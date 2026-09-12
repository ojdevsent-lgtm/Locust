tool
extends EditorPlugin

const PANEL_SCENE = preload("res://addons/locust/ui/locust_panel.tscn")

var panel

func _enter_tree():
	panel = PANEL_SCENE.instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, panel)

func _exit_tree():
	if panel:
		remove_control_from_docks(panel)
		panel.queue_free()
		panel = null
