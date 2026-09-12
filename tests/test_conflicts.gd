tool
extends Reference

const Conflicts = preload("res://addons/locust/core/conflicts.gd")

func run():
	var c = Conflicts.new()
	var base = {"a.gd": "same", "b.gd": "old"}
	var local = {"a.gd": "same", "b.gd": "local", "new.gd": "new"}
	var remote = {"a.gd": "same", "b.gd": "remote", "new_remote.gd": "remote"}
	var result = c.classify(local, remote, base)
	assert(result.conflicts.has("b.gd"))
	assert(result.upload.has("new.gd"))
	assert(result.download.has("new_remote.gd"))
	return true
