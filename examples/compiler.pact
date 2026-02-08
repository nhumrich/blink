// compiler.pact — Self-hosting Pact compiler driver
//
// Ties together lexer, parser, and codegen into a complete compiler.
// Reads a .pact source file, lexes, parses, generates C, and writes output.
//
// Usage (once compiled): ./pactc <source.pact> [output.c]
// If no output file given, writes to stdout.

import lexer
import parser
import codegen

fn main() {
    if arg_count() < 2 {
        io.println("Usage: pactc <source.pact> [output.c]")
        io.println("  Compiles a Pact source file to C.")
        return
    }

    let source_path = get_arg(1)
    let source = read_file(source_path)

    lex(source)
    let program_node = parse_program()
    let c_output = generate(program_node)

    if arg_count() >= 3 {
        let out_path = get_arg(2)
        write_file(out_path, c_output)
    } else {
        io.println(c_output)
    }
}
