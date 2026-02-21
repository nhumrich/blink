// http_types.pact — HTTP request/response types using parallel arrays
//
// Provides: method/status constants, request/response builders,
// header and query param management. No actual networking.

// ── Method constants ─────────────────────────────────────────────
pub let METHOD_GET = 0
pub let METHOD_POST = 1
pub let METHOD_PUT = 2
pub let METHOD_DELETE = 3
pub let METHOD_PATCH = 4
pub let METHOD_HEAD = 5
pub let METHOD_OPTIONS = 6

// ── Status codes ─────────────────────────────────────────────────
pub let STATUS_OK = 200
pub let STATUS_CREATED = 201
pub let STATUS_NO_CONTENT = 204
pub let STATUS_BAD_REQUEST = 400
pub let STATUS_UNAUTHORIZED = 401
pub let STATUS_FORBIDDEN = 403
pub let STATUS_NOT_FOUND = 404
pub let STATUS_CONFLICT = 409
pub let STATUS_INTERNAL_ERROR = 500
pub let STATUS_BAD_GATEWAY = 502
pub let STATUS_SERVICE_UNAVAILABLE = 503

// ── Request storage (parallel arrays) ────────────────────────────
pub let mut req_methods: List[Int] = []
pub let mut req_paths: List[Str] = []
pub let mut req_bodies: List[Str] = []
pub let mut req_param_names: List[Str] = []
pub let mut req_param_values: List[Str] = []
pub let mut req_param_owners: List[Int] = []
pub let mut req_header_names: List[Str] = []
pub let mut req_header_values: List[Str] = []
pub let mut req_header_owners: List[Int] = []

// ── Response storage (parallel arrays) ───────────────────────────
pub let mut resp_statuses: List[Int] = []
pub let mut resp_bodies: List[Str] = []
pub let mut resp_header_names: List[Str] = []
pub let mut resp_header_values: List[Str] = []
pub let mut resp_header_owners: List[Int] = []

// ── Request API ──────────────────────────────────────────────────

pub fn request_new(method: Int, path: Str, body: Str) -> Int {
    let idx = req_methods.len()
    req_methods.push(method)
    req_paths.push(path)
    req_bodies.push(body)
    idx
}

pub fn request_method(idx: Int) -> Int {
    req_methods.get(idx)
}

pub fn request_path(idx: Int) -> Str {
    req_paths.get(idx)
}

pub fn request_body(idx: Int) -> Str {
    req_bodies.get(idx)
}

pub fn request_param(idx: Int, name: Str) -> Str {
    let mut i = 0
    while i < req_param_owners.len() {
        if req_param_owners.get(i) == idx && req_param_names.get(i) == name {
            return req_param_values.get(i)
        }
        i = i + 1
    }
    ""
}

pub fn request_header(idx: Int, name: Str) -> Str {
    let mut i = 0
    while i < req_header_owners.len() {
        if req_header_owners.get(i) == idx && req_header_names.get(i) == name {
            return req_header_values.get(i)
        }
        i = i + 1
    }
    ""
}

pub fn request_add_param(idx: Int, name: Str, value: Str) {
    req_param_names.push(name)
    req_param_values.push(value)
    req_param_owners.push(idx)
}

pub fn request_add_header(idx: Int, name: Str, value: Str) {
    req_header_names.push(name)
    req_header_values.push(value)
    req_header_owners.push(idx)
}

// ── Response API ─────────────────────────────────────────────────

pub fn response_new(status: Int, body: Str) -> Int {
    let idx = resp_statuses.len()
    resp_statuses.push(status)
    resp_bodies.push(body)
    idx
}

pub fn response_json_str(body: Str) -> Int {
    let idx = response_new(200, body)
    response_with_header(idx, "Content-Type", "application/json")
    idx
}

pub fn response_bad_request(msg: Str) -> Int {
    response_new(400, msg)
}

pub fn response_not_found(msg: Str) -> Int {
    response_new(404, msg)
}

pub fn response_internal_error(msg: Str) -> Int {
    response_new(500, msg)
}

pub fn response_with_status(idx: Int, status: Int) -> Int {
    resp_statuses.set(idx, status)
    idx
}

pub fn response_with_header(idx: Int, name: Str, val: Str) -> Int {
    resp_header_names.push(name)
    resp_header_values.push(val)
    resp_header_owners.push(idx)
    idx
}

pub fn response_body(idx: Int) -> Str {
    resp_bodies.get(idx)
}

pub fn response_status(idx: Int) -> Int {
    resp_statuses.get(idx)
}

// ── Helpers ──────────────────────────────────────────────────────

pub fn method_to_str(m: Int) -> Str {
    if m == 0 {
        return "GET"
    }
    if m == 1 {
        return "POST"
    }
    if m == 2 {
        return "PUT"
    }
    if m == 3 {
        return "DELETE"
    }
    if m == 4 {
        return "PATCH"
    }
    if m == 5 {
        return "HEAD"
    }
    if m == 6 {
        return "OPTIONS"
    }
    "UNKNOWN"
}

pub fn method_from_str(s: Str) -> Int {
    if s == "GET" {
        return 0
    }
    if s == "POST" {
        return 1
    }
    if s == "PUT" {
        return 2
    }
    if s == "DELETE" {
        return 3
    }
    if s == "PATCH" {
        return 4
    }
    if s == "HEAD" {
        return 5
    }
    if s == "OPTIONS" {
        return 6
    }
    -1
}

pub fn status_reason(code: Int) -> Str {
    if code == 200 {
        return "OK"
    }
    if code == 201 {
        return "Created"
    }
    if code == 204 {
        return "No Content"
    }
    if code == 400 {
        return "Bad Request"
    }
    if code == 401 {
        return "Unauthorized"
    }
    if code == 403 {
        return "Forbidden"
    }
    if code == 404 {
        return "Not Found"
    }
    if code == 409 {
        return "Conflict"
    }
    if code == 500 {
        return "Internal Server Error"
    }
    if code == 502 {
        return "Bad Gateway"
    }
    if code == 503 {
        return "Service Unavailable"
    }
    "Unknown"
}

pub fn http_types_clear() {
    req_methods = []
    req_paths = []
    req_bodies = []
    req_param_names = []
    req_param_values = []
    req_param_owners = []
    req_header_names = []
    req_header_values = []
    req_header_owners = []
    resp_statuses = []
    resp_bodies = []
    resp_header_names = []
    resp_header_values = []
    resp_header_owners = []
}
