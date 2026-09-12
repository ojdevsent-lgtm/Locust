tool
extends Reference

const CONFIG_PATH = "res://.locust/config.json"

static func default_config():
	return {
		"version": 1,
		"owner": "",
		"repo": "",
		"branch": "main",
		"remote_path": "",
		"ignore": [".git", ".godot", ".import", ".locust/cache", "*.tmp", "*.log"]
	}

static func load_config():
	if not File.new().file_exists(CONFIG_PATH):
		return default_config()
	var file = File.new()
	if file.open(CONFIG_PATH, File.READ) != OK:
		return default_config()
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return default_config()
	var config = default_config()
	for key in parsed.result.keys():
		config[key] = parsed.result[key]
	return config

static func save_config(config):
	var dir = Directory.new()
	if not dir.dir_exists("res://.locust"):
		dir.make_dir_recursive("res://.locust")
	var file = File.new()
	if file.open(CONFIG_PATH, File.WRITE) != OK:
		return false
	file.store_string(JSON.print(config, "\t"))
	file.close()
	return true
