tool
extends Reference

signal request_completed(success, data, error_message)

var http = null
var token = ""

func _init():
	http = HTTPRequest.new()
	if Engine.is_editor_hint():
		get_tree().get_root().add_child(http)

func set_token(value):
	token = value

func request(method, path, body = null):
	if not http:
		request_completed.emit(false, null, "HTTP client unavailable")
		return
	var headers = ["Accept: application/vnd.github.v3+json", "User-Agent: Locust-Godot-3"]
	if token != "":
		headers.append("Authorization: token " + token)
	var payload = ""
	if body != null:
		headers.append("Content-Type: application/json")
		payload = JSON.print(body)
	var url = "https://api.github.com" + path
	var err = http.request(url, headers, true, method, payload)
	if err != OK:
		request_completed.emit(false, null, "Request could not start: " + str(err))

func get_repository(owner, repo):
	request(HTTPClient.METHOD_GET, "/repos/%s/%s" % [owner, repo])

func get_contents(owner, repo, path, branch = "main"):
	request(HTTPClient.METHOD_GET, "/repos/%s/%s/contents/%s?ref=%s" % [owner, repo, path, branch])
