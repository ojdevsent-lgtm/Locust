tool
extends Reference

signal request_completed(success, data, error_message)

var http = null
var token = ""

func setup(http_request):
	http = http_request
	if http and not http.is_connected("request_completed", self, "_on_http_completed"):
		http.connect("request_completed", self, "_on_http_completed")

func set_token(value):
	token = value.strip_edges()

func request(method, path, body = null):
	if http == null:
		emit_signal("request_completed", false, null, "HTTP client unavailable")
		return false
	var headers = ["Accept: application/vnd.github.v3+json", "User-Agent: Locust-Godot-3"]
	if token != "":
		headers.append("Authorization: token " + token)
	var payload = ""
	if body != null:
		headers.append("Content-Type: application/json")
		payload = JSON.print(body)
	var err = http.request("https://api.github.com" + path, headers, true, method, payload)
	if err != OK:
		emit_signal("request_completed", false, null, "Request could not start: " + str(err))
		return false
	return true

func get_repository(owner, repo):
	return request(HTTPClient.METHOD_GET, "/repos/%s/%s" % [owner, repo])

func get_tree(owner, repo, branch):
	return request(HTTPClient.METHOD_GET, "/repos/%s/%s/git/trees/%s?recursive=1" % [owner, repo, branch])

func get_contents(owner, repo, path, branch):
	var escaped = path.replace(" ", "%20").replace("#", "%23")
	return request(HTTPClient.METHOD_GET, "/repos/%s/%s/contents/%s?ref=%s" % [owner, repo, escaped, branch])

func put_content(owner, repo, path, content_base64, message, branch, sha = ""):
	var body = {"message": message, "content": content_base64, "branch": branch}
	if sha != "": body["sha"] = sha
	return request(HTTPClient.METHOD_PUT, "/repos/%s/%s/contents/%s" % [owner, repo, path], body)

func delete_content(owner, repo, path, message, branch, sha):
	var body = {"message": message, "branch": branch, "sha": sha}
	return request(HTTPClient.METHOD_DELETE, "/repos/%s/%s/contents/%s" % [owner, repo, path], body)

func _on_http_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("request_completed", false, null, "Network error: " + str(result))
		return
	var text = body.get_string_from_utf8()
	var parsed = JSON.parse(text)
	if response_code < 200 or response_code >= 300:
		var message = "GitHub returned HTTP " + str(response_code)
		if parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY:
			message = str(parsed.result.get("message", message))
		emit_signal("request_completed", false, parsed.result if parsed.error == OK else null, message)
		return
	if parsed.error == OK:
		emit_signal("request_completed", true, parsed.result, "")
	else:
		emit_signal("request_completed", true, text, "")
