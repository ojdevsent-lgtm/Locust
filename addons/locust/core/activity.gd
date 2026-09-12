tool
extends Reference

const LOG_PATH = "res://.locust/activity.json"
const MAX_ITEMS = 200

func load_entries():
	var file = File.new()
	if not file.file_exists(LOG_PATH):
		return []
	if file.open(LOG_PATH, File.READ) != OK:
		return []
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or typeof(parsed.result) != TYPE_ARRAY:
		return []
	return parsed.result

func add(message, kind = "info"):
	var entries = load_entries()
	entries.push_front({"time": OS.get_datetime(), "kind": kind, "message": message})
	if entries.size() > MAX_ITEMS:
		entries.resize(MAX_ITEMS)
	var dir = Directory.new()
	if not dir.dir_exists("res://.locust"):
		dir.make_dir_recursive("res://.locust")
	var file = File.new()
	if file.open(LOG_PATH, File.WRITE) == OK:
		file.store_string(JSON.print(entries, "\t"))
		file.close()
