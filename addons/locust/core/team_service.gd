tool
extends Reference

# Repository collaboration data. The UI can consume these normalized records
# without depending directly on GitHub response shapes.

func normalize_collaborators(data):
	var result = []
	if typeof(data) != TYPE_ARRAY:
		return result
	for item in data:
		var permissions = item.get("permissions", {})
		var role = "collaborator"
		if permissions.get("admin", false):
			role = "admin"
		elif permissions.get("push", false):
			role = "write"
		elif permissions.get("pull", false):
			role = "read"
		result.append({"login": str(item.get("login", "")), "avatar": str(item.get("avatar_url", "")), "role": role})
	return result

func normalize_commits(data):
	var result = []
	if typeof(data) != TYPE_ARRAY:
		return result
	for item in data:
		var commit = item.get("commit", {})
		var author = commit.get("author", {})
		result.append({"sha": str(item.get("sha", "")), "message": str(commit.get("message", "")).split("\n")[0], "author": str(author.get("name", "")), "date": str(author.get("date", ""))})
	return result

func normalize_pull_requests(data):
	var result = []
	if typeof(data) != TYPE_ARRAY:
		return result
	for item in data:
		result.append({"number": int(item.get("number", 0)), "title": str(item.get("title", "")), "author": str(item.get("user", {}).get("login", "")), "state": str(item.get("state", "")), "url": str(item.get("html_url", ""))})
	return result
