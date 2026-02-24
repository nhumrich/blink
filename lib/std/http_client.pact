import std.http_types
import std.http_error

pub fn get(url: Str) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    let req = request_new("GET", url)
    net.request(req)
}

pub fn post(url: Str, body: Str) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    let req = request_new("POST", url)
    let req2 = request_with_body(req, body)
    net.request(req2)
}

pub fn put(url: Str, body: Str) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    let req = request_new("PUT", url)
    let req2 = request_with_body(req, body)
    net.request(req2)
}

pub fn delete(url: Str) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    let req = request_new("DELETE", url)
    net.request(req)
}

pub fn head(url: Str) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    let req = request_new("HEAD", url)
    net.request(req)
}

pub fn request(req: Request) -> Result[Response, NetError] ! Net.Connect, Net.DNS {
    net.request(req)
}
