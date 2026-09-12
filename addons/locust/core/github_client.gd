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

func request(method, path, body = null, extra_headers = []):
	if http == null:
		emit_signal("request_completed", false, null, "HTTP client unavailable")
		return false
	var headers = ["Accept: application/vnd.github.v3+json", "User-Agent: Locust-Godot-3"]
	if token != "":
		headers.append("Authorization: token " + token)
	for header in extra_headers:
		headers.append(str(header))
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
	return request(HTTPClient.METHOD_GET, "/repos/%s/%s/git/trees/%s?recursive=1" % [owner, repo, _escape(branch)])

func get_contents(owner, repo, path, branch):
	return request(HTTPClient.METHOD_GET, "/repos/%s/%s/contents/%s?ref=%s" % [owner, repo, _escape_path(path), _escape(branch)])

func get_raw_contents(owner, repo, path, branch):
	if http == null:
		emit_signal("request_completed", false, null, "HTTP client unavailable")
		return false
	var headers = ["Accept: application/octet-stream", "User-Agent: Locust-Godot-3"]
	if token != "":
		headers.append("Authorization: token " + token)
	var url = "https://raw.githubusercontent.com/%s/%s/%s/%s" % [owner, repo, _escape_path(branch), _escape_path(path)]
	var err = http.request(url, headers, true, HTTPClient.METHOD_GET, "")
	if err != OK:
		emit_signal("request_completed", false, null, "Request could not start: " + str(err))
		return false
	return true

func put_content(owner, repo, path, content_base64, message, branch, sha = ""):
	var body = {"message": message, "content": content_base64, "branch": branch}
	if sha != "":
		body["sha"] = sha
	return request(HTTPClient.METHOD_PUT, "/repos/%s/%s/contents/%s" % [owner, repo, _escape_path(path)], body)

func delete_content(owner, repo, path, message, branch, sha):
	var body = {"message": message, "branch": branch, "sha": sha}
	return request(HTTPClient.METHOD_DELETE, "/repos/%s/%s/contents/%s" % [owner, repo, _escape_path(path)], body)

func get_commits(owner, repo, branch = "main", per_page = 20):
	return request(HTTPClient.METHOD_GET, "/repos/%s/%s/commits?sha=%s&per_page=%d" % [owner, repo, _escape(branch), per_page])

func get_collaborators(owner, repo):
	return request(HTTPClient.METHOD_GET, "/repos/%s/%s/collaborators" % [owner, repo])

func get_pull_requests(owner, repo, state = "open"):
	return request(HTTPClient.METHOD_GET, "/repos/%s/%s/pulls?state=%s&per_page=20" % [owner, repo, state])

func _escape(value):
	var text = str(value)
	return text.percent_encode()

func _escape_path(value):
	var parts = str(value).split("/")
	for i in range(parts.size()):
		parts[i] = parts[i].percent_encode()
	return "/".join(parts)

func _on_http_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("request_completed", false, null, "Network error: " + str(result))
		return
	if response_code < 200 or response_code >= 300:
		var text = body.get_string_from_utf8()
		var parsed_error = JSON.parse(text)
		var message = "GitHub returned HTTP " + str(response_code)
		if parsed_error.error == OK and typeof(parsed_error.result) == TYPE_DICTIONARY:
			message = str(parsed_error.result.get("message", message))
			emit_signal("request_completed", false, parsed_error.result, message)
		else:
			emit_signal("request_completed", false, null, message)
		return
	# Raw GitHub responses are binary and must not be JSON-decoded.
	if response_code == 200 and body.size() > 0:
		var text = body.get_string_from_utf8()
		var parsed = JSON.parse(text)
		if parsed.error == OK:
			emit_signal("request_completed", true, parsed.result, "")
			return
		emit_signal("request_completed", true, body, "")
		return
	emit_signal("request_completed", true, {}, "")
