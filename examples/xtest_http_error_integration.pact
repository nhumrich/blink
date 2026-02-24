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

// ── Local server/routing (mirrors http_server.pact) ──────────────

let mut server_hosts: List[Str] = []
let mut server_ports: List[Int] = []
let mut route_methods: List[Str] = []
let mut route_patterns: List[Str] = []
let mut route_handlers: List[Int] = []
let mut route_server_owners: List[Int] = []
let mut param_names: List[Str] = []
let mut param_values: List[Str] = []

fn server_new(host: Str, port: Int) -> Int {
    let idx = server_hosts.len()
    server_hosts.push(host)
    server_ports.push(port)
    idx
}

fn server_route(srv: Int, method: Str, pattern: Str, handler_fn: Int) {
    route_methods.push(method)
    route_patterns.push(pattern)
    route_handlers.push(handler_fn)
    route_server_owners.push(srv)
}

fn route_handler_fn(idx: Int) -> Int {
    route_handlers.get(idx)
}

fn path_param_clear() {
    param_names = []
    param_values = []
}

fn path_param(name: Str) -> Str {
    let mut i = 0
    while i < param_names.len() {
        if param_names.get(i) == name {
            return param_values.get(i)
        }
        i = i + 1
    }
    ""
}

fn split_path(path: Str) -> List[Str] {
    let mut parts: List[Str] = []
    let mut current = ""
    let mut i = 0
    while i < path.len() {
        if path.char_at(i) == 47 {
            if current.len() > 0 {
                parts.push(current)
                current = ""
            }
        } else {
            current = current.concat(path.substring(i, 1))
        }
        i = i + 1
    }
    if current.len() > 0 {
        parts.push(current)
    }
    parts
}

fn path_match(pattern: Str, path: Str) -> Int {
    let pat_parts = split_path(pattern)
    let path_parts = split_path(path)
    if pat_parts.len() != path_parts.len() {
        return 0
    }
    let mut i = 0
    while i < pat_parts.len() {
        let pat_seg = pat_parts.get(i)
        let path_seg = path_parts.get(i)
        if pat_seg.len() > 0 && pat_seg.char_at(0) == 58 {
            let pname = pat_seg.substring(1, pat_seg.len() - 1)
            param_names.push(pname)
            param_values.push(path_seg)
        } else if pat_seg != path_seg {
            return 0
        }
        i = i + 1
    }
    1
}

fn match_route(srv: Int, method: Str, path: Str) -> Int {
    path_param_clear()
    let mut i = 0
    while i < route_methods.len() {
        if route_server_owners.get(i) == srv && route_methods.get(i) == method {
            if path_match(route_patterns.get(i), path) == 1 {
                return i
            }
            path_param_clear()
        }
        i = i + 1
    }
    -1
}

fn server_clear() {
    server_hosts = []
    server_ports = []
    route_methods = []
    route_patterns = []
    route_handlers = []
    route_server_owners = []
    param_names = []
    param_values = []
}

fn clear_all() {
    http_types_clear()
    server_clear()
    http_error_clear()
}

// ── Simulate dispatching a request through the router ────────────

fn dispatch(srv: Int, method: Str, path: Str, body: Str) -> Int {
    let route = match_route(srv, method, path)
    if route == -1 {
        let err = http_error_new_status(404, "Not Found")
        let display = http_error_display(err)
        return response_not_found(display)
    }
    let hfn = route_handler_fn(route)
    if hfn == 2 {
        let err = http_error_new_status(400, "Bad Request")
        let display = http_error_display(err)
        return response_bad_request(display)
    }
    if hfn == 3 {
        let err = http_error_new_status(500, "Internal Server Error")
        let display = http_error_display(err)
        return response_internal_error(display)
    }
    response_new(200, "ok")
}

// ── Test: unmatched route produces 404 ───────────────────────────

fn test_unmatched_route_404() {
    clear_all()
    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/users", 1)

    let resp = dispatch(srv, "GET", "/nonexistent", "")
    check_int(response_status(resp), 404, "unmatched route: status 404")
    check_str(response_body(resp), "HTTP 404: Not Found", "unmatched route: body is error display")

    check_int(http_err_types.len(), 1, "unmatched route: one error recorded")
    check_int(http_error_type(0), HTTP_ERR_STATUS, "unmatched route: error type is STATUS")
    check_int(http_error_code(0), 404, "unmatched route: error code is 404")
}

// ── Test: wrong method produces 404 ──────────────────────────────

fn test_wrong_method_404() {
    clear_all()
    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/items", 1)

    let resp = dispatch(srv, "POST", "/items", "\{\"name\":\"x\"\}")
    check_int(response_status(resp), 404, "wrong method: status 404")
    check_str(response_body(resp), "HTTP 404: Not Found", "wrong method: body")
}

// ── Test: bad request data produces 400 ──────────────────────────

fn test_bad_request_400() {
    clear_all()
    let srv = server_new("localhost", 8080)
    server_route(srv, "POST", "/users", 2)

    let resp = dispatch(srv, "POST", "/users", "invalid data")
    check_int(response_status(resp), 400, "bad request: status 400")
    check_str(response_body(resp), "HTTP 400: Bad Request", "bad request: body is error display")

    check_int(http_err_types.len(), 1, "bad request: one error recorded")
    check_int(http_error_code(0), 400, "bad request: error code 400")
}

// ── Test: server error produces 500 ──────────────────────────────

fn test_server_error_500() {
    clear_all()
    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/crash", 3)

    let resp = dispatch(srv, "GET", "/crash", "")
    check_int(response_status(resp), 500, "server error: status 500")
    check_str(response_body(resp), "HTTP 500: Internal Server Error", "server error: body is error display")

    check_int(http_error_code(0), 500, "server error: error code 500")
}

// ── Test: successful route produces 200, no errors ───────────────

fn test_matched_route_200() {
    clear_all()
    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/health", 1)

    let resp = dispatch(srv, "GET", "/health", "")
    check_int(response_status(resp), 200, "matched route: status 200")
    check_str(response_body(resp), "ok", "matched route: body is ok")
    check_int(http_err_types.len(), 0, "matched route: no errors recorded")
}

// ── Test: error classification on status errors ──────────────────

fn test_status_error_classification() {
    clear_all()

    let e404 = http_error_new_status(404, "Not Found")
    let e400 = http_error_new_status(400, "Bad Request")
    let e500 = http_error_new_status(500, "Internal Server Error")
    let e_timeout = http_error_new(HTTP_ERR_TIMEOUT, "timed out")
    let e_conn = http_error_new(HTTP_ERR_CONNECTION_REFUSED, "refused")

    check_int(http_error_is_timeout(e404), 0, "classify: 404 is not timeout")
    check_int(http_error_is_timeout(e_timeout), 1, "classify: timeout is timeout")
    check_int(http_error_is_network(e_conn), 1, "classify: conn_refused is network")
    check_int(http_error_is_network(e404), 0, "classify: 404 is not network")
    check_int(http_error_is_network(e500), 0, "classify: 500 is not network")
    check_int(http_error_is_network(e_timeout), 0, "classify: timeout is not network")
}

// ── Test: error display formatting for different types ───────────

fn test_error_display_formatting() {
    clear_all()

    let e404 = http_error_new_status(404, "Not Found")
    check_str(http_error_display(e404), "HTTP 404: Not Found", "display: 404 status")

    let e500 = http_error_new_status(500, "Internal Server Error")
    check_str(http_error_display(e500), "HTTP 500: Internal Server Error", "display: 500 status")

    let e400 = http_error_new_status(400, "Bad Request")
    check_str(http_error_display(e400), "HTTP 400: Bad Request", "display: 400 status")

    let e_timeout = http_error_new(HTTP_ERR_TIMEOUT, "connection timed out")
    check_str(http_error_display(e_timeout), "timeout: connection timed out", "display: timeout")

    let e_dns = http_error_new(HTTP_ERR_DNS_FAILURE, "host not found")
    check_str(http_error_display(e_dns), "dns_failure: host not found", "display: dns failure")

    let e_parse = http_error_new(HTTP_ERR_PARSE, "malformed response")
    check_str(http_error_display(e_parse), "parse: malformed response", "display: parse error")
}

// ── Test: multiple errors across different routes ────────────────

fn test_multiple_error_accumulation() {
    clear_all()
    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/ok", 1)
    server_route(srv, "POST", "/fail", 2)

    dispatch(srv, "GET", "/ok", "")
    check_int(http_err_types.len(), 0, "multi: 0 errors after success")

    dispatch(srv, "GET", "/missing", "")
    check_int(http_err_types.len(), 1, "multi: 1 error after 404")
    check_int(http_error_code(0), 404, "multi: first error is 404")

    dispatch(srv, "POST", "/fail", "bad")
    check_int(http_err_types.len(), 2, "multi: 2 errors after 400")
    check_int(http_error_code(1), 400, "multi: second error is 400")

    dispatch(srv, "DELETE", "/ok", "")
    check_int(http_err_types.len(), 3, "multi: 3 errors after wrong-method 404")
    check_int(http_error_code(2), 404, "multi: third error is 404")
}

// ── Test: path param route still matches, no error ───────────────

fn test_path_param_route_match() {
    clear_all()
    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/users/:id", 1)

    let resp = dispatch(srv, "GET", "/users/42", "")
    check_int(response_status(resp), 200, "path param: status 200")
    check_str(path_param("id"), "42", "path param: id == 42")
    check_int(http_err_types.len(), 0, "path param: no errors")
}

// ── Test: error from server failure to response round-trip ───────

fn test_error_to_response_roundtrip() {
    clear_all()

    let err = http_error_new_status(502, "Bad Gateway")
    let display = http_error_display(err)
    let resp = response_new(http_error_code(err), display)

    check_int(response_status(resp), 502, "roundtrip: resp status 502")
    check_str(response_body(resp), "HTTP 502: Bad Gateway", "roundtrip: resp body matches display")
    check_str(http_error_type_name(http_error_type(err)), "status", "roundtrip: type name is status")
}

// ── Test: boundary — invalid error index returns safe defaults ───

fn test_invalid_error_index() {
    clear_all()
    check_int(http_error_type(-1), -1, "invalid idx -1: type returns -1")
    check_str(http_error_message(-1), "", "invalid idx -1: message returns empty")
    check_int(http_error_code(-1), 0, "invalid idx -1: code returns 0")
    check_str(http_error_display(-1), "unknown error", "invalid idx -1: display returns unknown")
    check_int(http_error_is_timeout(-1), 0, "invalid idx -1: is_timeout returns 0")
    check_int(http_error_is_network(-1), 0, "invalid idx -1: is_network returns 0")

    check_int(http_error_type(999), -1, "invalid idx 999: type returns -1")
    check_str(http_error_display(999), "unknown error", "invalid idx 999: display returns unknown")
}

fn main() {
    test_unmatched_route_404()
    test_wrong_method_404()
    test_bad_request_400()
    test_server_error_500()
    test_matched_route_200()
    test_status_error_classification()
    test_error_display_formatting()
    test_multiple_error_accumulation()
    test_path_param_route_match()
    test_error_to_response_roundtrip()
    test_invalid_error_index()

    io.println("All http_error_integration tests complete")
}
