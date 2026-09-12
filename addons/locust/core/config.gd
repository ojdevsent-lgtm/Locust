tool
extends Reference

const CONFIG_PATH = "user://locust.cfg"

var data = {
	"owner": "",
	"repo": "",
	"branch": "main",
	"token": "",
	"project_id": "",
	"last_sync": "",
	"tracked_commit": ""
}

func load_config():
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	for key in data.keys():
		data[key] = cfg.get_value("locust", key, data[key])

func save_config():
	var cfg = ConfigFile.new()
	for key in data.keys():
		cfg.set_value("locust", key, data[key])
	cfg.save(CONFIG_PATH)

func set_value(key, value):
	data[key] = value

func get_value(key, fallback = null):
	return data.get(key, fallback)
