tool
extends VBoxContainer

const SyncEngine = preload("res://addons/locust/core/sync_engine.gd")
const Config = preload("res://addons/locust/core/locust_config.gd")
const Activity = preload("res://addons/locust/core/activity.gd")
const Recovery = preload("res://addons/locust/core/recovery.gd")
const Assets = preload("res://addons/locust/core/asset_manager.gd")
const Scanner = preload("res://addons/locust/core/project_scanner.gd")

var engine
var activity
var recovery
var assets
var scanner
var status_label
var owner_edit
var repo_edit
var branch_edit
var token_edit
var connect_button
var sync_button
var clear_token_button
var refresh_button
var keep_local_button
var keep_remote_button
var milestone_button
var asset_button
var log_view
var conflict_list
var conflict_title

func _ready():
	set_name("Locust")
	engine = SyncEngine.new()
	add_child(engine)
	engine.connect("status_changed", self, "_on_status")
	engine.connect("sync_finished", self, "_on_sync_finished")
	engine.connect("conflicts_found", self, "_on_conflicts")
	activity = Activity.new()
	recovery = Recovery.new()
	assets = Assets.new()
	scanner = Scanner.new()
	_build_ui()
	_load_config()
	_render_activity()

func _build_ui():
	var title = Label.new()
	title.text = "LOCUST"
	title.add_font_override("font_size", 22)
	add_child(title)
	var subtitle = Label.new()
	subtitle.text = "GitHub collaboration for Godot 3"
	add_child(subtitle)
	add_child(HSeparator.new())
	owner_edit = _field("GitHub owner")
	repo_edit = _field("Repository")
	branch_edit = _field("Branch")
	branch_edit.text = "main"
	token_edit = _field("GitHub token — used only in memory")
	token_edit.secret = true
	var primary = HBoxContainer.new()
	add_child(primary)
	connect_button = _button("CHECK REPOSITORY", "_on_connect")
	primary.add_child(connect_button)
	refresh_button = _button("REFRESH", "_on_connect")
	primary.add_child(refresh_button)
	sync_button = _button("SYNC PROJECT", "_on_sync")
	sync_button.disabled = true
	add_child(sync_button)
	clear_token_button = _button("CLEAR TOKEN", "_on_clear_token")
	add_child(clear_token_button)
	status_label = Label.new()
	status_label.text = "Status: Not connected"
	status_label.autowrap = true
	add_child(status_label)
	add_child(HSeparator.new())
	conflict_title = Label.new()
	conflict_title.text = "Conflicts (none)"
	add_child(conflict_title)
	conflict_list = ItemList.new()
	conflict_list.select_mode = ItemList.SELECT_MULTI
	conflict_list.size_flags_vertical = SIZE_EXPAND_FILL
	conflict_list.rect_min_size = Vector2(0, 80)
	add_child(conflict_list)
	var conflict_actions = HBoxContainer.new()
	add_child(conflict_actions)
	keep_local_button = _button("KEEP MINE", "_on_keep_local")
	keep_local_button.disabled = true
	conflict_actions.add_child(keep_local_button)
	keep_remote_button = _button("USE GITHUB", "_on_keep_remote")
	keep_remote_button.disabled = true
	conflict_actions.add_child(keep_remote_button)
	var tools = HBoxContainer.new()
	add_child(tools)
	milestone_button = _button("CREATE BACKUP", "_on_backup")
	tools.add_child(milestone_button)
	asset_button = _button("CHECK ASSETS", "_on_assets")
	tools.add_child(asset_button)
	var log_title = Label.new()
	log_title.text = "Activity"
	add_child(log_title)
	log_view = RichTextLabel.new()
	log_view.bbcode_enabled = true
	log_view.scroll_active = true
	log_view.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(log_view)

func _button(text, method):
	var button = Button.new()
	button.text = text
	button.connect("pressed", self, method)
	return button

func _field(placeholder):
	var edit = LineEdit.new()
	edit.placeholder_text = placeholder
	add_child(edit)
	return edit

func _load_config():
	var config = Config.load_config()
	owner_edit.text = str(config.get("owner", ""))
	repo_edit.text = str(config.get("repo", ""))
	branch_edit.text = str(config.get("branch", "main"))

func _save_config():
	Config.save_config({"version": 1, "owner": owner_edit.text.strip_edges(), "repo": repo_edit.text.strip_edges(), "branch": branch_edit.text.strip_edges() if branch_edit.text.strip_edges() != "" else "main", "remote_path": "", "ignore": [".git", ".godot", ".import", ".locust", "*.tmp", "*.log"]})

func _configure_engine():
	_save_config()
	engine.configure(owner_edit.text, repo_edit.text, branch_edit.text, token_edit.text)

func _on_connect():
	if owner_edit.text.strip_edges() == "" or repo_edit.text.strip_edges() == "":
		_on_status("Enter GitHub owner and repository")
		return
	_configure_engine()
	sync_button.disabled = false
	engine.connect_repository()

func _on_sync():
	_configure_engine()
	conflict_list.clear()
	keep_local_button.disabled = true
	keep_remote_button.disabled = true
	engine.sync_project()

func _on_clear_token():
	token_edit.text = ""
	engine.configure(owner_edit.text, repo_edit.text, branch_edit.text, "")
	_on_status("Token cleared from memory")

func _selected_paths():
	var paths = []
	for index in conflict_list.get_selected_items():
		paths.append(conflict_list.get_item_text(index))
	return paths

func _on_keep_local():
	var paths = _selected_paths()
	if not paths.empty():
		engine.resolve_conflicts(paths, true)

func _on_keep_remote():
	var paths = _selected_paths()
	if not paths.empty():
		engine.resolve_conflicts(paths, false)

func _on_backup():
	var path = recovery.create_backup(scanner.scan(), scanner)
	_on_status("Backup created" if path != "" else "Could not create backup")

func _on_assets():
	var report = assets.inspect(scanner, scanner.scan())
	if report.large.empty():
		_on_status("No large assets detected")
	else:
		_on_status("Large assets: %d — consider Git LFS" % report.large.size())
		for item in report.large:
			_log("Asset: %s (%s)" % [item.path, assets.format_size(item.bytes)])

func _on_status(text):
	status_label.text = "Status: " + str(text)
	_log(text)

func _on_sync_finished(success, summary):
	if not success:
		if summary.has("conflicts"):
			return
		_on_status(str(summary.get("error", "Sync failed")))
	else:
		_on_status("Sync complete")
	_render_activity()

func _on_conflicts(paths):
	conflict_list.clear()
	for path in paths:
		conflict_list.add_item(path)
	conflict_title.text = "Conflicts (%d)" % paths.size()
	keep_local_button.disabled = paths.empty()
	keep_remote_button.disabled = paths.empty()
	_log("Conflicts require review: %d" % paths.size())

func _render_activity():
	if not log_view:
		return
	log_view.clear()
	for entry in activity.load_entries():
		log_view.append_bbcode("• " + str(entry.get("message", "")) + "\n")

func _log(text):
	if log_view:
		log_view.append_bbcode("• " + str(text) + "\n")
