tool
extends Reference

const LARGE_FILE_BYTES = 5 * 1024 * 1024
const GITHUB_CONTENT_LIMIT = 1024 * 1024

func inspect(scanner, files):
	var report = {"large": [], "unsupported": [], "total_bytes": 0}
	for path in files:
		var data = scanner.read_file(path)
		if data == null:
			continue
		var size = data.size()
		report.total_bytes += size
		if size >= LARGE_FILE_BYTES:
			report.large.append({"path": path, "bytes": size, "requires_lfs": size > GITHUB_CONTENT_LIMIT})
	return report

func format_size(bytes):
	var value = float(bytes)
	var units = ["B", "KB", "MB", "GB"]
	var index = 0
	while value >= 1024.0 and index < units.size() - 1:
		value /= 1024.0
		index += 1
	return "%.1f %s" % [value, units[index]]

func recommended_gitattributes():
	return "# Locust large-asset guidance\n# Add binary formats that your team wants Git LFS to manage.\n*.psd filter=lfs diff=lfs merge=lfs -text\n*.fbx filter=lfs diff=lfs merge=lfs -text\n*.blend filter=lfs diff=lfs merge=lfs -text\n*.wav filter=lfs diff=lfs merge=lfs -text\n*.mp4 filter=lfs diff=lfs merge=lfs -text\n"
