tool
extends Node

signal status_changed(text)
signal sync_finished(success, summary)
signal conflicts_found(paths)
signal backup_created(path)

const GithubClient = preload("res://addons/locust/core/github_client.gd")
const Scanner = preload("res://addons/locust/core/project_scanner.gd")
const Snapshot = preload("res://addons/locust/core/snapshot.gd")
const Conflicts = preload("res://addons/locust/core/conflicts.gd")
const Activity = preload("res://addons/locust/core/activity.gd")
const Recovery = preload("res://addons/locust/core/recovery.gd")

var http
var github
var scanner
var snapshot
var conflicts
var activity
var recovery
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

func configure(p_owner, p_repo, p_branch = "main", p_token = ""):
	owner = p_owner.strip_edges()
	repo = p_repo.strip_edges()
	branch = p_branch.strip_edges() if p_branch.strip_edges() != "" else "main"
	token = p_token.strip_edges()
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

func _start_plan(tree):
	remote_map = {}
	remote_entries = {}
	if typeof(tree) == TYPE_DICTIONARY:
		for entry in tree.get("tree", []):
			if entry.get("type", "") == "blob":
				var path = str(entry.get("path", ""))
				remote_map[path] = str(entry.get("sha", ""))
				remote_entries[path] = entry
	var files = scanner.scan()
	local_map = snapshot.build(files, scanner)
	var result = conflicts.classify(local_map, remote_map, base_snapshot)
	plan = result
	if result.conflicts.size() > 0:
		activity.add("Sync stopped: %d conflict(s) detected" % result.conflicts.size(), "conflict")
		emit_signal("conflicts_found", result.conflicts)
		emit_signal("status_changed", "%d conflict(s) need review" % result.conflicts.size())
		emit_signal("sync_finished", false, {"conflicts": result.conflicts})
		pending = ""
		return
	var backup = recovery.create_backup(files, scanner)
	if backup != "":
		emit_signal("backup_created", backup)
		activity.add("Created recovery backup", "backup")
	queue = []
	for path in result.download: queue.append({"op": "download", "path": path})
	for path in result.upload: queue.append({"op": "upload", "path": path})
	for path in result.delete_remote: queue.append({"op": "delete_remote", "path": path})
	for path in result.delete_local: queue.append({"op": "delete_local", "path": path})
	queue_index = 0
	if queue.empty():
		_save_snapshot()
		activity.add("Project already synchronized", "sync")
		emit_signal("status_changed", "Project is up to date")
		emit_signal("sync_finished", true, {"changed": 0})
		pending = ""
		return
	_process_next()

func _process_next():
	if queue_index >= queue.size():
		_save_snapshot()
		activity.add("Sync completed: %d operation(s)" % queue.size(), "sync")
		emit_signal("status_changed", "Sync complete — %d operation(s)" % queue.size())
		emit_signal("sync_finished", true, {"changed": queue.size()})
		pending = ""
		return
	var item = queue[queue_index]
	pending = item.op
	pending_path = item.path
	emit_signal("status_changed", "%s: %s" % [item.op.capitalize(), item.path])
	match item.op:
		"download":
			github.get_contents(owner, repo, item.path, branch)
		"upload":
			var data = scanner.read_file(item.path)
			if data == null:
				_finish_queue_item()
				return
			var content = Marshalls.raw_to_base64(data)
			var sha = remote_map.get(item.path, "")
			github.put_content(owner, repo, item.path, content, "Locust: update " + item.path, branch, sha)
		"delete_remote":
			var sha = remote_map.get(item.path, "")
			github.delete_content(owner, repo, item.path, "Locust: delete " + item.path, branch, sha)
		"delete_local":
			scanner.delete_file(item.path)
			_finish_queue_item()

func _handle_download(data):
	if typeof(data) != TYPE_DICTIONARY:
		_finish_queue_item()
		return
	var encoded = str(data.get("content", "")).replace("\n", "")
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
	var files = scanner.scan()
	var current = snapshot.build(files, scanner)
	snapshot.save_snapshot({"version": 1, "owner": owner, "repo": repo, "branch": branch, "files": current})
