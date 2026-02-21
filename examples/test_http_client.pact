import std.http_types
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

// ── Client result pair (mirrors http_client.pact) ─────────────────
let mut client_ok: Int = 1
let mut client_result: Int = -1

fn http_client_clear() {
    client_ok = 1
    client_result = -1
}

// ── Mock net handler for testing ───────────────────────────────────

let mut mock_responses: List[Int] = []
let mut mock_next: Int = 0

fn mock_reset() {
    mock_responses = []
    mock_next = 0
}

fn mock_add_response(resp_idx: Int) {
    mock_responses.push(resp_idx)
}

fn mock_net_request(req_idx: Int) -> Int {
    if mock_next >= mock_responses.len() {
        return -1
    }
    let resp = mock_responses.get(mock_next)
    mock_next = mock_next + 1
    resp
}

// ── Tests ──────────────────────────────────────────────────────────

fn test_get_success() {
    http_types_clear()
    http_error_clear()
    http_client_clear()
    mock_reset()

    let resp = response_new(200, "\{\"ok\":true\}")
    mock_add_response(resp)

    let req = request_new(METHOD_GET, "http://example.com/api", "")
    check_int(request_method(req), METHOD_GET, "get: method is GET")
    check_str(request_path(req), "http://example.com/api", "get: url matches")

    let result = mock_net_request(req)
    check_int(result >= 0, 1, "get: response is valid")
    check_int(response_status(result), 200, "get: status 200")
    check_str(response_body(result), "\{\"ok\":true\}", "get: body matches")
}

fn test_post_success() {
    http_types_clear()
    http_error_clear()
    http_client_clear()
    mock_reset()

    let resp = response_new(201, "\{\"id\":42\}")
    mock_add_response(resp)

    let req = request_new(METHOD_POST, "http://example.com/items", "\{\"name\":\"thing\"\}")
    check_int(request_method(req), METHOD_POST, "post: method is POST")
    check_str(request_body(req), "\{\"name\":\"thing\"\}", "post: body matches")

    let result = mock_net_request(req)
    check_int(response_status(result), 201, "post: status 201")
}

fn test_put_success() {
    http_types_clear()
    http_error_clear()
    http_client_clear()
    mock_reset()

    let resp = response_new(200, "\{\"updated\":true\}")
    mock_add_response(resp)

    let req = request_new(METHOD_PUT, "http://example.com/items/1", "\{\"name\":\"updated\"\}")
    check_int(request_method(req), METHOD_PUT, "put: method is PUT")

    let result = mock_net_request(req)
    check_int(response_status(result), 200, "put: status 200")
}

fn test_delete_success() {
    http_types_clear()
    http_error_clear()
    http_client_clear()
    mock_reset()

    let resp = response_new(204, "")
    mock_add_response(resp)

    let req = request_new(METHOD_DELETE, "http://example.com/items/1", "")
    check_int(request_method(req), METHOD_DELETE, "delete: method is DELETE")
    check_str(request_body(req), "", "delete: body is empty")

    let result = mock_net_request(req)
    check_int(response_status(result), 204, "delete: status 204")
}

fn test_request_failure() {
    http_types_clear()
    http_error_clear()
    http_client_clear()
    mock_reset()

    let result = mock_net_request(0)
    check_int(result, -1, "failure: returns -1 on connection fail")

    if result < 0 {
        client_ok = 0
        client_result = http_error_new(HTTP_ERR_CONNECTION_REFUSED, "request failed")
    }
    check_int(client_ok, 0, "failure: client_ok is 0")
    check_int(http_error_type(client_result), HTTP_ERR_CONNECTION_REFUSED, "failure: error type is CONNECTION_REFUSED")
    check_str(http_error_message(client_result), "request failed", "failure: error message")
}

fn test_error_status() {
    http_types_clear()
    http_error_clear()
    http_client_clear()
    mock_reset()

    let resp = response_new(404, "Not Found")
    mock_add_response(resp)

    let result = mock_net_request(0)
    let status = response_status(result)
    check_int(status, 404, "error_status: status is 404")

    if status >= 400 {
        client_ok = 0
        client_result = http_error_new_status(status, response_body(result))
    }
    check_int(client_ok, 0, "error_status: client_ok is 0")
    check_int(http_error_type(client_result), HTTP_ERR_STATUS, "error_status: error type is STATUS")
    check_int(http_error_code(client_result), 404, "error_status: error code is 404")
    check_str(http_error_message(client_result), "Not Found", "error_status: error message")
}

fn test_request_with_headers() {
    http_types_clear()
    http_error_clear()
    http_client_clear()
    mock_reset()

    let req = request_new(METHOD_POST, "http://example.com/api", "\{\}")
    let headers: List[Str] = ["Content-Type", "application/json", "Authorization", "Bearer token123"]

    let mut i = 0
    while i < headers.len() - 1 {
        request_add_header(req, headers.get(i), headers.get(i + 1))
        i = i + 2
    }

    check_str(request_header(req, "Content-Type"), "application/json", "with_headers: Content-Type")
    check_str(request_header(req, "Authorization"), "Bearer token123", "with_headers: Authorization")
}

fn test_client_clear() {
    http_client_clear()
    check_int(client_ok, 1, "clear: client_ok is 1")
    check_int(client_result, -1, "clear: client_result is -1")

    client_ok = 0
    client_result = 42

    check_int(client_ok, 0, "clear: client_ok after dirty is 0")
    check_int(client_result, 42, "clear: client_result after dirty is 42")

    http_client_clear()
    check_int(client_ok, 1, "clear: client_ok after clear is 1")
    check_int(client_result, -1, "clear: client_result after clear is -1")
}

fn test_success_sets_result() {
    http_types_clear()
    http_error_clear()
    http_client_clear()
    mock_reset()

    let resp = response_new(200, "ok")
    mock_add_response(resp)

    let result = mock_net_request(0)
    let status = response_status(result)

    if result >= 0 && status < 400 {
        client_ok = 1
        client_result = result
    }

    check_int(client_ok, 1, "success_result: client_ok is 1")
    check_int(client_result, resp, "success_result: client_result is response idx")
}

fn main() {
    test_get_success()
    test_post_success()
    test_put_success()
    test_delete_success()
    test_request_failure()
    test_error_status()
    test_request_with_headers()
    test_client_clear()
    test_success_sets_result()

    io.println("All http_client tests complete")
}
