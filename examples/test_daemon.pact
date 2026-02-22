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

fn has_substr(haystack: Str, needle: Str) -> Int {
    if needle.len() > haystack.len() {
        return 0
    }
    let mut i = 0
    while i <= haystack.len() - needle.len() {
        if haystack.substring(i, needle.len()) == needle {
            return 1
        }
        i = i + 1
    }
    0
}

// Minimal JSON key extractor for flat objects: {"key":"value",...}
fn json_get_str(json: Str, key: Str) -> Str {
    let needle = "\"".concat(key).concat("\":\"")
    let mut i = 0
    while i <= json.len() - needle.len() {
        if json.substring(i, needle.len()) == needle {
            let val_start = i + needle.len()
            let mut j = val_start
            while j < json.len() {
                if json.char_at(j) == 34 {
                    return json.substring(val_start, j - val_start)
                }
                if json.char_at(j) == 92 {
                    j = j + 2
                } else {
                    j = j + 1
                }
            }
            return ""
        }
        i = i + 1
    }
    ""
}

// --- Protocol format tests ---

fn test_status_request() {
    let req = "\{\"type\":\"status\"}"
    check_str(json_get_str(req, "type"), "status", "status request: type field")
}

fn test_stop_request() {
    let req = "\{\"type\":\"stop\"}"
    check_str(json_get_str(req, "type"), "stop", "stop request: type field")
}

fn test_query_fn_request() {
    let name = "my_func"
    let req = "\{\"type\":\"query\",\"query_type\":\"fn\",\"name\":\"{name}\"}"
    check_str(json_get_str(req, "type"), "query", "query fn request: type")
    check_str(json_get_str(req, "query_type"), "fn", "query fn request: query_type")
    check_str(json_get_str(req, "name"), "my_func", "query fn request: name")
}

fn test_query_effect_request() {
    let eff_name = "IO"
    let req = "\{\"type\":\"query\",\"query_type\":\"effect\",\"effect\":\"{eff_name}\"}"
    check_str(json_get_str(req, "type"), "query", "query effect request: type")
    check_str(json_get_str(req, "query_type"), "effect", "query effect request: query_type")
    check_str(json_get_str(req, "effect"), "IO", "query effect request: effect")
}

fn test_query_signature_request() {
    let mod_name = "main"
    let req = "\{\"type\":\"query\",\"query_type\":\"signature\",\"module\":\"{mod_name}\"}"
    check_str(json_get_str(req, "type"), "query", "query sig request: type")
    check_str(json_get_str(req, "query_type"), "signature", "query sig request: query_type")
    check_str(json_get_str(req, "module"), "main", "query sig request: module")
}

fn test_query_pub_pure_request() {
    let req = "\{\"type\":\"query\",\"query_type\":\"pub_pure\"}"
    check_str(json_get_str(req, "type"), "query", "query pub_pure request: type")
    check_str(json_get_str(req, "query_type"), "pub_pure", "query pub_pure request: query_type")
}

// --- Response format tests ---

fn test_status_response_format() {
    let resp = "\{\"ok\":true,\"uptime_ms\":12345,\"symbols\":10,\"files\":2,\"checks\":3}"
    check_str(json_get_str(resp, "uptime_ms"), "", "status response: uptime_ms not a string (numeric)")
    check_int(has_substr(resp, "\"ok\":true"), 1, "status response: has ok field")
    check_int(has_substr(resp, "\"uptime_ms\":"), 1, "status response: has uptime_ms")
    check_int(has_substr(resp, "\"symbols\":"), 1, "status response: has symbols")
    check_int(has_substr(resp, "\"files\":"), 1, "status response: has files")
    check_int(has_substr(resp, "\"checks\":"), 1, "status response: has checks")
}

fn test_stop_response_format() {
    let resp = "\{\"ok\":true,\"message\":\"daemon stopping\"}"
    check_int(has_substr(resp, "\"ok\":true"), 1, "stop response: has ok")
    check_str(json_get_str(resp, "message"), "daemon stopping", "stop response: message")
}

fn test_error_response_format() {
    let resp = "\{\"ok\":false,\"error\":\"unknown request type: bogus\"}"
    check_int(has_substr(resp, "\"ok\":false"), 1, "error response: ok is false")
    check_int(has_substr(resp, "\"error\":"), 1, "error response: has error field")
}

// --- JSON key extractor edge cases ---

fn test_json_get_missing_key() {
    let json = "\{\"type\":\"status\"}"
    check_str(json_get_str(json, "missing"), "", "json_get: missing key returns empty")
}

fn test_json_get_empty_value() {
    let json = "\{\"type\":\"\"}"
    check_str(json_get_str(json, "type"), "", "json_get: empty value")
}

fn test_json_get_multiple_keys() {
    let json = "\{\"a\":\"one\",\"b\":\"two\",\"c\":\"three\"}"
    check_str(json_get_str(json, "a"), "one", "json_get multi: first key")
    check_str(json_get_str(json, "b"), "two", "json_get multi: second key")
    check_str(json_get_str(json, "c"), "three", "json_get multi: third key")
}

// --- Check request construction matches daemon expectations ---

fn test_check_request() {
    let req = "\{\"type\":\"check\"}"
    check_str(json_get_str(req, "type"), "check", "check request: type field")
}

fn test_query_dispatch_request() {
    let req = "\{\"type\":\"signature\",\"module\":\"codegen\"}"
    check_str(json_get_str(req, "type"), "signature", "dispatch request: type")
    check_str(json_get_str(req, "module"), "codegen", "dispatch request: module")
}

fn main() {
    test_status_request()
    test_stop_request()
    test_query_fn_request()
    test_query_effect_request()
    test_query_signature_request()
    test_query_pub_pure_request()
    test_status_response_format()
    test_stop_response_format()
    test_error_response_format()
    test_json_get_missing_key()
    test_json_get_empty_value()
    test_json_get_multiple_keys()
    test_check_request()
    test_query_dispatch_request()

    io.println("All daemon tests complete")
}
