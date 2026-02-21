// http_error.pact — HTTP error types for structured error handling
//
// Parallel-array storage for HTTP errors with type tags, messages,
// and optional HTTP status codes.

// ── Error type tags ─────────────────────────────────────────────────
pub let HTTP_ERR_TIMEOUT = 0
pub let HTTP_ERR_CONNECTION_REFUSED = 1
pub let HTTP_ERR_DNS_FAILURE = 2
pub let HTTP_ERR_INVALID_URL = 3
pub let HTTP_ERR_TLS = 4
pub let HTTP_ERR_PARSE = 5
pub let HTTP_ERR_STATUS = 6

// ── Global store: parallel arrays ───────────────────────────────────
pub let mut http_err_types: List[Int] = []
pub let mut http_err_messages: List[Str] = []
pub let mut http_err_codes: List[Int] = []

// ── Constructor ─────────────────────────────────────────────────────

pub fn http_error_new(etype: Int, msg: Str) -> Int {
    let idx = http_err_types.len()
    http_err_types.push(etype)
    http_err_messages.push(msg)
    http_err_codes.push(0)
    idx
}

pub fn http_error_new_status(code: Int, msg: Str) -> Int {
    let idx = http_err_types.len()
    http_err_types.push(HTTP_ERR_STATUS)
    http_err_messages.push(msg)
    http_err_codes.push(code)
    idx
}

// ── Getters ─────────────────────────────────────────────────────────

pub fn http_error_type(idx: Int) -> Int {
    if idx < 0 || idx >= http_err_types.len() {
        return -1
    }
    http_err_types.get(idx)
}

pub fn http_error_message(idx: Int) -> Str {
    if idx < 0 || idx >= http_err_messages.len() {
        return ""
    }
    http_err_messages.get(idx)
}

pub fn http_error_code(idx: Int) -> Int {
    if idx < 0 || idx >= http_err_codes.len() {
        return 0
    }
    http_err_codes.get(idx)
}

// ── Type name mapping ───────────────────────────────────────────────

pub fn http_error_type_name(etype: Int) -> Str {
    if etype == HTTP_ERR_TIMEOUT {
        return "timeout"
    }
    if etype == HTTP_ERR_CONNECTION_REFUSED {
        return "connection_refused"
    }
    if etype == HTTP_ERR_DNS_FAILURE {
        return "dns_failure"
    }
    if etype == HTTP_ERR_INVALID_URL {
        return "invalid_url"
    }
    if etype == HTTP_ERR_TLS {
        return "tls"
    }
    if etype == HTTP_ERR_PARSE {
        return "parse"
    }
    if etype == HTTP_ERR_STATUS {
        return "status"
    }
    "unknown"
}

// ── Display ─────────────────────────────────────────────────────────

pub fn http_error_display(idx: Int) -> Str {
    if idx < 0 || idx >= http_err_types.len() {
        return "unknown error"
    }
    let etype = http_err_types.get(idx)
    let msg = http_err_messages.get(idx)
    if etype == HTTP_ERR_STATUS {
        let code = http_err_codes.get(idx)
        return "HTTP {code}: {msg}"
    }
    let name = http_error_type_name(etype)
    "{name}: {msg}"
}

// ── Classification helpers ──────────────────────────────────────────

pub fn http_error_is_timeout(idx: Int) -> Int {
    if idx < 0 || idx >= http_err_types.len() {
        return 0
    }
    if http_err_types.get(idx) == HTTP_ERR_TIMEOUT {
        return 1
    }
    0
}

pub fn http_error_is_network(idx: Int) -> Int {
    if idx < 0 || idx >= http_err_types.len() {
        return 0
    }
    let etype = http_err_types.get(idx)
    if etype == HTTP_ERR_CONNECTION_REFUSED {
        return 1
    }
    if etype == HTTP_ERR_DNS_FAILURE {
        return 1
    }
    if etype == HTTP_ERR_TLS {
        return 1
    }
    0
}

// ── State management ────────────────────────────────────────────────

pub fn http_error_clear() {
    http_err_types = []
    http_err_messages = []
    http_err_codes = []
}
