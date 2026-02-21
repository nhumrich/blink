import std.http_types

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

fn test_request_basics() {
    http_types_clear()
    let r = request_new(METHOD_GET, "/users", "")
    check_int(request_method(r), METHOD_GET, "req method is GET")
    check_str(request_path(r), "/users", "req path is /users")
    check_str(request_body(r), "", "req body is empty")

    let r2 = request_new(METHOD_POST, "/items", "\{\"name\":\"thing\"\}")
    check_int(request_method(r2), METHOD_POST, "req2 method is POST")
    check_str(request_path(r2), "/items", "req2 path is /items")
    check_str(request_body(r2), "\{\"name\":\"thing\"\}", "req2 body matches")
}

fn test_request_params() {
    http_types_clear()
    let r = request_new(METHOD_GET, "/search", "")
    request_add_param(r, "q", "pact lang")
    request_add_param(r, "page", "1")

    check_str(request_param(r, "q"), "pact lang", "param q")
    check_str(request_param(r, "page"), "1", "param page")
    check_str(request_param(r, "missing"), "", "param missing returns empty")
}

fn test_request_headers() {
    http_types_clear()
    let r = request_new(METHOD_POST, "/api", "\{\}")
    request_add_header(r, "Content-Type", "application/json")
    request_add_header(r, "Authorization", "Bearer abc123")

    check_str(request_header(r, "Content-Type"), "application/json", "req header content-type")
    check_str(request_header(r, "Authorization"), "Bearer abc123", "req header auth")
    check_str(request_header(r, "X-Missing"), "", "req header missing returns empty")
}

fn test_request_isolation() {
    http_types_clear()
    let r1 = request_new(METHOD_GET, "/a", "")
    let r2 = request_new(METHOD_GET, "/b", "")
    request_add_param(r1, "key", "val1")
    request_add_param(r2, "key", "val2")
    request_add_header(r1, "X-Id", "one")
    request_add_header(r2, "X-Id", "two")

    check_str(request_param(r1, "key"), "val1", "isolation: r1 param")
    check_str(request_param(r2, "key"), "val2", "isolation: r2 param")
    check_str(request_header(r1, "X-Id"), "one", "isolation: r1 header")
    check_str(request_header(r2, "X-Id"), "two", "isolation: r2 header")
}

fn test_response_basics() {
    http_types_clear()
    let r = response_new(200, "\{\"ok\":true\}")
    check_int(response_status(r), 200, "resp status 200")
    check_str(response_body(r), "\{\"ok\":true\}", "resp body matches")
}

fn test_response_json_str() {
    http_types_clear()
    let r = response_json_str("\{\"items\":[]\}")
    check_int(response_status(r), 200, "json_str status 200")
    check_str(response_body(r), "\{\"items\":[]\}", "json_str body matches")
}

fn test_response_error_helpers() {
    http_types_clear()
    let r1 = response_bad_request("bad input")
    check_int(response_status(r1), 400, "bad_request status 400")
    check_str(response_body(r1), "bad input", "bad_request body")

    let r2 = response_not_found("no such thing")
    check_int(response_status(r2), 404, "not_found status 404")
    check_str(response_body(r2), "no such thing", "not_found body")

    let r3 = response_internal_error("oops")
    check_int(response_status(r3), 500, "internal_error status 500")
    check_str(response_body(r3), "oops", "internal_error body")
}

fn test_response_with_status() {
    http_types_clear()
    let r = response_new(200, "ok")
    check_int(response_status(r), 200, "with_status before")
    response_with_status(r, 201)
    check_int(response_status(r), 201, "with_status after")
}

fn test_response_with_header() {
    http_types_clear()
    let r = response_new(200, "ok")
    response_with_header(r, "X-Custom", "hello")
    // verify header was stored by checking arrays directly
    check_int(resp_header_owners.len(), 1, "with_header: 1 header stored")
    check_str(resp_header_names.get(0), "X-Custom", "with_header: name")
    check_str(resp_header_values.get(0), "hello", "with_header: value")
    check_int(resp_header_owners.get(0), r, "with_header: owner")
}

fn test_method_to_str() {
    check_str(method_to_str(METHOD_GET), "GET", "method_to_str GET")
    check_str(method_to_str(METHOD_POST), "POST", "method_to_str POST")
    check_str(method_to_str(METHOD_PUT), "PUT", "method_to_str PUT")
    check_str(method_to_str(METHOD_DELETE), "DELETE", "method_to_str DELETE")
    check_str(method_to_str(METHOD_PATCH), "PATCH", "method_to_str PATCH")
    check_str(method_to_str(METHOD_HEAD), "HEAD", "method_to_str HEAD")
    check_str(method_to_str(METHOD_OPTIONS), "OPTIONS", "method_to_str OPTIONS")
    check_str(method_to_str(99), "UNKNOWN", "method_to_str unknown")
}

fn test_method_from_str() {
    check_int(method_from_str("GET"), METHOD_GET, "method_from_str GET")
    check_int(method_from_str("POST"), METHOD_POST, "method_from_str POST")
    check_int(method_from_str("PUT"), METHOD_PUT, "method_from_str PUT")
    check_int(method_from_str("DELETE"), METHOD_DELETE, "method_from_str DELETE")
    check_int(method_from_str("PATCH"), METHOD_PATCH, "method_from_str PATCH")
    check_int(method_from_str("HEAD"), METHOD_HEAD, "method_from_str HEAD")
    check_int(method_from_str("OPTIONS"), METHOD_OPTIONS, "method_from_str OPTIONS")
    check_int(method_from_str("BOGUS"), -1, "method_from_str unknown")
}

fn test_method_roundtrip() {
    let mut m = 0
    while m <= 6 {
        let name = method_to_str(m)
        let back = method_from_str(name)
        check_int(back, m, "roundtrip method {m}")
        m = m + 1
    }
}

fn test_status_reason() {
    check_str(status_reason(200), "OK", "reason 200")
    check_str(status_reason(201), "Created", "reason 201")
    check_str(status_reason(204), "No Content", "reason 204")
    check_str(status_reason(400), "Bad Request", "reason 400")
    check_str(status_reason(401), "Unauthorized", "reason 401")
    check_str(status_reason(403), "Forbidden", "reason 403")
    check_str(status_reason(404), "Not Found", "reason 404")
    check_str(status_reason(409), "Conflict", "reason 409")
    check_str(status_reason(500), "Internal Server Error", "reason 500")
    check_str(status_reason(502), "Bad Gateway", "reason 502")
    check_str(status_reason(503), "Service Unavailable", "reason 503")
    check_str(status_reason(999), "Unknown", "reason unknown")
}

fn test_clear() {
    http_types_clear()
    let r = request_new(METHOD_GET, "/x", "")
    request_add_param(r, "a", "b")
    request_add_header(r, "H", "V")
    let resp = response_new(200, "ok")
    response_with_header(resp, "X", "Y")

    check_int(req_methods.len(), 1, "clear: before req count")
    check_int(resp_statuses.len(), 1, "clear: before resp count")

    http_types_clear()

    check_int(req_methods.len(), 0, "clear: req_methods empty")
    check_int(req_paths.len(), 0, "clear: req_paths empty")
    check_int(req_bodies.len(), 0, "clear: req_bodies empty")
    check_int(req_param_names.len(), 0, "clear: req_param_names empty")
    check_int(req_param_values.len(), 0, "clear: req_param_values empty")
    check_int(req_param_owners.len(), 0, "clear: req_param_owners empty")
    check_int(req_header_names.len(), 0, "clear: req_header_names empty")
    check_int(req_header_values.len(), 0, "clear: req_header_values empty")
    check_int(req_header_owners.len(), 0, "clear: req_header_owners empty")
    check_int(resp_statuses.len(), 0, "clear: resp_statuses empty")
    check_int(resp_bodies.len(), 0, "clear: resp_bodies empty")
    check_int(resp_header_names.len(), 0, "clear: resp_header_names empty")
    check_int(resp_header_values.len(), 0, "clear: resp_header_values empty")
    check_int(resp_header_owners.len(), 0, "clear: resp_header_owners empty")
}

fn main() {
    test_request_basics()
    test_request_params()
    test_request_headers()
    test_request_isolation()
    test_response_basics()
    test_response_json_str()
    test_response_error_helpers()
    test_response_with_status()
    test_response_with_header()
    test_method_to_str()
    test_method_from_str()
    test_method_roundtrip()
    test_status_reason()
    test_clear()

    io.println("All http_types tests complete")
}
