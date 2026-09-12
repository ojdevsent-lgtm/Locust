tool
extends Reference

signal request_completed(success, data, error_message)

var http = null
var token = ""

func _init():
	http = HTTPRequest.new()
	var root = Engine.get_main_loop().get_root()
	root.add_child(http)
	http.connect("request_completed", self, "_on_request_completed")

func set_token(value):
	token = value

func request(method, path, body = null):
	if not http:
		emit_signal("request_completed", false, null, "HTTP client unavailable")
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
		emit_signal("request_completed", false, null, "Request could not start: " + str(err))

func get_repository(owner, repo):
	request(HTTPClient.METHOD_GET, "/repos/%s/%s" % [owner, repo])

func get_contents(owner, repo, path, branch = "main"):
	request(HTTPClient.METHOD_GET, "/repos/%s/%s/contents/%s?ref=%s" % [owner, repo, path, branch])

func _on_request_completed(result, response_code, headers, body):
	var text = body.get_string_from_utf8()
	var parsed = JSON.parse(text)
	var data = parsed.result if parsed.error == OK else text
	var success = result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
	emit_signal("request_completed", success, data, "" if success else "GitHub HTTP %s" % response_code)
