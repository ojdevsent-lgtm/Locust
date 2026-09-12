tool
extends Reference

signal command_finished(success, output)

var git_path = "git"

func is_available():
	var output = []
	var code = OS.execute(git_path, ["--version"], true, output)
	return code == 0 and output.size() > 0

func run(arguments):
	var output = []
	var code = OS.execute(git_path, arguments, true, output)
	var text = ""
	for line in output:
		text += str(line)
	return {"success": code == 0, "code": code, "output": text}

func status():
	return run(["status", "--porcelain"])

func current_branch():
	var result = run(["rev-parse", "--abbrev-ref", "HEAD"])
	return str(result.output).strip_edges() if result.success else ""

func init():
	return run(["init"])

func add_all():
	return run(["add", "-A"])

func commit(message):
	return run(["commit", "-m", message])

func pull(remote = "origin", branch = "main"):
	return run(["pull", "--ff-only", remote, branch])

func push(remote = "origin", branch = "main"):
	return run(["push", remote, branch])

func clone(url, destination):
	return run(["clone", url, destination])
