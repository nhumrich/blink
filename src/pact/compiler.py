import sys
import os
import tempfile
import subprocess
import shutil

import pact.lexer as lexer
import pact.parser as parser
import pact.codegen as codegen


def resolve_imports(program, base_dir, seen=None):
    if seen is None:
        seen = set()

    for imp in program.imports:
        rel_path = imp.path.replace('.', '/') + '.pact'
        abs_path = os.path.normpath(os.path.join(base_dir, rel_path))

        if abs_path in seen:
            continue
        seen.add(abs_path)

        try:
            with open(abs_path) as f:
                source = f.read()
        except FileNotFoundError:
            print(f"Warning: import not found: {imp.path} ({abs_path})", file=sys.stderr)
            continue

        tokens = lexer.lex(source)
        imported = parser.parse(tokens)

        resolve_imports(imported, os.path.dirname(abs_path), seen)

        if imp.names:
            for fn in imported.functions:
                if fn.name in imp.names:
                    program.functions.insert(0, fn)
            for td in imported.types:
                if td.name in imp.names:
                    program.types.insert(0, td)
            for lb in imported.top_lets:
                if lb.name in imp.names:
                    program.top_lets.insert(0, lb)
        else:
            existing_fn_names = {fn.name for fn in program.functions}
            for fn in imported.functions:
                if fn.name != 'main' and fn.name not in existing_fn_names:
                    program.functions.insert(0, fn)
            existing_type_names = {td.name for td in program.types}
            for td in imported.types:
                if td.name not in existing_type_names:
                    program.types.insert(0, td)
            existing_let_names = {lb.name for lb in program.top_lets}
            for lb in imported.top_lets:
                if lb.name not in existing_let_names:
                    program.top_lets.insert(0, lb)


def compile_file(filepath, emit_c=False, output=None):
    try:
        with open(filepath) as f:
            source = f.read()
    except FileNotFoundError:
        print(f"Error: file not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    tokens = lexer.lex(source)
    program = parser.parse(tokens)

    base_dir = os.path.dirname(os.path.abspath(filepath))
    resolve_imports(program, base_dir)

    gen = codegen.CCodeGen()
    c_code = gen.generate(program)

    if emit_c:
        print(c_code)
        return

    if output is None:
        output = os.path.splitext(os.path.basename(filepath))[0]

    with tempfile.NamedTemporaryFile(suffix='.c', mode='w', delete=False) as tmp:
        tmp.write(c_code)
        tmp_path = tmp.name

    try:
        result = subprocess.run(
            ['cc', '-o', output, tmp_path, '-lm'],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"C compiler error:\n{result.stderr}", file=sys.stderr)
            sys.exit(1)
        runtime_src = os.path.join(os.path.dirname(__file__), 'runtime.h')
        runtime_dst = os.path.join(os.path.dirname(os.path.abspath(output)), 'runtime.h')
        if os.path.abspath(runtime_src) != os.path.abspath(runtime_dst):
            shutil.copy2(runtime_src, runtime_dst)
    finally:
        os.unlink(tmp_path)
