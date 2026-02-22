#!/bin/bash
set -e
cd /home/nhumrich/personal/pact
mkdir -p build
cp bootstrap/runtime.h build/runtime.h
mkdir -p build/lib/std
cp lib/std/*.pact build/lib/std/

echo "Compiling bootstrap compiler..."
cc -o build/pactc bootstrap/pactc_bootstrap.c -lm

echo "Self-compiling pactc (gen1)..."
build/pactc src/compiler.pact build/pactc_self.c
cc -o build/pactc_self build/pactc_self.c -lm

echo "Verifying (gen2)..."
build/pactc_self src/compiler.pact build/pactc_verify.c

if diff -q build/pactc_self.c build/pactc_verify.c > /dev/null 2>&1; then
    echo "Bootstrap verified -- self-compilation is stable."
    cp build/pactc_self build/pactc
    rm -f build/pactc_self build/pactc_self.c build/pactc_verify.c
    echo "Done. Compiler at: build/pactc"
else
    echo "ERROR: gen1 and gen2 differ!"
    diff build/pactc_self.c build/pactc_verify.c | head -30
    exit 1
fi
