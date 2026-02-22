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

// ── Route storage (mirrors http_server.pact) ────────────────────
let mut route_methods: List[Str] = []
let mut route_patterns: List[Str] = []
let mut route_handlers: List[Int] = []
let mut route_server_owners: List[Int] = []

// ── Path param storage (per-request, reset each match) ──────────
let mut param_names: List[Str] = []
let mut param_values: List[Str] = []

// ── Server storage ──────────────────────────────────────────────
let mut server_hosts: List[Str] = []
let mut server_ports: List[Int] = []

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

fn clear_all() {
    http_types_clear()
    http_error_clear()
    server_hosts = []
    server_ports = []
    route_methods = []
    route_patterns = []
    route_handlers = []
    route_server_owners = []
    param_names = []
    param_values = []
}

// ── Handler IDs (simulate function pointers as int tags) ────────
let HANDLER_LIST_USERS = 1
let HANDLER_GET_USER = 2
let HANDLER_CREATE_USER = 3
let HANDLER_DELETE_USER = 4
let HANDLER_HEALTH = 5

fn dispatch_handler(handler_id: Int, req_idx: Int) -> Int {
    if handler_id == HANDLER_LIST_USERS {
        return handle_list_users(req_idx)
    }
    if handler_id == HANDLER_GET_USER {
        return handle_get_user(req_idx)
    }
    if handler_id == HANDLER_CREATE_USER {
        return handle_create_user(req_idx)
    }
    if handler_id == HANDLER_DELETE_USER {
        return handle_delete_user(req_idx)
    }
    if handler_id == HANDLER_HEALTH {
        return handle_health(req_idx)
    }
    response_not_found("unknown handler")
}

// ── Mock handlers ───────────────────────────────────────────────

fn handle_list_users(req_idx: Int) -> Int {
    let resp = response_new(STATUS_OK, "[\"alice\",\"bob\"]")
    response_with_header(resp, "Content-Type", "application/json")
    resp
}

fn handle_get_user(req_idx: Int) -> Int {
    let id = path_param("id")
    if id == "" {
        return response_bad_request("missing user id")
    }
    let body = "\{\"id\":\"{id}\",\"name\":\"User {id}\"\}"
    let resp = response_new(STATUS_OK, body)
    response_with_header(resp, "Content-Type", "application/json")
    resp
}

fn handle_create_user(req_idx: Int) -> Int {
    let body = request_body(req_idx)
    if body == "" {
        return response_bad_request("empty body")
    }
    let resp = response_new(STATUS_CREATED, body)
    response_with_header(resp, "Content-Type", "application/json")
    resp
}

fn handle_delete_user(req_idx: Int) -> Int {
    let id = path_param("id")
    if id == "" {
        return response_bad_request("missing user id")
    }
    response_new(STATUS_NO_CONTENT, "")
}

fn handle_health(req_idx: Int) -> Int {
    response_new(STATUS_OK, "ok")
}

// ── Helper: full roundtrip ──────────────────────────────────────

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

// ── Tests ───────────────────────────────────────────────────────

fn setup_server() -> Int {
    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/health", HANDLER_HEALTH)
    server_route(srv, "GET", "/users", HANDLER_LIST_USERS)
    server_route(srv, "GET", "/users/:id", HANDLER_GET_USER)
    server_route(srv, "POST", "/users", HANDLER_CREATE_USER)
    server_route(srv, "DELETE", "/users/:id", HANDLER_DELETE_USER)
    srv
}

fn test_get_health() {
    clear_all()
    let srv = setup_server()

    let resp = roundtrip(srv, METHOD_GET, "/health", "")
    check_int(response_status(resp), 200, "health: status 200")
    check_str(response_body(resp), "ok", "health: body is ok")
}

fn test_list_users() {
    clear_all()
    let srv = setup_server()

    let resp = roundtrip(srv, METHOD_GET, "/users", "")
    check_int(response_status(resp), 200, "list users: status 200")
    check_str(response_body(resp), "[\"alice\",\"bob\"]", "list users: body")
}

fn test_get_user_by_id() {
    clear_all()
    let srv = setup_server()

    let resp = roundtrip(srv, METHOD_GET, "/users/42", "")
    check_int(response_status(resp), 200, "get user: status 200")
    check_str(response_body(resp), "\{\"id\":\"42\",\"name\":\"User 42\"\}", "get user: body")
}

fn test_get_user_path_param() {
    clear_all()
    let srv = setup_server()

    let req = request_new(METHOD_GET, "/users/99", "")
    let route_idx = match_route(srv, "GET", "/users/99")
    check_int(route_idx >= 0, 1, "path param: route found")
    check_str(path_param("id"), "99", "path param: id == 99")
    check_int(route_handler(route_idx), HANDLER_GET_USER, "path param: correct handler")
}

fn test_create_user() {
    clear_all()
    let srv = setup_server()

    let body = "\{\"name\":\"charlie\"\}"
    let resp = roundtrip(srv, METHOD_POST, "/users", body)
    check_int(response_status(resp), 201, "create user: status 201")
    check_str(response_body(resp), body, "create user: body echoed back")
}

fn test_create_user_empty_body() {
    clear_all()
    let srv = setup_server()

    let resp = roundtrip(srv, METHOD_POST, "/users", "")
    check_int(response_status(resp), 400, "create empty: status 400")
    check_str(response_body(resp), "empty body", "create empty: error message")
}

fn test_delete_user() {
    clear_all()
    let srv = setup_server()

    let resp = roundtrip(srv, METHOD_DELETE, "/users/7", "")
    check_int(response_status(resp), 204, "delete user: status 204")
    check_str(response_body(resp), "", "delete user: empty body")
}

fn test_route_not_found() {
    clear_all()
    let srv = setup_server()

    let resp = roundtrip(srv, METHOD_GET, "/nonexistent", "")
    check_int(response_status(resp), 404, "not found: status 404")
}

fn test_method_not_matched() {
    clear_all()
    let srv = setup_server()

    let resp = roundtrip(srv, METHOD_PUT, "/users", "")
    check_int(response_status(resp), 404, "wrong method: status 404")
}

fn test_route_dispatch_correct_handler() {
    clear_all()
    let srv = setup_server()

    let r0 = match_route(srv, "GET", "/health")
    check_int(route_handler(r0), HANDLER_HEALTH, "dispatch: GET /health -> HEALTH")

    path_param_clear()
    let r1 = match_route(srv, "GET", "/users")
    check_int(route_handler(r1), HANDLER_LIST_USERS, "dispatch: GET /users -> LIST_USERS")

    path_param_clear()
    let r2 = match_route(srv, "GET", "/users/5")
    check_int(route_handler(r2), HANDLER_GET_USER, "dispatch: GET /users/5 -> GET_USER")

    path_param_clear()
    let r3 = match_route(srv, "POST", "/users")
    check_int(route_handler(r3), HANDLER_CREATE_USER, "dispatch: POST /users -> CREATE_USER")

    path_param_clear()
    let r4 = match_route(srv, "DELETE", "/users/3")
    check_int(route_handler(r4), HANDLER_DELETE_USER, "dispatch: DELETE /users/3 -> DELETE_USER")
}

fn test_handler_receives_request_data() {
    clear_all()
    let srv = setup_server()

    let req = request_new(METHOD_POST, "/users", "\{\"name\":\"diana\"\}")
    request_add_header(req, "Content-Type", "application/json")
    request_add_header(req, "Authorization", "Bearer tok123")

    check_int(request_method(req), METHOD_POST, "handler data: method is POST")
    check_str(request_path(req), "/users", "handler data: path is /users")
    check_str(request_body(req), "\{\"name\":\"diana\"\}", "handler data: body matches")
    check_str(request_header(req, "Content-Type"), "application/json", "handler data: content-type")
    check_str(request_header(req, "Authorization"), "Bearer tok123", "handler data: auth header")

    let route_idx = match_route(srv, "POST", "/users")
    check_int(route_idx >= 0, 1, "handler data: route matched")
    let handler_id = route_handler(route_idx)
    let resp = dispatch_handler(handler_id, req)
    check_int(response_status(resp), 201, "handler data: response 201")
    check_str(response_body(resp), "\{\"name\":\"diana\"\}", "handler data: response body echoed")
}

fn test_response_headers_flow_back() {
    clear_all()
    let srv = setup_server()

    let resp = roundtrip(srv, METHOD_GET, "/users", "")
    check_int(response_status(resp), 200, "resp headers: status 200")

    let mut found_ct = 0
    let mut i = 0
    while i < resp_header_owners.len() {
        if resp_header_owners.get(i) == resp && resp_header_names.get(i) == "Content-Type" {
            check_str(resp_header_values.get(i), "application/json", "resp headers: Content-Type is application/json")
            found_ct = 1
        }
        i = i + 1
    }
    check_int(found_ct, 1, "resp headers: Content-Type header found")
}

fn test_multiple_path_params() {
    clear_all()
    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/orgs/:org_id/users/:user_id", HANDLER_HEALTH)

    let route_idx = match_route(srv, "GET", "/orgs/acme/users/42")
    check_int(route_idx >= 0, 1, "multi param: route matched")
    check_str(path_param("org_id"), "acme", "multi param: org_id == acme")
    check_str(path_param("user_id"), "42", "multi param: user_id == 42")
}

fn test_error_roundtrip() {
    clear_all()
    let srv = setup_server()

    let resp = roundtrip(srv, METHOD_GET, "/nonexistent", "")
    let status = response_status(resp)
    check_int(status, 404, "error roundtrip: status 404")

    let err = http_error_new_status(status, response_body(resp))
    check_int(http_error_type(err), HTTP_ERR_STATUS, "error roundtrip: error type STATUS")
    check_int(http_error_code(err), 404, "error roundtrip: error code 404")
}

fn test_server_isolation() {
    clear_all()
    let srv1 = server_new("localhost", 8080)
    let srv2 = server_new("localhost", 9090)

    server_route(srv1, "GET", "/a", HANDLER_HEALTH)
    server_route(srv2, "GET", "/b", HANDLER_LIST_USERS)

    let r1 = match_route(srv1, "GET", "/a")
    check_int(r1 >= 0, 1, "isolation: srv1 /a found")
    check_int(route_handler(r1), HANDLER_HEALTH, "isolation: srv1 /a handler")

    let r2 = match_route(srv1, "GET", "/b")
    check_int(r2, -1, "isolation: srv1 /b not found")

    let r3 = match_route(srv2, "GET", "/b")
    check_int(r3 >= 0, 1, "isolation: srv2 /b found")
    check_int(route_handler(r3), HANDLER_LIST_USERS, "isolation: srv2 /b handler")

    let r4 = match_route(srv2, "GET", "/a")
    check_int(r4, -1, "isolation: srv2 /a not found")
}

fn main() {
    test_get_health()
    test_list_users()
    test_get_user_by_id()
    test_get_user_path_param()
    test_create_user()
    test_create_user_empty_body()
    test_delete_user()
    test_route_not_found()
    test_method_not_matched()
    test_route_dispatch_correct_handler()
    test_handler_receives_request_data()
    test_response_headers_flow_back()
    test_multiple_path_params()
    test_error_roundtrip()
    test_server_isolation()

    io.println("All http_integration tests complete")
}
