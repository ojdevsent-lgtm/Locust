tool
extends Reference

const VERSION = "0.1.0"
const GODOT_MAJOR = 3
const PRODUCT = "Locust"

func get_info():
	return {
		"name": PRODUCT,
		"version": VERSION,
		"godot_major": GODOT_MAJOR
	}
