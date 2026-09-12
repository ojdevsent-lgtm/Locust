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

func save_snapshot(snapshot):
	var dir = Directory.new()
	if not dir.dir_exists("res://.locust"):
		dir.make_dir_recursive("res://.locust")
	var file = File.new()
	if file.open(SNAPSHOT_PATH, File.WRITE) != OK:
		return false
	file.store_string(JSON.print(snapshot, "\t"))
	file.close()
	return true

func checksum(data):
	return Marshalls.raw_to_base64(data.sha256_buffer())

func build(files, scanner):
	var result = {}
	for path in files:
		var data = scanner.read_file(path)
		if data != null:
			result[path] = checksum(data)
	return result
