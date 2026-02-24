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

fn test_new_basic_errors() {
    http_error_clear()

    let e0 = http_error_new(HTTP_ERR_TIMEOUT, "connection timed out")
    check_int(e0, 0, "new timeout: idx == 0")
    check_int(http_error_type(e0), HTTP_ERR_TIMEOUT, "new timeout: type == TIMEOUT")
    check_str(http_error_message(e0), "connection timed out", "new timeout: message")
    check_int(http_error_code(e0), 0, "new timeout: code == 0")

    let e1 = http_error_new(HTTP_ERR_CONNECTION_REFUSED, "port closed")
    check_int(e1, 1, "new conn_refused: idx == 1")
    check_int(http_error_type(e1), HTTP_ERR_CONNECTION_REFUSED, "new conn_refused: type")

    let e2 = http_error_new(HTTP_ERR_DNS_FAILURE, "host not found")
    check_int(http_error_type(e2), HTTP_ERR_DNS_FAILURE, "new dns: type")

    let e3 = http_error_new(HTTP_ERR_INVALID_URL, "bad scheme")
    check_int(http_error_type(e3), HTTP_ERR_INVALID_URL, "new invalid_url: type")

    let e4 = http_error_new(HTTP_ERR_TLS, "cert expired")
    check_int(http_error_type(e4), HTTP_ERR_TLS, "new tls: type")

    let e5 = http_error_new(HTTP_ERR_PARSE, "malformed json")
    check_int(http_error_type(e5), HTTP_ERR_PARSE, "new parse: type")
}

fn test_new_status() {
    http_error_clear()

    let e0 = http_error_new_status(404, "Not Found")
    check_int(e0, 0, "new_status 404: idx == 0")
    check_int(http_error_type(e0), HTTP_ERR_STATUS, "new_status 404: type == STATUS")
    check_str(http_error_message(e0), "Not Found", "new_status 404: message")
    check_int(http_error_code(e0), 404, "new_status 404: code == 404")

    let e1 = http_error_new_status(500, "Internal Server Error")
    check_int(e1, 1, "new_status 500: idx == 1")
    check_int(http_error_code(e1), 500, "new_status 500: code == 500")
}

fn test_display() {
    http_error_clear()

    let e0 = http_error_new(HTTP_ERR_TIMEOUT, "connection timed out")
    check_str(http_error_display(e0), "timeout: connection timed out", "display timeout")

    let e1 = http_error_new(HTTP_ERR_CONNECTION_REFUSED, "port closed")
    check_str(http_error_display(e1), "connection_refused: port closed", "display conn_refused")

    let e2 = http_error_new_status(404, "Not Found")
    check_str(http_error_display(e2), "HTTP 404: Not Found", "display status 404")

    let e3 = http_error_new_status(503, "Service Unavailable")
    check_str(http_error_display(e3), "HTTP 503: Service Unavailable", "display status 503")
}

fn test_is_timeout() {
    http_error_clear()

    let e0 = http_error_new(HTTP_ERR_TIMEOUT, "timed out")
    check_int(http_error_is_timeout(e0), 1, "is_timeout: TIMEOUT == 1")

    let e1 = http_error_new(HTTP_ERR_CONNECTION_REFUSED, "refused")
    check_int(http_error_is_timeout(e1), 0, "is_timeout: CONN_REFUSED == 0")

    let e2 = http_error_new_status(408, "Request Timeout")
    check_int(http_error_is_timeout(e2), 0, "is_timeout: STATUS == 0")
}

fn test_is_network() {
    http_error_clear()

    let e0 = http_error_new(HTTP_ERR_CONNECTION_REFUSED, "refused")
    check_int(http_error_is_network(e0), 1, "is_network: CONN_REFUSED == 1")

    let e1 = http_error_new(HTTP_ERR_DNS_FAILURE, "nxdomain")
    check_int(http_error_is_network(e1), 1, "is_network: DNS == 1")

    let e2 = http_error_new(HTTP_ERR_TLS, "handshake failed")
    check_int(http_error_is_network(e2), 1, "is_network: TLS == 1")

    let e3 = http_error_new(HTTP_ERR_TIMEOUT, "timed out")
    check_int(http_error_is_network(e3), 0, "is_network: TIMEOUT == 0")

    let e4 = http_error_new(HTTP_ERR_PARSE, "bad json")
    check_int(http_error_is_network(e4), 0, "is_network: PARSE == 0")

    let e5 = http_error_new_status(500, "error")
    check_int(http_error_is_network(e5), 0, "is_network: STATUS == 0")
}

fn test_type_name() {
    check_str(http_error_type_name(HTTP_ERR_TIMEOUT), "timeout", "type_name: TIMEOUT")
    check_str(http_error_type_name(HTTP_ERR_CONNECTION_REFUSED), "connection_refused", "type_name: CONN_REFUSED")
    check_str(http_error_type_name(HTTP_ERR_DNS_FAILURE), "dns_failure", "type_name: DNS")
    check_str(http_error_type_name(HTTP_ERR_INVALID_URL), "invalid_url", "type_name: INVALID_URL")
    check_str(http_error_type_name(HTTP_ERR_TLS), "tls", "type_name: TLS")
    check_str(http_error_type_name(HTTP_ERR_PARSE), "parse", "type_name: PARSE")
    check_str(http_error_type_name(HTTP_ERR_STATUS), "status", "type_name: STATUS")
    check_str(http_error_type_name(99), "unknown", "type_name: unknown tag")
}

fn test_clear() {
    http_error_clear()

    http_error_new(HTTP_ERR_TIMEOUT, "test")
    http_error_new(HTTP_ERR_DNS_FAILURE, "test2")
    check_int(http_err_types.len(), 2, "clear: 2 errors before clear")

    http_error_clear()
    check_int(http_err_types.len(), 0, "clear: 0 types after clear")
    check_int(http_err_messages.len(), 0, "clear: 0 messages after clear")
    check_int(http_err_codes.len(), 0, "clear: 0 codes after clear")
}

fn main() {
    test_new_basic_errors()
    test_new_status()
    test_display()
    test_is_timeout()
    test_is_network()
    test_type_name()
    test_clear()

    io.println("All http_error tests complete")
}
