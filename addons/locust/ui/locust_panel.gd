tool
extends VBoxContainer

var status_label
var owner_edit
var repo_edit
var branch_edit
var connect_button
var sync_button
var log_view

func _ready():
	set_name("Locust")
	_build_ui()

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

	connect_button = Button.new()
	connect_button.text = "CONNECT REPOSITORY"
	connect_button.connect("pressed", self, "_on_connect")
	add_child(connect_button)

	sync_button = Button.new()
	sync_button.text = "SYNC PROJECT"
	sync_button.disabled = true
	sync_button.connect("pressed", self, "_on_sync")
	add_child(sync_button)

	status_label = Label.new()
	status_label.text = "Status: Not connected"
	add_child(status_label)

	add_child(HSeparator.new())
	var log_title = Label.new()
	log_title.text = "Activity"
	add_child(log_title)

	log_view = RichTextLabel.new()
	log_view.bbcode_enabled = true
	log_view.fit_content_height = true
	log_view.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(log_view)

func _field(placeholder):
	var edit = LineEdit.new()
	edit.placeholder_text = placeholder
	add_child(edit)
	return edit

func _on_connect():
	if owner_edit.text.strip_edges() == "" or repo_edit.text.strip_edges() == "":
		_set_status("Status: Enter GitHub owner and repository")
		return
	sync_button.disabled = false
	_set_status("Status: Repository configured")
	_log("Connected to %s/%s" % [owner_edit.text, repo_edit.text])

func _on_sync():
	_set_status("Status: Sync engine ready — Git operations will be executed here")
	_log("Sync requested for branch %s" % branch_edit.text)

func _set_status(text):
	status_label.text = text

func _log(text):
	if log_view:
		log_view.append_bbcode("• " + text + "\n")
