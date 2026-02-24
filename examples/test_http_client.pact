import std.http_types
import std.http_error

fn check(cond: Int, label: Str) {
    if cond != 0 {
        io.println("PASS: {label}")
    } else {
        io.println("FAIL: {label}")
    }
}

fn test_request_construction() {
    io.println("--- Request construction ---")
    let req = request_new("GET", "http://example.com/test")
    check(req.method == "GET", "method is GET")
    check(req.url == "http://example.com/test", "url set")
    check(req.timeout_ms == 30000, "default timeout")

    let req2 = request_with_body(req, "hello")
    check(req2.body == "hello", "body set")

    let req3 = request_with_header(req, "Accept", "application/json")
    check(req3.method == "GET", "header request preserved method")
}

fn test_response_helpers() {
    io.println("--- Response helpers ---")
    let r = response_ok("hi")
    check(r.status == 200, "response_ok status")
    check(r.body == "hi", "response_ok body")
    check(response_is_ok(r) != 0, "response_is_ok true")

    let r2 = response_not_found("nope")
    check(r2.status == 404, "not_found status")
}

fn main() {
    io.println("=== HTTP client tests ===")
    test_request_construction()
    test_response_helpers()
    io.println("=== done ===")
}
