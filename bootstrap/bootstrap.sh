#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"

mkdir -p "$BUILD_DIR"
# Copy split runtime headers to build/ for direct #include usage
cp "$SCRIPT_DIR"/runtime_*.h "$BUILD_DIR/"
# Build a flat runtime.h in build/ for CLI inlining (CLI reads build/runtime.h
# and embeds it verbatim in generated C, so nested #includes won't work)
cat "$SCRIPT_DIR/runtime_core.h" \
    "$SCRIPT_DIR/runtime_tcp.h" \
    "$SCRIPT_DIR/runtime_unix_socket.h" \
    "$SCRIPT_DIR/runtime_thread.h" \
    "$SCRIPT_DIR/runtime_process.h" \
    "$SCRIPT_DIR/runtime_test.h" \
    "$SCRIPT_DIR/runtime_sqlite.h" \
    "$SCRIPT_DIR/runtime_stdio.h" \
    "$SCRIPT_DIR/runtime_trace.h" \
    > "$BUILD_DIR/runtime.h"
# Build gc_unity.c — inline all ../*.c includes from gc/extra/gc.c into a
# single translation unit so the embedded version has no relative .c deps.
GC_EXTRA="$SCRIPT_DIR/vendor/gc/extra"
GC_UNITY="$BUILD_DIR/gc_unity.c"
# Inline all #include "../*.c" directives (POSIX-compatible, no gawk needed)
while IFS= read -r line; do
    inc_path=$(printf '%s\n' "$line" | sed -n 's/^#[[:space:]]*include[[:space:]]*"\(\.\.\/[^"]*\.c\)".*/\1/p')
    if [ -n "$inc_path" ]; then
        echo "/* === inlined: $inc_path === */"
        cat "$GC_EXTRA/$inc_path"
        echo "/* === end: $inc_path === */"
    else
        printf '%s\n' "$line"
    fi
done < "$GC_EXTRA/gc.c" > "$GC_UNITY"

mkdir -p "$BUILD_DIR/lib/std"
cp "$ROOT_DIR/lib/std/"*.pact "$BUILD_DIR/lib/std/" 2>/dev/null || true
cp "$ROOT_DIR/lib/std/"*.bl "$BUILD_DIR/lib/std/" 2>/dev/null || true
mkdir -p "$BUILD_DIR/lib/pkg"
cp "$ROOT_DIR/lib/pkg/"*.pact "$BUILD_DIR/lib/pkg/" 2>/dev/null || true
cp "$ROOT_DIR/lib/pkg/"*.bl "$BUILD_DIR/lib/pkg/" 2>/dev/null || true

# --- Gen 0: resolve a working pactc ---
GEN0=""
if [ -f "$BUILD_DIR/pactc" ]; then
    echo "Using existing build/pactc as Gen 0"
    GEN0="$BUILD_DIR/pactc"
elif command -v pact > /dev/null 2>&1; then
    echo "Compiling pactc from installed pact..."
    pact build "$ROOT_DIR/src/pactc_main.pact" --output "$BUILD_DIR/pactc_gen0"
    GEN0="$BUILD_DIR/pactc_gen0"
else
    echo "ERROR: No compiler found." >&2
    echo "Either build/pactc must exist, or 'pact' must be on PATH." >&2
    echo "Install pact from: https://github.com/nhumrich/pact/releases" >&2
    exit 1
fi

# --- Gen 1: compile pactc with Gen 0 ---
echo "Self-compiling pactc (Gen 1)..."
"$GEN0" "$ROOT_DIR/src/pactc_main.pact" "$BUILD_DIR/pactc_gen1.c"
cc -o "$BUILD_DIR/pactc_gen1" "$BUILD_DIR/pactc_gen1.c" -lm -lgc

# --- Gen 2: compile pactc with Gen 1 ---
echo "Verifying bootstrap chain (Gen 2)..."
"$BUILD_DIR/pactc_gen1" "$ROOT_DIR/src/pactc_main.pact" "$BUILD_DIR/pactc_gen2.c"

if diff -q "$BUILD_DIR/pactc_gen1.c" "$BUILD_DIR/pactc_gen2.c" > /dev/null 2>&1; then
    echo "Bootstrap verified — self-compilation is stable."
    rm -f "$BUILD_DIR/pactc"
    cp "$BUILD_DIR/pactc_gen1" "$BUILD_DIR/pactc"
    rm -f "$BUILD_DIR/pactc_gen0" "$BUILD_DIR/pactc_gen1" "$BUILD_DIR/pactc_gen1.c" "$BUILD_DIR/pactc_gen2.c"
else
    echo "ERROR: Bootstrap verification failed — Gen 1 and Gen 2 differ!" >&2
    exit 1
fi

echo "Done. Compiler at: $BUILD_DIR/pactc"
