tool
extends Reference

const BACKUP_ROOT = "res://.locust/backups"

func create_backup(files, scanner):
	var stamp = OS.get_unix_time()
	var path = BACKUP_ROOT.plus_file(str(stamp))
	var dir = Directory.new()
	if not dir.make_dir_recursive(path) == OK and not dir.dir_exists(path):
		return ""
	for file_path in files:
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
		if dir.current_is_dir():
			result.append(name)
	dir.list_dir_end()
	result.sort()
	result.invert()
	return result

func restore_backup(name, scanner):
	var root = BACKUP_ROOT.plus_file(name)
	var dir = Directory.new()
	if dir.open(root) != OK:
		return false
	_restore_dir(root, "", scanner)
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
			var file = File.new()
			if file.open(root.plus_file(rel), File.READ) == OK:
				var data = file.get_buffer(file.get_len())
				file.close()
				scanner.write_file(rel, data)
	dir.list_dir_end()
