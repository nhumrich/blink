import std.net_error

/// Connect to a TCP host:port. Returns the file descriptor on success.
pub fn tcp_connect(host: Str, port: Int) -> Result[Int, NetError] {
    let fd = net.connect(host, port)
    if fd == -2 {
        return Err(NetError.DnsFailure("DNS resolution failed for {host}"))
    }
    if fd == -3 {
        return Err(NetError.Timeout("connection timed out"))
    }
    if fd < 0 {
        return Err(NetError.ConnectionRefused("connection refused"))
    }
    Ok(fd)
}

/// Bind and listen on host:port. Returns the listener file descriptor on success.
pub fn tcp_listen(host: Str, port: Int) -> Result[Int, NetError] {
    let fd = net.listen(host, port)
    if fd < 0 {
        return Err(NetError.BindError("failed to listen on {host}:{port.to_string()}"))
    }
    Ok(fd)
}

/// Accept an incoming connection on a listener fd. Returns the client file descriptor.
pub fn tcp_accept(fd: Int) -> Result[Int, NetError] {
    let conn = net.accept(fd)
    if conn < 0 {
        return Err(NetError.BindError("accept failed"))
    }
    Ok(conn)
}

/// Read up to max_bytes from a socket. Returns the data read (empty string on EOF).
pub fn tcp_read(fd: Int, max_bytes: Int) -> Str {
    net.read(fd, max_bytes)
}

/// Read all available data from a socket until EOF.
pub fn tcp_read_all(fd: Int) -> Str {
    net.read_all(fd)
}

/// Write data to a socket.
pub fn tcp_write(fd: Int, data: Str) {
    net.write(fd, data)
}

/// Close a socket.
pub fn tcp_close(fd: Int) {
    net.close(fd)
}

/// Set send/receive timeout in milliseconds on a socket.
pub fn tcp_set_timeout(fd: Int, ms: Int) {
    net.set_timeout(fd, ms)
}
