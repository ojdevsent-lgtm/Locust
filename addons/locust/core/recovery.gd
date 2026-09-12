tool
extends Reference

const BACKUP_ROOT = "res://.locust/backups"

func create_backup(files, scanner):
	# Include milliseconds so repeated backups in the same second do not collide.
	var stamp = "%d-%d" % [OS.get_unix_time(), OS.get_ticks_msec() % 100000]
	var path = BACKUP_ROOT.plus_file(stamp)
	var dir = Directory.new()
	if dir.make_dir_recursive(path) != OK and not dir.dir_exists(path):
		return ""
	for file_path in files:
		if not scanner.is_safe_project_path(file_path):
			continue
		var data = scanner.read_file(file_path)
		if data == null:
			continue
		var target = path.plus_file(file_path)
		var parent = target.get_base_dir()
		if not dir.dir_exists(parent):
			dir.make_dir_recursive(parent)
		var file = File.new()
		if file.open(target, File.WRITE) == OK:
			file.store_buffer(data)
			file.close()
	return path

func list_backups():
	var result = []
	var dir = Directory.new()
	if dir.open(BACKUP_ROOT) != OK:
		return result
	dir.list_dir_begin(true, true)
	while true:
		var name = dir.get_next()
		if name == "":
			break
		if dir.current_is_dir() and _is_safe_backup_name(name):
			result.append(name)
	dir.list_dir_end()
	result.sort()
	result.invert()
	return result

func restore_backup(name, scanner):
	if not _is_safe_backup_name(name):
		return false
	var root = BACKUP_ROOT.plus_file(name)
	var dir = Directory.new()
	if dir.open(root) != OK:
		return false
	_restore_dir(root, "", scanner)
	return true

func _is_safe_backup_name(name):
	var value = str(name)
	if value == "" or value == "." or value == ".." or value.find("/") >= 0 or value.find("\\") >= 0 or value.find(":") >= 0:
		return false
	return true

func _restore_dir(root, relative, scanner):
	var dir = Directory.new()
	if dir.open(root.plus_file(relative)) != OK:
		return
	dir.list_dir_begin(true, true)
	while true:
		var name = dir.get_next()
		if name == "":
			break
		var rel = name if relative == "" else relative.plus_file(name)
		if dir.current_is_dir():
			_restore_dir(root, rel, scanner)
		else:
			if not scanner.is_safe_project_path(rel):
				continue
			var file = File.new()
			if file.open(root.plus_file(rel), File.READ) == OK:
				var data = file.get_buffer(file.get_len())
				file.close()
				scanner.write_file(rel, data)
	dir.list_dir_end()
