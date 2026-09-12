tool
extends Reference

signal status_changed(status)
signal operation_finished(operation, result)

var project_path = ""
var github_owner = ""
var github_repo = ""
var github_branch = "main"
var access_token = ""

func configure(p_path, owner, repo, branch = "main"):
	project_path = p_path
	github_owner = owner
	github_repo = repo
	github_branch = branch

func get_status():
	return {
		"configured": github_owner != "" and github_repo != "",
		"owner": github_owner,
		"repo": github_repo,
		"branch": github_branch
	}

func set_token(token):
	access_token = token

func clear_token():
	access_token = ""

func is_authenticated():
	return access_token != ""
