tool
extends Reference

const VERSION = "0.3.2"
const GODOT_MAJOR = 3
const PRODUCT = "Locust"

func get_info():
	return {
		"name": PRODUCT,
		"version": VERSION,
		"godot_major": GODOT_MAJOR
	}
