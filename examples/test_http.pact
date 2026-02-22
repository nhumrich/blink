// test_http.pact — Comprehensive umbrella HTTP test suite
//
// Cross-cutting integration tests that span multiple HTTP modules.
// Individual module tests live in test_http_{types,client,server,error}.pact
// and test_http_{integration,json_integration,error_integration}.pact.
// This file focuses on edge cases and multi-module flows they don't cover.

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

// ── Server/routing (mirrors http_server.pact) ───────────────────

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

fn route_handler(idx: Int) -> Int {
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

fn route_count(srv: Int) -> Int {
    let mut count = 0
    let mut i = 0
    while i < route_server_owners.len() {
        if route_server_owners.get(i) == srv {
            count = count + 1
        }
        i = i + 1
    }
    count
}

// ── Mock net ────────────────────────────────────────────────────

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

// ── Client result pair ──────────────────────────────────────────

let mut client_ok: Int = 1
let mut client_result: Int = -1

fn http_client_clear() {
    client_ok = 1
    client_result = -1
}

// ── Response header helper ──────────────────────────────────────

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

fn resp_header_count(resp: Int) -> Int {
    let mut count = 0
    let mut i = 0
    while i < resp_header_owners.len() {
        if resp_header_owners.get(i) == resp {
            count = count + 1
        }
        i = i + 1
    }
    count
}

fn req_header_count(req: Int) -> Int {
    let mut count = 0
    let mut i = 0
    while i < req_header_owners.len() {
        if req_header_owners.get(i) == req {
            count = count + 1
        }
        i = i + 1
    }
    count
}

// ── Clear everything ────────────────────────────────────────────

fn clear_all() {
    http_types_clear()
    http_error_clear()
    server_clear()
    mock_reset()
    http_client_clear()
}

// ── Handler IDs ─────────────────────────────────────────────────

let HANDLER_ECHO = 1
let HANDLER_JSON = 2
let HANDLER_CREATED = 3
let HANDLER_DELETE = 4
let HANDLER_HEALTH = 5
let HANDLER_ERROR = 6

fn dispatch_handler(handler_id: Int, req_idx: Int) -> Int {
    if handler_id == HANDLER_ECHO {
        return handle_echo(req_idx)
    }
    if handler_id == HANDLER_JSON {
        return handle_json(req_idx)
    }
    if handler_id == HANDLER_CREATED {
        return handle_created(req_idx)
    }
    if handler_id == HANDLER_DELETE {
        return handle_delete(req_idx)
    }
    if handler_id == HANDLER_HEALTH {
        return handle_health(req_idx)
    }
    if handler_id == HANDLER_ERROR {
        return handle_error(req_idx)
    }
    response_not_found("unknown handler")
}

fn handle_echo(req_idx: Int) -> Int {
    let body = request_body(req_idx)
    let method_str = method_to_str(request_method(req_idx))
    let resp = response_new(200, "{method_str}: {body}")
    response_with_header(resp, "Content-Type", "text/plain")
    response_with_header(resp, "X-Echo", "true")
    resp
}

fn handle_json(req_idx: Int) -> Int {
    let id = path_param("id")
    let body = "\{\"id\":\"{id}\",\"found\":true\}"
    let resp = response_json_str(body)
    response_with_header(resp, "Cache-Control", "no-cache")
    resp
}

fn handle_created(req_idx: Int) -> Int {
    let body = request_body(req_idx)
    if body == "" {
        return response_bad_request("body required")
    }
    let resp = response_new(201, body)
    response_with_header(resp, "Content-Type", "application/json")
    response_with_header(resp, "Location", "/items/new")
    resp
}

fn handle_delete(req_idx: Int) -> Int {
    let id = path_param("id")
    if id == "" {
        return response_bad_request("missing id")
    }
    response_new(204, "")
}

fn handle_health(req_idx: Int) -> Int {
    response_new(200, "ok")
}

fn handle_error(req_idx: Int) -> Int {
    response_internal_error("something broke")
}

// ── Roundtrip helper ────────────────────────────────────────────

fn roundtrip(srv: Int, method: Int, path: Str, body: Str) -> Int {
    let req = request_new(method, path, body)
    let method_str = method_to_str(method)
    let route_idx = match_route(srv, method_str, path)
    if route_idx < 0 {
        return response_not_found("no route for {method_str} {path}")
    }
    let handler_id = route_handler(route_idx)
    dispatch_handler(handler_id, req)
}

// ═══════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════

// ── Response builder chaining ───────────────────────────────────

fn test_response_builder_chaining() {
    clear_all()

    let resp = response_new(200, "initial")
    response_with_status(resp, 201)
    response_with_header(resp, "Content-Type", "application/json")
    response_with_header(resp, "X-Request-Id", "abc-123")
    response_with_header(resp, "Cache-Control", "no-store")

    check_int(response_status(resp), 201, "chaining: status changed to 201")
    check_str(response_body(resp), "initial", "chaining: body unchanged")
    check_int(resp_header_count(resp), 3, "chaining: 3 headers added")
    check_str(resp_header_value(resp, "Content-Type"), "application/json", "chaining: content-type")
    check_str(resp_header_value(resp, "X-Request-Id"), "abc-123", "chaining: request-id")
    check_str(resp_header_value(resp, "Cache-Control"), "no-store", "chaining: cache-control")
}

// ── Response status override after headers ──────────────────────

fn test_status_override_preserves_headers() {
    clear_all()

    let resp = response_json_str("\{\"ok\":true\}")
    check_int(response_status(resp), 200, "override: initial status 200")
    check_str(resp_header_value(resp, "Content-Type"), "application/json", "override: initial content-type")

    response_with_status(resp, 206)
    check_int(response_status(resp), 206, "override: status changed to 206")
    check_str(resp_header_value(resp, "Content-Type"), "application/json", "override: content-type preserved")
    check_str(response_body(resp), "\{\"ok\":true\}", "override: body preserved")
}

// ── Request with many params and many headers ───────────────────

fn test_request_many_params_and_headers() {
    clear_all()

    let req = request_new(METHOD_POST, "/api/search", "\{\"q\":\"test\"\}")
    request_add_param(req, "page", "1")
    request_add_param(req, "limit", "50")
    request_add_param(req, "sort", "date")
    request_add_param(req, "order", "desc")
    request_add_header(req, "Content-Type", "application/json")
    request_add_header(req, "Authorization", "Bearer xyz")
    request_add_header(req, "Accept", "application/json")
    request_add_header(req, "X-Request-Id", "req-001")
    request_add_header(req, "X-Correlation-Id", "corr-555")

    check_str(request_param(req, "page"), "1", "many: param page")
    check_str(request_param(req, "limit"), "50", "many: param limit")
    check_str(request_param(req, "sort"), "date", "many: param sort")
    check_str(request_param(req, "order"), "desc", "many: param order")
    check_int(req_header_count(req), 5, "many: 5 headers")
    check_str(request_header(req, "Content-Type"), "application/json", "many: content-type")
    check_str(request_header(req, "Authorization"), "Bearer xyz", "many: auth")
    check_str(request_header(req, "Accept"), "application/json", "many: accept")
    check_str(request_header(req, "X-Request-Id"), "req-001", "many: request-id")
    check_str(request_header(req, "X-Correlation-Id"), "corr-555", "many: correlation-id")
}

// ── Method string -> int -> request -> route match pipeline ─────

fn test_method_string_to_route_pipeline() {
    clear_all()
    let srv = server_new("localhost", 8080)
    server_route(srv, "POST", "/items", HANDLER_CREATED)
    server_route(srv, "DELETE", "/items/:id", HANDLER_DELETE)

    let method_int = method_from_str("POST")
    check_int(method_int, METHOD_POST, "pipeline: POST parsed")

    let req = request_new(method_int, "/items", "\{\"name\":\"widget\"\}")
    let method_str = method_to_str(method_int)
    check_str(method_str, "POST", "pipeline: roundtrip method string")

    let route_idx = match_route(srv, method_str, "/items")
    check_int(route_idx >= 0, 1, "pipeline: route matched")
    check_int(route_handler(route_idx), HANDLER_CREATED, "pipeline: correct handler")

    let resp = dispatch_handler(route_handler(route_idx), req)
    check_int(response_status(resp), 201, "pipeline: response 201")
    check_str(response_body(resp), "\{\"name\":\"widget\"\}", "pipeline: body echoed")
}

// ── Sequential mock requests (client retry flow) ────────────────

fn test_sequential_mock_retry_flow() {
    clear_all()

    let fail_resp = response_new(503, "Service Unavailable")
    let ok_resp = response_new(200, "\{\"ok\":true\}")
    mock_add_response(fail_resp)
    mock_add_response(ok_resp)

    // First request fails
    let req1 = request_new(METHOD_GET, "http://api.example.com/data", "")
    let result1 = mock_net_request(req1)
    let status1 = response_status(result1)
    check_int(status1, 503, "retry: first request 503")

    if status1 >= 400 {
        client_ok = 0
        client_result = http_error_new_status(status1, response_body(result1))
    }
    check_int(client_ok, 0, "retry: client_ok is 0 after failure")
    check_int(http_error_type(client_result), HTTP_ERR_STATUS, "retry: error type STATUS")
    check_int(http_error_code(client_result), 503, "retry: error code 503")

    // Retry succeeds
    http_client_clear()
    let req2 = request_new(METHOD_GET, "http://api.example.com/data", "")
    let result2 = mock_net_request(req2)
    let status2 = response_status(result2)
    check_int(status2, 200, "retry: second request 200")

    if result2 >= 0 && status2 < 400 {
        client_ok = 1
        client_result = result2
    }
    check_int(client_ok, 1, "retry: client_ok is 1 after success")
    check_str(response_body(client_result), "\{\"ok\":true\}", "retry: body matches")
}

// ── Error classification pipeline ───────────────────────────────

fn test_error_classification_pipeline() {
    clear_all()

    let timeout_err = http_error_new(HTTP_ERR_TIMEOUT, "request timed out")
    let conn_err = http_error_new(HTTP_ERR_CONNECTION_REFUSED, "port 8080 refused")
    let dns_err = http_error_new(HTTP_ERR_DNS_FAILURE, "NXDOMAIN")
    let tls_err = http_error_new(HTTP_ERR_TLS, "cert expired")
    let parse_err = http_error_new(HTTP_ERR_PARSE, "unexpected EOF")
    let url_err = http_error_new(HTTP_ERR_INVALID_URL, "missing scheme")
    let status_err = http_error_new_status(429, "Too Many Requests")

    // Timeout: is_timeout=yes, is_network=no
    check_int(http_error_is_timeout(timeout_err), 1, "classify pipeline: timeout is_timeout")
    check_int(http_error_is_network(timeout_err), 0, "classify pipeline: timeout not network")

    // Network errors: is_network=yes, is_timeout=no
    check_int(http_error_is_network(conn_err), 1, "classify pipeline: conn is network")
    check_int(http_error_is_timeout(conn_err), 0, "classify pipeline: conn not timeout")
    check_int(http_error_is_network(dns_err), 1, "classify pipeline: dns is network")
    check_int(http_error_is_network(tls_err), 1, "classify pipeline: tls is network")

    // Non-network, non-timeout
    check_int(http_error_is_network(parse_err), 0, "classify pipeline: parse not network")
    check_int(http_error_is_timeout(parse_err), 0, "classify pipeline: parse not timeout")
    check_int(http_error_is_network(url_err), 0, "classify pipeline: url not network")
    check_int(http_error_is_timeout(url_err), 0, "classify pipeline: url not timeout")

    // Status errors
    check_int(http_error_is_network(status_err), 0, "classify pipeline: status not network")
    check_int(http_error_is_timeout(status_err), 0, "classify pipeline: status not timeout")
    check_int(http_error_code(status_err), 429, "classify pipeline: status code 429")
    check_str(http_error_display(status_err), "HTTP 429: Too Many Requests", "classify pipeline: status display")
}

// ── Overlapping route patterns across servers ───────────────────

fn test_overlapping_routes_different_servers() {
    clear_all()

    let api_srv = server_new("localhost", 8080)
    let admin_srv = server_new("localhost", 9090)

    server_route(api_srv, "GET", "/users/:id", HANDLER_JSON)
    server_route(admin_srv, "GET", "/users/:id", HANDLER_ECHO)
    server_route(api_srv, "GET", "/health", HANDLER_HEALTH)
    server_route(admin_srv, "GET", "/health", HANDLER_ERROR)

    // Same path, different servers -> different handlers
    let r1 = match_route(api_srv, "GET", "/users/42")
    check_int(r1 >= 0, 1, "overlap: api /users/42 found")
    check_int(route_handler(r1), HANDLER_JSON, "overlap: api handler is JSON")
    check_str(path_param("id"), "42", "overlap: api param id")

    let r2 = match_route(admin_srv, "GET", "/users/42")
    check_int(r2 >= 0, 1, "overlap: admin /users/42 found")
    check_int(route_handler(r2), HANDLER_ECHO, "overlap: admin handler is ECHO")

    // /health on api -> HEALTH, on admin -> ERROR
    let r3 = match_route(api_srv, "GET", "/health")
    check_int(route_handler(r3), HANDLER_HEALTH, "overlap: api /health -> HEALTH")

    let r4 = match_route(admin_srv, "GET", "/health")
    check_int(route_handler(r4), HANDLER_ERROR, "overlap: admin /health -> ERROR")
}

// ── Multi-method routing on same path ───────────────────────────

fn test_multi_method_same_path() {
    clear_all()

    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/items/:id", HANDLER_JSON)
    server_route(srv, "PUT", "/items/:id", HANDLER_ECHO)
    server_route(srv, "DELETE", "/items/:id", HANDLER_DELETE)
    server_route(srv, "POST", "/items", HANDLER_CREATED)

    check_int(route_count(srv), 4, "multi-method: 4 routes")

    let r_get = match_route(srv, "GET", "/items/5")
    check_int(route_handler(r_get), HANDLER_JSON, "multi-method: GET -> JSON")
    check_str(path_param("id"), "5", "multi-method: GET param")

    let r_put = match_route(srv, "PUT", "/items/5")
    check_int(route_handler(r_put), HANDLER_ECHO, "multi-method: PUT -> ECHO")
    check_str(path_param("id"), "5", "multi-method: PUT param")

    let r_del = match_route(srv, "DELETE", "/items/5")
    check_int(route_handler(r_del), HANDLER_DELETE, "multi-method: DELETE -> DELETE")
    check_str(path_param("id"), "5", "multi-method: DELETE param")

    let r_post = match_route(srv, "POST", "/items")
    check_int(route_handler(r_post), HANDLER_CREATED, "multi-method: POST -> CREATED")

    // PATCH not registered -> not found
    let r_patch = match_route(srv, "PATCH", "/items/5")
    check_int(r_patch, -1, "multi-method: PATCH not found")
}

// ── Path matching edge cases ────────────────────────────────────

fn test_path_matching_edges() {
    clear_all()

    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/", HANDLER_HEALTH)
    server_route(srv, "GET", "/a/b/c", HANDLER_ECHO)
    server_route(srv, "GET", "/a/:x/c", HANDLER_JSON)

    // Root path
    let r_root = match_route(srv, "GET", "/")
    // Note: split_path("/") returns empty list, so "/" matches "/" pattern
    check_int(r_root >= 0, 1, "path edge: root / matches")

    // Exact 3-segment match
    let r_abc = match_route(srv, "GET", "/a/b/c")
    check_int(r_abc >= 0, 1, "path edge: /a/b/c matches")
    check_int(route_handler(r_abc), HANDLER_ECHO, "path edge: /a/b/c handler")

    // Segment count mismatch -> no match
    let r_short = match_route(srv, "GET", "/a/b")
    check_int(r_short, -1, "path edge: /a/b no match (too few segments)")

    let r_long = match_route(srv, "GET", "/a/b/c/d")
    check_int(r_long, -1, "path edge: /a/b/c/d no match (too many segments)")

    // Trailing slash treated same (split_path strips trailing)
    let r_trail = match_route(srv, "GET", "/a/b/c/")
    check_int(r_trail >= 0, 1, "path edge: trailing slash matches")
}

// ── Path param with varied segment values ───────────────────────

fn test_path_param_varied_values() {
    clear_all()

    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/users/:id/posts/:post_id", HANDLER_HEALTH)

    // Numeric IDs
    let r1 = match_route(srv, "GET", "/users/123/posts/456")
    check_int(r1 >= 0, 1, "varied: numeric ids match")
    check_str(path_param("id"), "123", "varied: id=123")
    check_str(path_param("post_id"), "456", "varied: post_id=456")

    // UUID-like IDs
    let r2 = match_route(srv, "GET", "/users/abc-def/posts/ghi-jkl")
    check_int(r2 >= 0, 1, "varied: uuid-like match")
    check_str(path_param("id"), "abc-def", "varied: id=abc-def")
    check_str(path_param("post_id"), "ghi-jkl", "varied: post_id=ghi-jkl")

    // Single char IDs
    let r3 = match_route(srv, "GET", "/users/x/posts/y")
    check_int(r3 >= 0, 1, "varied: single char match")
    check_str(path_param("id"), "x", "varied: id=x")
    check_str(path_param("post_id"), "y", "varied: post_id=y")
}

// ── Full request->route->handler->response->error pipeline ──────

fn test_full_pipeline_success() {
    clear_all()

    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/items/:id", HANDLER_JSON)
    server_route(srv, "POST", "/items", HANDLER_CREATED)

    // GET /items/77 -> handler returns JSON with id
    let resp1 = roundtrip(srv, METHOD_GET, "/items/77", "")
    check_int(response_status(resp1), 200, "pipeline success: GET status 200")
    check_str(response_body(resp1), "\{\"id\":\"77\",\"found\":true\}", "pipeline success: GET body")
    check_str(resp_header_value(resp1, "Content-Type"), "application/json", "pipeline success: GET content-type")
    check_str(resp_header_value(resp1, "Cache-Control"), "no-cache", "pipeline success: GET cache-control")

    // POST /items -> handler returns 201
    let resp2 = roundtrip(srv, METHOD_POST, "/items", "\{\"name\":\"gadget\"\}")
    check_int(response_status(resp2), 201, "pipeline success: POST status 201")
    check_str(response_body(resp2), "\{\"name\":\"gadget\"\}", "pipeline success: POST body")
    check_str(resp_header_value(resp2, "Location"), "/items/new", "pipeline success: POST location")
}

// ── Full pipeline with error recovery ───────────────────────────

fn test_full_pipeline_error_recovery() {
    clear_all()

    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/items/:id", HANDLER_JSON)

    // Attempt unknown route -> 404
    let resp1 = roundtrip(srv, METHOD_GET, "/unknown", "")
    check_int(response_status(resp1), 404, "error recovery: 404 for unknown")

    let err = http_error_new_status(response_status(resp1), response_body(resp1))
    check_int(http_error_type(err), HTTP_ERR_STATUS, "error recovery: error type STATUS")
    check_int(http_error_code(err), 404, "error recovery: error code 404")
    check_str(http_error_type_name(http_error_type(err)), "status", "error recovery: type name")

    // Recover by trying a valid route
    let resp2 = roundtrip(srv, METHOD_GET, "/items/1", "")
    check_int(response_status(resp2), 200, "error recovery: success after error")
    check_str(response_body(resp2), "\{\"id\":\"1\",\"found\":true\}", "error recovery: body correct")
}

// ── Mock client + error creation + display integration ──────────

fn test_client_error_display_integration() {
    clear_all()

    // Connection refused scenario
    let result1 = mock_net_request(0)
    check_int(result1, -1, "client err display: mock returns -1")

    client_ok = 0
    client_result = http_error_new(HTTP_ERR_CONNECTION_REFUSED, "connection to api.example.com:443 refused")
    check_str(http_error_display(client_result), "connection_refused: connection to api.example.com:443 refused", "client err display: conn refused display")

    // Status error scenario
    http_client_clear()
    mock_reset()
    let resp = response_new(401, "Unauthorized")
    mock_add_response(resp)

    let result2 = mock_net_request(0)
    let status = response_status(result2)
    check_int(status, 401, "client err display: 401 status")

    client_ok = 0
    client_result = http_error_new_status(status, response_body(result2))
    check_str(http_error_display(client_result), "HTTP 401: Unauthorized", "client err display: 401 display")
    check_str(http_error_type_name(http_error_type(client_result)), "status", "client err display: type name")
}

// ── Handler with multiple response headers ──────────────────────

fn test_handler_multiple_response_headers() {
    clear_all()

    let srv = server_new("localhost", 8080)
    server_route(srv, "POST", "/echo", HANDLER_ECHO)

    let resp = roundtrip(srv, METHOD_POST, "/echo", "hello world")
    check_int(response_status(resp), 200, "multi headers: status 200")
    check_str(response_body(resp), "POST: hello world", "multi headers: echo body")
    check_str(resp_header_value(resp, "Content-Type"), "text/plain", "multi headers: content-type")
    check_str(resp_header_value(resp, "X-Echo"), "true", "multi headers: x-echo")
    check_int(resp_header_count(resp), 2, "multi headers: exactly 2 headers")
}

// ── Multiple responses with independent headers ─────────────────

fn test_multiple_responses_header_isolation() {
    clear_all()

    let r1 = response_new(200, "one")
    response_with_header(r1, "X-Id", "first")
    response_with_header(r1, "Content-Type", "text/plain")

    let r2 = response_new(200, "two")
    response_with_header(r2, "X-Id", "second")
    response_with_header(r2, "Content-Type", "application/json")
    response_with_header(r2, "Cache-Control", "max-age=3600")

    let r3 = response_new(204, "")

    check_int(resp_header_count(r1), 2, "header isolation: r1 has 2 headers")
    check_int(resp_header_count(r2), 3, "header isolation: r2 has 3 headers")
    check_int(resp_header_count(r3), 0, "header isolation: r3 has 0 headers")
    check_str(resp_header_value(r1, "X-Id"), "first", "header isolation: r1 X-Id")
    check_str(resp_header_value(r2, "X-Id"), "second", "header isolation: r2 X-Id")
    check_str(resp_header_value(r2, "Cache-Control"), "max-age=3600", "header isolation: r2 cache")
}

// ── Request header case sensitivity ─────────────────────────────

fn test_header_case_sensitivity() {
    clear_all()

    let req = request_new(METHOD_GET, "/test", "")
    request_add_header(req, "Content-Type", "text/html")
    request_add_header(req, "content-type", "application/xml")

    // Headers are case-sensitive in current implementation
    check_str(request_header(req, "Content-Type"), "text/html", "case: exact match Content-Type")
    check_str(request_header(req, "content-type"), "application/xml", "case: exact match content-type")
    check_str(request_header(req, "CONTENT-TYPE"), "", "case: all caps not found")
    check_int(req_header_count(req), 2, "case: both headers stored")
}

// ── All error constructors produce valid display strings ────────

fn test_all_error_types_display() {
    clear_all()

    let e0 = http_error_new(HTTP_ERR_TIMEOUT, "10s elapsed")
    let e1 = http_error_new(HTTP_ERR_CONNECTION_REFUSED, "ECONNREFUSED")
    let e2 = http_error_new(HTTP_ERR_DNS_FAILURE, "NXDOMAIN for api.test")
    let e3 = http_error_new(HTTP_ERR_INVALID_URL, "no host")
    let e4 = http_error_new(HTTP_ERR_TLS, "CERTIFICATE_VERIFY_FAILED")
    let e5 = http_error_new(HTTP_ERR_PARSE, "unexpected token")
    let e6 = http_error_new_status(418, "I'm a teapot")

    check_str(http_error_display(e0), "timeout: 10s elapsed", "all display: timeout")
    check_str(http_error_display(e1), "connection_refused: ECONNREFUSED", "all display: conn refused")
    check_str(http_error_display(e2), "dns_failure: NXDOMAIN for api.test", "all display: dns")
    check_str(http_error_display(e3), "invalid_url: no host", "all display: invalid url")
    check_str(http_error_display(e4), "tls: CERTIFICATE_VERIFY_FAILED", "all display: tls")
    check_str(http_error_display(e5), "parse: unexpected token", "all display: parse")
    check_str(http_error_display(e6), "HTTP 418: I'm a teapot", "all display: status 418")
}

// ── Error-to-response conversion for each error status ──────────

fn test_error_to_response_convenience() {
    clear_all()

    let e400 = http_error_new_status(400, "Bad Request")
    let r400 = response_bad_request(http_error_display(e400))
    check_int(response_status(r400), 400, "err->resp: 400 status")
    check_str(response_body(r400), "HTTP 400: Bad Request", "err->resp: 400 body")

    let e404 = http_error_new_status(404, "Not Found")
    let r404 = response_not_found(http_error_display(e404))
    check_int(response_status(r404), 404, "err->resp: 404 status")
    check_str(response_body(r404), "HTTP 404: Not Found", "err->resp: 404 body")

    let e500 = http_error_new_status(500, "Internal Server Error")
    let r500 = response_internal_error(http_error_display(e500))
    check_int(response_status(r500), 500, "err->resp: 500 status")
    check_str(response_body(r500), "HTTP 500: Internal Server Error", "err->resp: 500 body")
}

// ── Multiple requests to same server, state accumulation ────────

fn test_multi_request_state_accumulation() {
    clear_all()

    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/items/:id", HANDLER_JSON)

    let resp1 = roundtrip(srv, METHOD_GET, "/items/1", "")
    let resp2 = roundtrip(srv, METHOD_GET, "/items/2", "")
    let resp3 = roundtrip(srv, METHOD_GET, "/items/3", "")

    check_int(response_status(resp1), 200, "accumulation: resp1 status")
    check_int(response_status(resp2), 200, "accumulation: resp2 status")
    check_int(response_status(resp3), 200, "accumulation: resp3 status")

    check_str(response_body(resp1), "\{\"id\":\"1\",\"found\":true\}", "accumulation: resp1 body")
    check_str(response_body(resp2), "\{\"id\":\"2\",\"found\":true\}", "accumulation: resp2 body")
    check_str(response_body(resp3), "\{\"id\":\"3\",\"found\":true\}", "accumulation: resp3 body")

    // All 3 responses have independent headers
    check_str(resp_header_value(resp1, "Content-Type"), "application/json", "accumulation: resp1 ct")
    check_str(resp_header_value(resp2, "Content-Type"), "application/json", "accumulation: resp2 ct")
    check_str(resp_header_value(resp3, "Content-Type"), "application/json", "accumulation: resp3 ct")
}

// ── Handler receives correct request body for each method ───────

fn test_handler_sees_correct_request_body() {
    clear_all()

    let srv = server_new("localhost", 8080)
    server_route(srv, "POST", "/echo", HANDLER_ECHO)
    server_route(srv, "PUT", "/echo", HANDLER_ECHO)

    let resp_post = roundtrip(srv, METHOD_POST, "/echo", "post body")
    check_str(response_body(resp_post), "POST: post body", "handler body: POST echoed")

    let resp_put = roundtrip(srv, METHOD_PUT, "/echo", "put body")
    check_str(response_body(resp_put), "PUT: put body", "handler body: PUT echoed")
}

// ── Empty body handling across constructors ─────────────────────

fn test_empty_body_handling() {
    clear_all()

    // Request with empty body
    let req = request_new(METHOD_GET, "/test", "")
    check_str(request_body(req), "", "empty body: GET body empty")

    // Response constructors with empty body
    let r1 = response_new(204, "")
    check_str(response_body(r1), "", "empty body: 204 body empty")

    let r2 = response_bad_request("")
    check_str(response_body(r2), "", "empty body: bad_request body empty")
    check_int(response_status(r2), 400, "empty body: bad_request still 400")

    let r3 = response_not_found("")
    check_str(response_body(r3), "", "empty body: not_found body empty")
    check_int(response_status(r3), 404, "empty body: not_found still 404")
}

// ── Clear resets all state across modules ────────────────────────

fn test_clear_resets_cross_module() {
    // Build up state in all modules
    let req = request_new(METHOD_POST, "/data", "body")
    request_add_header(req, "H", "V")
    request_add_param(req, "P", "Q")
    let resp = response_new(200, "ok")
    response_with_header(resp, "X", "Y")
    let err = http_error_new(HTTP_ERR_TIMEOUT, "test")
    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/test", 1)

    check_int(req_methods.len() > 0, 1, "clear cross: req_methods populated")
    check_int(resp_statuses.len() > 0, 1, "clear cross: resp_statuses populated")
    check_int(http_err_types.len() > 0, 1, "clear cross: errors populated")
    check_int(route_methods.len() > 0, 1, "clear cross: routes populated")

    clear_all()

    check_int(req_methods.len(), 0, "clear cross: req_methods empty")
    check_int(req_paths.len(), 0, "clear cross: req_paths empty")
    check_int(req_bodies.len(), 0, "clear cross: req_bodies empty")
    check_int(req_param_names.len(), 0, "clear cross: req_params empty")
    check_int(req_header_names.len(), 0, "clear cross: req_headers empty")
    check_int(resp_statuses.len(), 0, "clear cross: resp_statuses empty")
    check_int(resp_bodies.len(), 0, "clear cross: resp_bodies empty")
    check_int(resp_header_names.len(), 0, "clear cross: resp_headers empty")
    check_int(http_err_types.len(), 0, "clear cross: errors empty")
    check_int(route_methods.len(), 0, "clear cross: routes empty")
    check_int(server_hosts.len(), 0, "clear cross: servers empty")
    check_int(client_ok, 1, "clear cross: client_ok reset")
    check_int(client_result, -1, "clear cross: client_result reset")
}

// ── All HTTP methods have consistent naming ─────────────────────

fn test_all_methods_roundtrip() {
    let mut m = 0
    while m <= 6 {
        let name = method_to_str(m)
        let back = method_from_str(name)
        check_int(back, m, "method roundtrip: {name} ({m})")
        m = m + 1
    }

    // Unknown in both directions
    check_str(method_to_str(-1), "UNKNOWN", "method roundtrip: -1 -> UNKNOWN")
    check_str(method_to_str(100), "UNKNOWN", "method roundtrip: 100 -> UNKNOWN")
    check_int(method_from_str("UNKNOWN"), -1, "method roundtrip: UNKNOWN -> -1")
    check_int(method_from_str(""), -1, "method roundtrip: empty -> -1")
    check_int(method_from_str("get"), -1, "method roundtrip: lowercase get -> -1")
}

// ── Status reason coverage ──────────────────────────────────────

fn test_status_reason_coverage() {
    check_str(status_reason(200), "OK", "status reason: 200")
    check_str(status_reason(201), "Created", "status reason: 201")
    check_str(status_reason(204), "No Content", "status reason: 204")
    check_str(status_reason(400), "Bad Request", "status reason: 400")
    check_str(status_reason(401), "Unauthorized", "status reason: 401")
    check_str(status_reason(403), "Forbidden", "status reason: 403")
    check_str(status_reason(404), "Not Found", "status reason: 404")
    check_str(status_reason(409), "Conflict", "status reason: 409")
    check_str(status_reason(500), "Internal Server Error", "status reason: 500")
    check_str(status_reason(502), "Bad Gateway", "status reason: 502")
    check_str(status_reason(503), "Service Unavailable", "status reason: 503")
    check_str(status_reason(0), "Unknown", "status reason: 0 unknown")
    check_str(status_reason(418), "Unknown", "status reason: 418 unknown")
    check_str(status_reason(-1), "Unknown", "status reason: -1 unknown")
}

// ── Route matching: first-match-wins behavior ───────────────────

fn test_first_match_wins() {
    clear_all()

    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/items/:id", HANDLER_JSON)
    server_route(srv, "GET", "/items/:name", HANDLER_ECHO)

    // Both patterns match /items/foo, but first registered wins
    let r = match_route(srv, "GET", "/items/foo")
    check_int(route_handler(r), HANDLER_JSON, "first match: first handler wins")
    check_str(path_param("id"), "foo", "first match: param from first pattern")
}

// ── Server error handler integration ────────────────────────────

fn test_server_error_handler() {
    clear_all()

    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/crash", HANDLER_ERROR)

    let resp = roundtrip(srv, METHOD_GET, "/crash", "")
    check_int(response_status(resp), 500, "server error: status 500")
    check_str(response_body(resp), "something broke", "server error: body")

    // Create error from response for client-side handling
    let err = http_error_new_status(response_status(resp), response_body(resp))
    check_int(http_error_is_network(err), 0, "server error: not network")
    check_int(http_error_is_timeout(err), 0, "server error: not timeout")
    check_str(http_error_display(err), "HTTP 500: something broke", "server error: display")
}

fn main() {
    test_response_builder_chaining()
    test_status_override_preserves_headers()
    test_request_many_params_and_headers()
    test_method_string_to_route_pipeline()
    test_sequential_mock_retry_flow()
    test_error_classification_pipeline()
    test_overlapping_routes_different_servers()
    test_multi_method_same_path()
    test_path_matching_edges()
    test_path_param_varied_values()
    test_full_pipeline_success()
    test_full_pipeline_error_recovery()
    test_client_error_display_integration()
    test_handler_multiple_response_headers()
    test_multiple_responses_header_isolation()
    test_header_case_sensitivity()
    test_all_error_types_display()
    test_error_to_response_convenience()
    test_multi_request_state_accumulation()
    test_handler_sees_correct_request_body()
    test_empty_body_handling()
    test_clear_resets_cross_module()
    test_all_methods_roundtrip()
    test_status_reason_coverage()
    test_first_match_wins()
    test_server_error_handler()

    io.println("All http umbrella tests complete")
}
