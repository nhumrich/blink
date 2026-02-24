pub type Request {
    method: Str
    url: Str
    body: Str
    headers: Map[Str, Str]
    timeout_ms: Int
}

pub type Response {
    status: Int
    body: Str
    headers: Map[Str, Str]
}

pub fn request_new(method: Str, url: Str) -> Request {
    Request { method: method, url: url, body: "", headers: Map(), timeout_ms: 30000 }
}

pub fn response_new(status: Int, body: Str) -> Response {
    Response { status: status, body: body, headers: Map() }
}

pub fn response_ok(body: Str) -> Response {
    Response { status: 200, body: body, headers: Map() }
}

pub fn response_not_found(msg: Str) -> Response {
    Response { status: 404, body: msg, headers: Map() }
}

pub fn response_bad_request(msg: Str) -> Response {
    Response { status: 400, body: msg, headers: Map() }
}

pub fn response_internal_error(msg: Str) -> Response {
    Response { status: 500, body: msg, headers: Map() }
}

pub fn response_json(body: Str) -> Response {
    let hdrs: Map[Str, Str] = Map()
    hdrs.set("Content-Type", "application/json")
    Response { status: 200, body: body, headers: hdrs }
}

pub fn request_with_body(req: Request, body: Str) -> Request {
    Request { method: req.method, url: req.url, body: body, headers: req.headers, timeout_ms: req.timeout_ms }
}

pub fn request_with_header(req: Request, name: Str, value: Str) -> Request {
    let hdrs = req.headers
    hdrs.set(name, value)
    Request { method: req.method, url: req.url, body: req.body, headers: hdrs, timeout_ms: req.timeout_ms }
}

pub fn request_with_timeout(req: Request, ms: Int) -> Request {
    Request { method: req.method, url: req.url, body: req.body, headers: req.headers, timeout_ms: ms }
}

pub fn response_is_ok(resp: Response) -> Bool {
    resp.status >= 200 && resp.status < 300
}

pub fn method_to_str(m: Str) -> Str {
    m
}

pub fn method_from_str(s: Str) -> Str {
    s
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
    if code == 301 {
        return "Moved Permanently"
    }
    if code == 302 {
        return "Found"
    }
    if code == 304 {
        return "Not Modified"
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
    if code == 405 {
        return "Method Not Allowed"
    }
    if code == 409 {
        return "Conflict"
    }
    if code == 422 {
        return "Unprocessable Entity"
    }
    if code == 429 {
        return "Too Many Requests"
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
    if code == 504 {
        return "Gateway Timeout"
    }
    "Unknown"
}
