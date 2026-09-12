tool
extends Reference

const DEFAULT_IGNORES = [".git", ".godot", ".locust", "*.tmp", "*.log"]

func scan(root = "res://", ignores = DEFAULT_IGNORES):
	var files = []
	_scan_dir(root, root, ignores, files)
	return files

func _scan_dir(base, path, ignores, output):
	var dir = Directory.new()
	if dir.open(path) != OK:
		return
	dir.list_dir_begin(true, true)
	while true:
		var name = dir.get_next()
		if name == "":
			break
		var full = path.plus_file(name)
		if _ignored(full, base, name, dir.current_is_dir(), ignores):
			continue
		if dir.current_is_dir():
			_scan_dir(base, full, ignores, output)
		else:
			output.append(_relative(base, full))
	dir.list_dir_end()

func _relative(base, full):
	var value = full.replace(base, "")
	while value.begins_with("/"):
		value = value.substr(1)
	return value.replace("\\", "/")

func _ignored(full, base, name, is_dir, ignores):
	var rel = _relative(base, full)
	for rule in ignores:
		if rule == "":
			continue
		if rule.ends_with("/") and rel.begins_with(rule):
			return true
		if rule.find("*") >= 0:
			var suffix = rule.replace("*", "")
			if suffix != "" and rel.ends_with(suffix):
				return true
		elif name == rule or rel == rule or rel.begins_with(rule + "/"):
			return true
	return false

func read_file(path):
	var file = File.new()
	if file.open("res://" + path, File.READ) != OK:
		return null
	var data = file.get_buffer(file.get_len())
	file.close()
	return data

func write_file(path, data):
	var full = "res://" + path
	var dir = Directory.new()
	var parent = full.get_base_dir()
	if not dir.dir_exists(parent):
		dir.make_dir_recursive(parent)
	var file = File.new()
	if file.open(full, File.WRITE) != OK:
		return false
	file.store_buffer(data)
	file.close()
	return true

func delete_file(path):
	var dir = Directory.new()
	return dir.remove("res://" + path) == OK
