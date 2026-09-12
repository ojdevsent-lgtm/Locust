tool
extends Reference

const SNAPSHOT_PATH = "res://.locust/snapshot.json"

func load_snapshot():
	var file = File.new()
	if not file.file_exists(SNAPSHOT_PATH):
		return {}
	if file.open(SNAPSHOT_PATH, File.READ) != OK:
		return {}
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return {}
	return parsed.result

func save_snapshot(data):
	var dir = Directory.new()
	if not dir.dir_exists("res://.locust"):
		dir.make_dir_recursive("res://.locust")
	var file = File.new()
	if file.open(SNAPSHOT_PATH, File.WRITE) != OK:
		return false
	file.store_string(JSON.print(data, "\t"))
	file.close()
	return true

func git_blob_sha(data):
	var header = "blob " + str(data.size()) + "\u0000"
	var bytes = PoolByteArray()
	bytes.append_array(header.to_utf8())
	bytes.append_array(data)
	return bytes.sha1_text()

func build(files, scanner):
	var result = {}
	for path in files:
		var data = scanner.read_file(path)
		if data != null:
			result[path] = git_blob_sha(data)
	return result
