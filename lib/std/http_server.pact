// http_server.pact — HTTP server with routing and path parameters
//
// Parallel-array storage for servers, routes, and path params.
// Actual networking delegated to net.listen/net.serve effects.

import std.http_types
import std.http_error

// ── Server storage ─────────────────────────────────────────────────
pub let mut server_hosts: List[Str] = []
pub let mut server_ports: List[Int] = []

// ── Route storage (parallel arrays) ───────────────────────────────
pub let mut route_methods: List[Str] = []
pub let mut route_patterns: List[Str] = []
pub let mut route_handlers: List[Int] = []
pub let mut route_server_owners: List[Int] = []

// ── Path param storage (per-request, reset each match) ────────────
pub let mut param_names: List[Str] = []
pub let mut param_values: List[Str] = []

// ── Server API ─────────────────────────────────────────────────────

pub fn server_new(host: Str, port: Int) -> Int {
    let idx = server_hosts.len()
    server_hosts.push(host)
    server_ports.push(port)
    idx
}

pub fn server_host(idx: Int) -> Str {
    server_hosts.get(idx)
}

pub fn server_port(idx: Int) -> Int {
    server_ports.get(idx)
}

pub fn server_route(srv: Int, method: Str, pattern: Str, handler_fn: Int) {
    route_methods.push(method)
    route_patterns.push(pattern)
    route_handlers.push(handler_fn)
    route_server_owners.push(srv)
}

pub fn server_serve(srv: Int) ! Net.Listen, IO {
    let host = server_hosts.get(srv)
    let port = server_ports.get(srv)
    net.serve(host, port, srv)
}

// ── Route matching ─────────────────────────────────────────────────

pub fn match_route(srv: Int, method: Str, path: Str) -> Int {
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

pub fn path_match(pattern: Str, path: Str) -> Int {
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
            // ':' = 58 — path parameter
            let pname = pat_seg.slice(1, pat_seg.len())
            param_names.push(pname)
            param_values.push(path_seg)
        } else if pat_seg != path_seg {
            return 0
        }
        i = i + 1
    }
    1
}

pub fn path_param(name: Str) -> Str {
    let mut i = 0
    while i < param_names.len() {
        if param_names.get(i) == name {
            return param_values.get(i)
        }
        i = i + 1
    }
    ""
}

pub fn path_param_clear() {
    param_names = []
    param_values = []
}

// ── Helpers ────────────────────────────────────────────────────────

pub fn route_handler(idx: Int) -> Int {
    route_handlers.get(idx)
}

pub fn route_count(srv: Int) -> Int {
    let mut count = 0
    let mut i = 0
    while i < route_server_owners.len() {
        if route_server_owners.get(i) == srv {
            count = count + 1
        }
        i = i + 1
    }
    count
}

fn split_path(path: Str) -> List[Str] {
    let mut parts: List[Str] = []
    let mut current = ""
    let mut i = 0
    while i < path.len() {
        if path.char_at(i) == 47 {
            // '/' = 47
            if current.len() > 0 {
                parts.push(current)
                current = ""
            }
        } else {
            current = current.concat(path.slice(i, i + 1))
        }
        i = i + 1
    }
    if current.len() > 0 {
        parts.push(current)
    }
    parts
}

pub fn server_clear() {
    server_hosts = []
    server_ports = []
    route_methods = []
    route_patterns = []
    route_handlers = []
    route_server_owners = []
    param_names = []
    param_values = []
}
