tool
extends VBoxContainer

const SyncEngine = preload("res://addons/locust/core/sync_engine.gd")
const Config = preload("res://addons/locust/core/locust_config.gd")

var engine
var status_label
var owner_edit
var repo_edit
var branch_edit
var token_edit
var connect_button
var sync_button
var clear_token_button
var log_view
var conflict_list

func _ready():
	set_name("Locust")
	engine = SyncEngine.new()
	add_child(engine)
	engine.connect("status_changed", self, "_on_status")
	engine.connect("sync_finished", self, "_on_sync_finished")
	engine.connect("conflicts_found", self, "_on_conflicts")
	_build_ui()
	_load_config()

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
	token_edit = _field("GitHub access token (kept in memory only)")
	token_edit.secret = true

	connect_button = Button.new()
	connect_button.text = "CHECK REPOSITORY"
	connect_button.connect("pressed", self, "_on_connect")
	add_child(connect_button)

	sync_button = Button.new()
	sync_button.text = "SYNC PROJECT"
	sync_button.disabled = true
	sync_button.connect("pressed", self, "_on_sync")
	add_child(sync_button)

	clear_token_button = Button.new()
	clear_token_button.text = "CLEAR TOKEN"
	clear_token_button.connect("pressed", self, "_on_clear_token")
	add_child(clear_token_button)

	status_label = Label.new()
	status_label.text = "Status: Not connected"
	status_label.autowrap = true
	add_child(status_label)

	add_child(HSeparator.new())
	var conflict_title = Label.new()
	conflict_title.text = "Conflicts"
	add_child(conflict_title)
	conflict_list = ItemList.new()
	conflict_list.size_flags_vertical = SIZE_EXPAND_FILL
	conflict_list.rect_min_size = Vector2(0, 70)
	add_child(conflict_list)

	var log_title = Label.new()
	log_title.text = "Activity"
	add_child(log_title)
	log_view = RichTextLabel.new()
	log_view.bbcode_enabled = true
	log_view.scroll_active = true
	log_view.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(log_view)

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
	Config.save_config({
		"version": 1,
		"owner": owner_edit.text.strip_edges(),
		"repo": repo_edit.text.strip_edges(),
		"branch": branch_edit.text.strip_edges() if branch_edit.text.strip_edges() != "" else "main",
		"remote_path": "",
		"ignore": [".git", ".godot", ".locust/cache", "*.tmp", "*.log"]
	})

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
	engine.sync_project()

func _on_clear_token():
	token_edit.text = ""
	engine.configure(owner_edit.text, repo_edit.text, branch_edit.text, "")
	_on_status("Token cleared from memory")

func _on_status(text):
	status_label.text = "Status: " + text
	_log(text)

func _on_sync_finished(success, summary):
	if not success:
		if summary.has("conflicts"):
			return
		_on_status(str(summary.get("error", "Sync failed")))
	else:
		_on_status("Sync complete")

func _on_conflicts(paths):
	conflict_list.clear()
	for path in paths:
		conflict_list.add_item(path)
	_log("Conflicts require review: %d" % paths.size())

func _log(text):
	if log_view:
		log_view.append_bbcode("• " + text + "\n")
