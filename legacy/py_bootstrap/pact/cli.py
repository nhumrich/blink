import sys

import pact.lexer as lexer
import pact.parser as parser
import pact.interpreter as interpreter
import pact.compiler as compiler

USAGE = "Usage: pact <run|compile> <file.pact> [options...]"


def main():
    args = sys.argv[1:]

    if len(args) < 2:
        print(USAGE, file=sys.stderr)
        sys.exit(1)

    command = args[0]

    if command == "run":
        filepath = args[1]
        script_args = args[1:]

        try:
            with open(filepath) as f:
                source = f.read()
        except FileNotFoundError:
            print(f"Error: file not found: {filepath}", file=sys.stderr)
            sys.exit(1)

        tokens = lexer.lex(source)
        program = parser.parse(tokens)
        interp = interpreter.Interpreter(script_args)
        interp.run(program)

    elif command == "compile":
        emit_c = False
        output = None
        rest = args[1:]
        filepath = None

        i = 0
        while i < len(rest):
            if rest[i] == "--emit-c":
                emit_c = True
            elif rest[i] == "-o" and i + 1 < len(rest):
                i += 1
                output = rest[i]
            else:
                filepath = rest[i]
            i += 1

        if filepath is None:
            print("Usage: pact compile [--emit-c] [-o output] <file.pact>", file=sys.stderr)
            sys.exit(1)

        compiler.compile_file(filepath, emit_c=emit_c, output=output)

    else:
        print(USAGE, file=sys.stderr)
        sys.exit(1)
