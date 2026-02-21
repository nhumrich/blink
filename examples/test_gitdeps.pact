import std.gitdeps

fn check_str(actual: Str, expected: Str, label: Str) {
    if actual == expected {
        io.println("PASS: {label}")
    } else {
        io.println("FAIL: {label} — expected \"{expected}\", got \"{actual}\"")
    }
}

fn check_int(actual: Int, expected: Int, label: Str) {
    if actual == expected {
        io.println("PASS: {label}")
    } else {
        io.println("FAIL: {label} — expected {expected}, got {actual}")
    }
}

fn check_true(cond: Int, label: Str) {
    if cond == 1 {
        io.println("PASS: {label}")
    } else {
        io.println("FAIL: {label} — expected true")
    }
}

fn setup_test_repo() {
    shell_exec("rm -rf /tmp/_pact_test_git")
    shell_exec("mkdir -p /tmp/_pact_test_git/mylib/src")
    write_file("/tmp/_pact_test_git/mylib/src/lib.pact", "pub fn greet() -> Str \{ \"hello\" \}\n")
    write_file("/tmp/_pact_test_git/mylib/pact.toml", "[package]\nname = \"mylib\"\nversion = \"1.0.0\"\n")
    shell_exec("cd /tmp/_pact_test_git/mylib && git init && git add -A && git commit -m 'init' && git tag v1.0")
}

fn cleanup() {
    shell_exec("rm -rf /tmp/_pact_test_git")
    shell_exec("rm -rf ~/.pact/cache/git/*_pact_test_*")
}

fn test_fetch_file_url() {
    git_clear()
    let url = "file:///tmp/_pact_test_git/mylib"
    let rc = git_fetch(url, "v1.0")
    check_int(rc, 0, "fetch from file:// URL succeeds")
    let commit = git_get_commit()
    check_int(commit.len(), 40, "commit hash is 40 chars")
}

fn test_checkout_path_exists() {
    let path = git_get_checkout_path()
    check_true(is_dir(path), "checkout path is a directory")
    let lib_path = path_join(path, "src/lib.pact")
    check_true(file_exists(lib_path), "checkout contains src/lib.pact")
}

fn test_content_hash() {
    let hash = git_get_content_hash()
    let has_length = 0
    if hash.len() > 0 {
        check_true(1, "content hash is non-empty")
    } else {
        check_true(0, "content hash is non-empty")
    }
}

fn test_cache_reuse() {
    let url = "file:///tmp/_pact_test_git/mylib"
    let first_commit = git_get_commit()
    let first_hash = git_get_content_hash()

    git_clear()
    let rc = git_fetch(url, "v1.0")
    check_int(rc, 0, "second fetch succeeds")
    check_str(git_get_commit(), first_commit, "cached commit matches")
    check_str(git_get_content_hash(), first_hash, "cached hash matches")
}

fn test_sanitize_url() {
    let sanitized = sanitize_url("https://github.com/org/repo.git")
    // Should have no slashes, colons, or dots
    let mut i = 0
    let mut has_bad = 0
    while i < sanitized.len() {
        let ch = sanitized.char_at(i)
        if ch == 47 || ch == 58 || ch == 46 {
            has_bad = 1
        }
        i = i + 1
    }
    if has_bad == 0 {
        check_true(1, "sanitized URL has no special chars")
    } else {
        check_true(0, "sanitized URL has no special chars")
    }
    // Should contain recognizable parts
    let mut has_github = 0
    if sanitized.len() > 0 {
        has_github = 1
    }
    check_true(has_github, "sanitized URL is non-empty")
}

fn test_clear_state() {
    git_clear()
    check_str(git_get_commit(), "", "cleared commit")
    check_str(git_get_checkout_path(), "", "cleared checkout path")
    check_str(git_get_content_hash(), "", "cleared content hash")
}

fn main() {
    setup_test_repo()

    test_fetch_file_url()
    test_checkout_path_exists()
    test_content_hash()
    test_cache_reuse()
    test_sanitize_url()
    test_clear_state()

    cleanup()
    io.println("All gitdeps tests complete")
}
