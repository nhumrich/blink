fn main() {
    // async.scope { body } — parsed as AsyncScope
    let result = async.scope {
        let x = 1
        x + 1
    }

    // async.spawn(closure) — parsed as MethodCall (async.spawn)
    let handle = async.spawn(fn() {
        42
    })

    // handle.await — parsed as AwaitExpr
    let value = handle.await

    // channel.new[T](buffer_size) — parsed as ChannelNew
    let ch = channel.new[Int](10)

    io.println("async parse test passed")
}
