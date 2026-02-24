import std.http_types
import std.json
import std.http_error

fn check_int(actual: Int, expected: Int, label: Str) {
    if actual == expected {
        io.println("PASS: {label}")
    } else {
        io.println("FAIL: {label} — expected {expected}, got {actual}")
    }
}

fn check_str(actual: Str, expected: Str, label: Str) {
    if actual == expected {
        io.println("PASS: {label}")
    } else {
        io.println("FAIL: {label} — expected \"{expected}\", got \"{actual}\"")
    }
}

fn resp_header_value(resp: Int, name: Str) -> Str {
    let mut i = 0
    while i < resp_header_owners.len() {
        if resp_header_owners.get(i) == resp && resp_header_names.get(i) == name {
            return resp_header_values.get(i)
        }
        i = i + 1
    }
    ""
}

fn test_parse_request_json_body() {
    http_types_clear()
    json_clear()

    let body = "\{\"username\":\"alice\",\"age\":30,\"active\":true}"
    let req = request_new(METHOD_POST, "/api/users", body)
    request_add_header(req, "Content-Type", "application/json")

    check_int(request_method(req), METHOD_POST, "req: method is POST")
    check_str(request_path(req), "/api/users", "req: path")
    check_str(request_header(req, "Content-Type"), "application/json", "req: content-type header")

    let parsed = json_parse(request_body(req))
    check_int(parsed >= 0, 1, "req body: parse succeeds")
    check_int(json_type(parsed), JSON_OBJECT, "req body: is object")
    check_str(json_as_str(json_get(parsed, "username")), "alice", "req body: username")
    check_int(json_as_int(json_get(parsed, "age")), 30, "req body: age")
    check_int(json_as_bool(json_get(parsed, "active")), 1, "req body: active")
}

fn test_build_json_response() {
    http_types_clear()
    json_clear()

    let resp_body = "\{\"id\":42,\"status\":\"created\"}"
    let resp = response_json_str(resp_body)

    check_int(response_status(resp), 200, "json resp: status 200")
    check_str(response_body(resp), resp_body, "json resp: body matches")
    check_str(resp_header_value(resp, "Content-Type"), "application/json", "json resp: content-type header")
}

fn test_content_type_header_flow() {
    http_types_clear()
    json_clear()

    let req = request_new(METHOD_POST, "/api/data", "\{\"key\":\"value\"}")
    request_add_header(req, "Content-Type", "application/json")
    request_add_header(req, "Accept", "application/json")

    check_str(request_header(req, "Content-Type"), "application/json", "header flow: req content-type")
    check_str(request_header(req, "Accept"), "application/json", "header flow: req accept")

    let resp = response_json_str("\{\"result\":\"ok\"}")
    check_str(resp_header_value(resp, "Content-Type"), "application/json", "header flow: resp content-type")
}

fn test_roundtrip_json_string() {
    http_types_clear()
    json_clear()

    let original = "\{\"name\":\"Bob\",\"score\":99,\"verified\":false}"

    let req = request_new(METHOD_POST, "/submit", original)
    let parsed = json_parse(request_body(req))
    check_int(parsed >= 0, 1, "roundtrip: parse succeeds")

    let name = json_as_str(json_get(parsed, "name"))
    let score = json_as_int(json_get(parsed, "score"))
    let verified = json_as_bool(json_get(parsed, "verified"))
    check_str(name, "Bob", "roundtrip: extracted name")
    check_int(score, 99, "roundtrip: extracted score")
    check_int(verified, 0, "roundtrip: extracted verified")

    let serialized = json_serialize(parsed)
    check_str(serialized, original, "roundtrip: serialize matches original")

    let resp = response_json_str(serialized)
    check_str(response_body(resp), original, "roundtrip: response body matches")
    check_str(resp_header_value(resp, "Content-Type"), "application/json", "roundtrip: resp content-type")
}

fn test_nested_json_request() {
    http_types_clear()
    json_clear()

    let body = "\{\"user\":\{\"id\":7,\"name\":\"Eve\"},\"action\":\"login\"}"
    let req = request_new(METHOD_PUT, "/api/session", body)
    request_add_header(req, "Content-Type", "application/json")

    let parsed = json_parse(request_body(req))
    check_int(json_type(parsed), JSON_OBJECT, "nested: top is object")

    let user = json_get(parsed, "user")
    check_int(json_type(user), JSON_OBJECT, "nested: user is object")
    check_int(json_as_int(json_get(user, "id")), 7, "nested: user.id")
    check_str(json_as_str(json_get(user, "name")), "Eve", "nested: user.name")
    check_str(json_as_str(json_get(parsed, "action")), "login", "nested: action")

    let resp_body = json_serialize(parsed)
    let resp = response_json_str(resp_body)
    check_int(response_status(resp), 200, "nested: resp status")
    check_str(resp_header_value(resp, "Content-Type"), "application/json", "nested: resp content-type")
}

fn test_array_json_body() {
    http_types_clear()
    json_clear()

    let body = "[1,2,3]"
    let req = request_new(METHOD_POST, "/api/batch", body)
    request_add_header(req, "Content-Type", "application/json")

    let parsed = json_parse(request_body(req))
    check_int(json_type(parsed), JSON_ARRAY, "array body: is array")
    check_int(json_len(parsed), 3, "array body: length 3")
    check_int(json_as_int(json_at(parsed, 0)), 1, "array body: first")
    check_int(json_as_int(json_at(parsed, 2)), 3, "array body: third")

    let serialized = json_serialize(parsed)
    let resp = response_json_str(serialized)
    check_str(response_body(resp), "[1,2,3]", "array body: resp matches")
}

fn test_invalid_json_request_body() {
    http_types_clear()
    json_clear()

    let req = request_new(METHOD_POST, "/api/data", "not json at all")
    request_add_header(req, "Content-Type", "application/json")

    let parsed = json_parse(request_body(req))
    check_int(parsed, -1, "invalid body: parse returns -1")

    let err = http_error_new(HTTP_ERR_PARSE, "malformed JSON in request body")
    check_int(http_error_type(err), HTTP_ERR_PARSE, "invalid body: error type is PARSE")
    check_str(http_error_message(err), "malformed JSON in request body", "invalid body: error message")

    let resp = response_bad_request("invalid JSON")
    check_int(response_status(resp), 400, "invalid body: resp status 400")
    check_str(response_body(resp), "invalid JSON", "invalid body: resp body")
}

fn test_empty_json_object_roundtrip() {
    http_types_clear()
    json_clear()

    let body = "\{\}"
    let req = request_new(METHOD_POST, "/api/empty", body)
    let parsed = json_parse(request_body(req))
    check_int(json_type(parsed), JSON_OBJECT, "empty obj: is object")
    check_int(json_len(parsed), 0, "empty obj: length 0")

    let serialized = json_serialize(parsed)
    check_str(serialized, "\{\}", "empty obj: serialize matches")

    let resp = response_json_str(serialized)
    check_str(response_body(resp), "\{\}", "empty obj: resp body")
}

fn test_error_response_with_json() {
    http_types_clear()
    json_clear()

    let err = http_error_new_status(422, "Unprocessable Entity")
    check_int(http_error_type(err), HTTP_ERR_STATUS, "error resp: type is STATUS")
    check_int(http_error_code(err), 422, "error resp: code is 422")

    let error_body = "\{\"error\":\"validation_failed\",\"message\":\"name is required\"}"
    let resp = response_new(422, error_body)
    response_with_header(resp, "Content-Type", "application/json")

    check_int(response_status(resp), 422, "error resp: status 422")
    check_str(resp_header_value(resp, "Content-Type"), "application/json", "error resp: content-type")

    let parsed = json_parse(response_body(resp))
    check_str(json_as_str(json_get(parsed, "error")), "validation_failed", "error resp: parsed error field")
    check_str(json_as_str(json_get(parsed, "message")), "name is required", "error resp: parsed message field")
}

fn test_multiple_requests_isolation() {
    http_types_clear()
    json_clear()

    let req1 = request_new(METHOD_POST, "/api/a", "\{\"id\":1}")
    request_add_header(req1, "Content-Type", "application/json")

    let req2 = request_new(METHOD_POST, "/api/b", "\{\"id\":2}")
    request_add_header(req2, "Content-Type", "application/json")

    let p1 = json_parse(request_body(req1))
    check_int(json_as_int(json_get(p1, "id")), 1, "isolation: req1 id")

    json_clear()
    let p2 = json_parse(request_body(req2))
    check_int(json_as_int(json_get(p2, "id")), 2, "isolation: req2 id")

    let resp1 = response_json_str("\{\"ok\":true}")
    let resp2 = response_json_str("\{\"ok\":false}")
    check_str(response_body(resp1), "\{\"ok\":true}", "isolation: resp1 body")
    check_str(response_body(resp2), "\{\"ok\":false}", "isolation: resp2 body")
}

fn main() {
    test_parse_request_json_body()
    test_build_json_response()
    test_content_type_header_flow()
    test_roundtrip_json_string()
    test_nested_json_request()
    test_array_json_body()
    test_invalid_json_request_body()
    test_empty_json_object_roundtrip()
    test_error_response_with_json()
    test_multiple_requests_isolation()

    io.println("All http_json_integration tests complete")
}
