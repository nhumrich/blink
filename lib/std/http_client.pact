import std.http_types
import std.http_error

/// Make a GET request
pub fn get(url: Str) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    let req = request_new("GET", url)
    net.request(req)
}

/// Make a POST request with body
pub fn post(url: Str, body: Str) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    let req = request_new("POST", url)
    let req2 = request_with_body(req, body)
    net.request(req2)
}

/// Make a PUT request with body
pub fn put(url: Str, body: Str) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    let req = request_new("PUT", url)
    let req2 = request_with_body(req, body)
    net.request(req2)
}

/// Make a DELETE request
pub fn delete(url: Str) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    let req = request_new("DELETE", url)
    net.request(req)
}

/// Make a HEAD request
pub fn head(url: Str) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    let req = request_new("HEAD", url)
    net.request(req)
}

/// Make an HTTP request from a Request struct
pub fn request(req: Request) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    net.request(req)
}
