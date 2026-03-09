#!/bin/bash
# Test FFI diagnostic errors are emitted correctly
set -euo pipefail

PACT="${1:-bin/pact}"
DIAG_TMP=".tmp"
mkdir -p "$DIAG_TMP"
trap 'rm -f "$DIAG_TMP"/diag_*.pact' EXIT
PASS=0
FAIL=0

check_diagnostic() {
    local name="$1" code="$2" file="$3"
    local output
    output=$($PACT check "$file" 2>&1 || true)
    if echo "$output" | grep -q "$code"; then
        echo "  ok: $name ($code)"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $name — expected $code"
        echo "  got: $output"
        FAIL=$((FAIL + 1))
    fi
}

echo "FFI diagnostics tests"
echo "====================="

# E0801: pub FFI
cat > "$DIAG_TMP/diag_e0801.pact" << 'EOF'
@ffi("labs")
@trusted
pub fn bad(n: Int) -> Int ! FFI { }
fn main() { }
EOF
check_diagnostic "pub FFI function" "PubFFI" "$DIAG_TMP/diag_e0801.pact"

# E0802: FFI without effects
cat > "$DIAG_TMP/diag_e0802.pact" << 'EOF'
@ffi("labs")
@trusted
fn bad(n: Int) -> Int { }
fn main() { }
EOF
check_diagnostic "FFI without effects" "FFINoEffects" "$DIAG_TMP/diag_e0802.pact"

# E0803: @requires on FFI
cat > "$DIAG_TMP/diag_e0803_req.pact" << 'EOF'
@ffi("labs")
@trusted
@requires(n > 0)
fn bad(n: Int) -> Int ! FFI { }
fn main() { }
EOF
check_diagnostic "@requires on FFI" "ContractOnFFI" "$DIAG_TMP/diag_e0803_req.pact"

# E0803: @ensures on FFI
cat > "$DIAG_TMP/diag_e0803_ens.pact" << 'EOF'
@ffi("labs")
@trusted
@ensures(result > 0)
fn bad(n: Int) -> Int ! FFI { }
fn main() { }
EOF
check_diagnostic "@ensures on FFI" "ContractOnFFI" "$DIAG_TMP/diag_e0803_ens.pact"

# E0811: Ptr outside FFI
cat > "$DIAG_TMP/diag_e0811.pact" << 'EOF'
fn bad(p: Ptr[Int]) -> Int { 0 }
fn main() { }
EOF
check_diagnostic "Ptr outside FFI" "PtrOutsideFFI" "$DIAG_TMP/diag_e0811.pact"

# W0800: unaudited FFI
cat > "$DIAG_TMP/diag_w0800.pact" << 'EOF'
@ffi("labs")
fn unaudited(n: Int) -> Int ! FFI { }
fn main() { }
EOF
check_diagnostic "FFI without @trusted" "UnauditedFFI" "$DIAG_TMP/diag_w0800.pact"

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
