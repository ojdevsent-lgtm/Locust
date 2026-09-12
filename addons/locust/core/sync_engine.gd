tool
extends Node

signal status_changed(text)
signal sync_finished(success, summary)
signal conflicts_found(paths)

const GithubClient = preload("res://addons/locust/core/github_client.gd")
const Scanner = preload("res://addons/locust/core/project_scanner.gd")
const Snapshot = preload("res://addons/locust/core/snapshot.gd")
const Conflicts = preload("res://addons/locust/core/conflicts.gd")
const Activity = preload("res://addons/locust/core/activity.gd")
const Recovery = preload("res://addons/locust/core/recovery.gd")
const Assets = preload("res://addons/locust/core/asset_manager.gd")

var http
var github
var scanner
var snapshot
var conflicts
var activity
var recovery
var assets
var owner = ""
var repo = ""
var branch = "main"
var token = ""
var base_snapshot = {}
var local_map = {}
var remote_map = {}
var remote_entries = {}
var plan = {}
var queue = []
var queue_index = 0
var pending = ""
var pending_path = ""
var pending_sha = ""
var operation_total = 0

func _ready():
	http = HTTPRequest.new()
	add_child(http)
	github = GithubClient.new()
	github.setup(http)
	github.connect("request_completed", self, "_on_github_response")
	scanner = Scanner.new()
	snapshot = Snapshot.new()
	conflicts = Conflicts.new()
	activity = Activity.new()
	recovery = Recovery.new()
	assets = Assets.new()

func configure(p_owner, p_repo, p_branch = "main", p_token = ""):
	owner = str(p_owner).strip_edges()
	repo = str(p_repo).strip_edges()
	branch = str(p_branch).strip_edges() if str(p_branch).strip_edges() != "" else "main"
	token = str(p_token).strip_edges()
	github.set_token(token)

func connect_repository():
	if owner == "" or repo == "":
		emit_signal("status_changed", "Enter a GitHub owner and repository")
		return
	pending = "connect"
	emit_signal("status_changed", "Checking GitHub repository…")
	github.get_repository(owner, repo)

func sync_project():
	if owner == "" or repo == "":
		emit_signal("sync_finished", false, {"error": "Repository is not configured"})
		return
	base_snapshot = snapshot.load_snapshot().get("files", {})
	pending = "tree"
	emit_signal("status_changed", "Reading project changes…")
	github.get_tree(owner, repo, branch)

func resolve_conflicts(paths, keep_local):
	if plan.empty():
		return
	var remaining = []
	var selected = {}
	for path in paths:
		if scanner.is_safe_project_path(path):
			selected[path] = true
	for path in plan.get("conflicts", []):
		if not selected.has(path):
			remaining.append(path)
		else:
			if keep_local:
				plan.upload.append(path)
			else:
				plan.download.append(path)
	plan.conflicts = remaining
	if remaining.size() > 0:
		emit_signal("conflicts_found", remaining)
		emit_signal("status_changed", "%d conflict(s) still need review" % remaining.size())
		return
	_start_queue()

func _on_github_response(success, data, error_message):
	if not success:
		emit_signal("status_changed", error_message)
		emit_signal("sync_finished", false, {"error": error_message})
		pending = ""
		return
	match pending:
		"connect":
			emit_signal("status_changed", "Repository connected: " + str(data.get("full_name", owner + "/" + repo)))
			activity.add("Connected to %s/%s" % [owner, repo], "connect")
			pending = ""
		"tree":
			_start_plan(data)
		"download":
			_handle_download(data)
		"upload":
			_finish_queue_item()
		"delete_remote":
			_finish_queue_item()
		"delete_local":
			_finish_queue_item()

func _start_plan(tree):
	remote_map = {}
	remote_entries = {}
	if typeof(tree) != TYPE_DICTIONARY:
		emit_signal("sync_finished", false, {"error": "GitHub returned an invalid repository tree"})
		pending = ""
		return
	if tree.get("truncated", false):
		emit_signal("sync_finished", false, {"error": "GitHub returned a truncated repository tree. Locust stopped to avoid an incomplete sync."})
		pending = ""
		return
	for entry in tree.get("tree", []):
		if entry.get("type", "") == "blob":
			var path = str(entry.get("path", ""))
			if scanner.is_safe_project_path(path):
				remote_map[path] = str(entry.get("sha", ""))
				remote_entries[path] = entry
	var files = scanner.scan()
	local_map = snapshot.build(files, scanner)
	var result = conflicts.classify(local_map, remote_map, base_snapshot)
	plan = result
	if result.conflicts.size() > 0:
		activity.add("Sync paused: %d conflict(s) detected" % result.conflicts.size(), "conflict")
		emit_signal("conflicts_found", result.conflicts)
		emit_signal("status_changed", "%d conflict(s) need review" % result.conflicts.size())
		emit_signal("sync_finished", false, {"conflicts": result.conflicts})
		pending = ""
		return
	_start_queue()

func _start_queue():
	queue = []
	for path in plan.get("download", []):
		if scanner.is_safe_project_path(path): queue.append({"op": "download", "path": path})
	for path in plan.get("upload", []):
		if scanner.is_safe_project_path(path): queue.append({"op": "upload", "path": path})
	for path in plan.get("delete_remote", []):
		if scanner.is_safe_project_path(path): queue.append({"op": "delete_remote", "path": path})
	for path in plan.get("delete_local", []):
		if scanner.is_safe_project_path(path): queue.append({"op": "delete_local", "path": path})
	queue_index = 0
	operation_total = queue.size()
	if queue.empty():
		_save_snapshot()
		activity.add("Project already synchronized", "sync")
		emit_signal("status_changed", "Project is up to date")
		emit_signal("sync_finished", true, {"changed": 0})
		pending = ""
		return
	# Preserve a local recovery point before modifying project files.
	recovery.create_backup(scanner.scan(), scanner)
	_process_next()

func _process_next():
	if queue_index >= queue.size():
		_save_snapshot()
		activity.add("Sync completed: %d operation(s)" % operation_total, "sync")
		emit_signal("status_changed", "Sync complete — %d operation(s)" % operation_total)
		emit_signal("sync_finished", true, {"changed": operation_total})
		pending = ""
		return
	var item = queue[queue_index]
	pending = item["op"]
	pending_path = item["path"]
	emit_signal("status_changed", "%s: %s" % [str(item["op"]).capitalize(), pending_path])
	match item["op"]:
		"download":
			github.get_contents(owner, repo, pending_path, branch)
		"upload":
			var data = scanner.read_file(pending_path)
			if data == null:
				emit_signal("status_changed", "Could not read " + pending_path)
				emit_signal("sync_finished", false, {"error": "Could not read " + pending_path})
				pending = ""
				return
			var content = Marshalls.raw_to_base64(data)
			var sha = remote_map.get(pending_path, "")
			github.put_content(owner, repo, pending_path, content, "Locust: update " + pending_path, branch, sha)
		"delete_remote":
			var sha = remote_map.get(pending_path, "")
			if sha == "":
				emit_signal("status_changed", "Remote file already absent: " + pending_path)
				_finish_queue_item()
				return
			github.delete_content(owner, repo, pending_path, "Locust: delete " + pending_path, branch, sha)
		"delete_local":
			if not scanner.delete_file(pending_path):
				emit_signal("sync_finished", false, {"error": "Could not delete " + pending_path})
				pending = ""
				return
			_finish_queue_item()

func _handle_download(data):
	if typeof(data) != TYPE_DICTIONARY:
		emit_signal("sync_finished", false, {"error": "GitHub returned invalid file data for " + pending_path})
		pending = ""
		return
	var encoded = str(data.get("content", "")).replace("\n", "")
	if encoded == "":
		emit_signal("sync_finished", false, {"error": "GitHub did not return file content for " + pending_path})
		pending = ""
		return
	var bytes = Marshalls.base64_to_raw(encoded)
	if scanner.write_file(pending_path, bytes):
		_finish_queue_item()
	else:
		emit_signal("status_changed", "Could not write " + pending_path)
		emit_signal("sync_finished", false, {"error": "Could not write " + pending_path})
		pending = ""

func _finish_queue_item():
	queue_index += 1
	_process_next()

func _save_snapshot():
	local_map = snapshot.build(scanner.scan(), scanner)
	snapshot.save_snapshot({"version": 1, "owner": owner, "repo": repo, "branch": branch, "files": local_map})
