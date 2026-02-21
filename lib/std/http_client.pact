// http_client.pact — HTTP client convenience functions
//
// Wraps http_types request/response with convenience methods.
// Actual networking delegated to net.request() effect operation.

import std.http_types
import std.http_error

// ── Result pair (since no Result type in C backend) ────────────────
pub let mut client_ok: Int = 1
pub let mut client_result: Int = -1

// ── Convenience functions ──────────────────────────────────────────

pub fn get(url: Str) -> Int ! Net.Connect, Net.DNS {
    let req = request_new(METHOD_GET, url, "")
    request(req)
}

pub fn post(url: Str, body: Str) -> Int ! Net.Connect, Net.DNS {
    let req = request_new(METHOD_POST, url, body)
    request(req)
}

pub fn put(url: Str, body: Str) -> Int ! Net.Connect, Net.DNS {
    let req = request_new(METHOD_PUT, url, body)
    request(req)
}

pub fn delete(url: Str) -> Int ! Net.Connect, Net.DNS {
    let req = request_new(METHOD_DELETE, url, "")
    request(req)
}

pub fn request(req_idx: Int) -> Int ! Net.Connect, Net.DNS {
    let resp = net.request(req_idx)
    if resp < 0 {
        client_ok = 0
        client_result = http_error_new(HTTP_ERR_CONNECTION_REFUSED, "request failed")
        return client_result
    }
    let status = response_status(resp)
    if status >= 400 {
        client_ok = 0
        client_result = http_error_new_status(status, response_body(resp))
        return client_result
    }
    client_ok = 1
    client_result = resp
    resp
}

pub fn request_with_headers(req_idx: Int, header_pairs: List[Str]) -> Int ! Net.Connect, Net.DNS {
    let mut i = 0
    while i < header_pairs.len() - 1 {
        request_add_header(req_idx, header_pairs.get(i), header_pairs.get(i + 1))
        i = i + 2
    }
    request(req_idx)
}

pub fn http_client_clear() {
    client_ok = 1
    client_result = -1
}
