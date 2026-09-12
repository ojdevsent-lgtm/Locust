tool
extends Reference

func detect(local_map, remote_map, base_map):
	var conflicts = []
	var paths = {}
	for p in local_map.keys(): paths[p] = true
	for p in remote_map.keys(): paths[p] = true
	for path in paths.keys():
		var local = local_map.get(path, "__missing__")
		var remote = remote_map.get(path, "__missing__")
		var base = base_map.get(path, "__missing__")
		var local_changed = local != base
		var remote_changed = remote != base
		if local_changed and remote_changed and local != remote:
			conflicts.append(path)
	return conflicts

func classify(local_map, remote_map, base_map):
	var result = {"upload": [], "download": [], "delete_remote": [], "delete_local": [], "conflicts": []}
	var paths = {}
	for p in local_map.keys(): paths[p] = true
	for p in remote_map.keys(): paths[p] = true
	for path in paths.keys():
		var local = local_map.get(path, "__missing__")
		var remote = remote_map.get(path, "__missing__")
		var base = base_map.get(path, "__missing__")
		var lc = local != base
		var rc = remote != base
		if lc and rc and local != remote:
			result.conflicts.append(path)
		elif lc and not rc:
			if local == "__missing__": result.delete_remote.append(path)
			else: result.upload.append(path)
		elif rc and not lc:
			if remote == "__missing__": result.delete_local.append(path)
			else: result.download.append(path)
	return result
