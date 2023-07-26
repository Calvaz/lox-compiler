package compiler

import "core:fmt"
import "core:os"
import "core:strconv"

Parser :: struct {
    current: Token,
    previous: Token,
    had_error: bool,
    panic_mode: bool,
}

Precedence :: enum u8 {
    None,
    Assignment,
    Or,
    And,
    Equality,
    Comparison,
    Term,
    Factor,
    Unary,
    Call,
    Primary,
}

Parse_Rule :: struct {
    prefix: proc(),
    infix: proc(),
    precedence: Precedence,
}

parser := Parser{}
compiling_chunk: ^Chunk

compile :: proc(source: string, chunk: ^Chunk) -> bool {
    init_scanner(source)
    compiling_chunk = chunk

    parser.had_error = false
    parser.panic_mode = false

    advance_compiler()
    expression()
    consume(Token_Type.Eof, "Expect end of expression.")
    end_compiler()
    return !parser.had_error
}

advance_compiler :: proc() {
    parser.previous = parser.current
    
    for {
        parser.current = scan_token()
        if parser.current.type != Token_Type.Error do break

        error_at_current(parser.current.start)
    }
}

error_at_current :: proc(message: string) {
    error_at(&parser.current, message)
}

error :: proc(message: string) {
    error_at(&parser.previous, message)
}

error_at :: proc(token: ^Token, message: string) {
    if parser.panic_mode do return 

    parser.panic_mode = true
    fmt.fprintf(os.stderr, "[line %d] Error", token.line)

    if token.type == Token_Type.Eof {
        fmt.fprintf(os.stderr, " at end")

    } else if token.type == Token_Type.Error {
        //

    } else {
        fmt.fprintf(os.stderr, " at '%.*s'", token.length, token.start)
    }

    fmt.fprintf(os.stderr, ": %s\n", message)
    parser.had_error = true
}

consume :: proc(type: Token_Type, message: string) {
    if parser.current.type == type {
        advance_compiler()
    } else {
        error_at_current(message)
    }
}

emit_byte :: proc(code: Op_Code) {
    write_chunk(current_chunk(), code, parser.previous.line)
}

emit_bytes :: proc(code1: Op_Code, code2: Op_Code) {
    emit_byte(code1)
    emit_byte(code2)
}

current_chunk :: proc() -> ^Chunk {
    return compiling_chunk
}

end_compiler :: proc() {
    emit_return()
    if DEBUG_PRINT_CODE {
        if !parser.had_error {
            disassemble_chunk(current_chunk(), "code")
        }
    }
}

emit_return :: proc() {
    emit_byte(Op_Code.Op_Return)
}

emit_constant :: proc(value: Value) {
    emit_bytes(Op_Code.Op_Constant, Op_Code(make_constant(value)))
}

expression :: proc() {
    parse_precedence(Precedence.Assignment)
}

number :: proc() {
    value, ok := strconv.parse_f32(parser.previous.start)
    //if !ok do error("Value is not a decimal.")
    emit_constant(number_val(value))
}

make_constant :: proc(value: Value) -> u8 {
    constant := add_constant(current_chunk(), value)
    if constant > 255 {
        error("Too many constants in one chunk.")
        return 0
    }

    return u8(constant)
}

rules: [Token_Type]Parse_Rule = #partial {
     Token_Type.Left_Paren      = Parse_Rule{grouping, nil, Precedence.None},
     Token_Type.Right_Paren     = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Left_Brace      = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Right_Brace     = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Comma           = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Dot             = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Minus           = Parse_Rule{unary, binary, Precedence.Term},
     Token_Type.Plus            = Parse_Rule{nil, binary, Precedence.Term},
     Token_Type.Semicolon       = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Slash           = Parse_Rule{nil, binary, Precedence.Factor},
     Token_Type.Star            = Parse_Rule{nil, binary, Precedence.Factor},
     Token_Type.Bang            = Parse_Rule{unary, nil, Precedence.None},
     Token_Type.Bang_Equal      = Parse_Rule{nil, binary, Precedence.Equality},
     Token_Type.Equal           = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Equal_Equal     = Parse_Rule{nil, binary, Precedence.Equality},
     Token_Type.Greater         = Parse_Rule{nil, binary, Precedence.Comparison},
     Token_Type.Greater_Equal   = Parse_Rule{nil, binary, Precedence.Comparison},
     Token_Type.Less            = Parse_Rule{nil, binary, Precedence.Comparison},
     Token_Type.Less_Equal      = Parse_Rule{nil, binary, Precedence.Comparison},
     Token_Type.Identifier      = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.String          = Parse_Rule{str, nil, Precedence.None},
     Token_Type.Number          = Parse_Rule{number, nil, Precedence.None},
     Token_Type.And             = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Class           = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Else            = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.False           = Parse_Rule{literal, nil, Precedence.None},
     Token_Type.For             = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Fn              = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.If              = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Nil             = Parse_Rule{literal, nil, Precedence.None},
     Token_Type.Or              = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Print           = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Return          = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Super           = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.This            = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.True            = Parse_Rule{literal, nil, Precedence.None},
     Token_Type.Var             = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.While           = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Error           = Parse_Rule{nil, nil, Precedence.None},
     Token_Type.Eof             = Parse_Rule{nil, nil, Precedence.None},
}

grouping    :: proc() {
    expression()
    consume(Token_Type.Right_Paren, "Expect ')' after expression.")
}

unary :: proc() {
    operator_type := parser.previous.type

    parse_precedence(Precedence.Unary)

    using Token_Type
    #partial switch operator_type {
    case Bang: emit_byte(Op_Code.Op_Not)
    case Minus: emit_byte(Op_Code.Op_Negate)
    case: return
    }
}

binary :: proc() {
    operator_type := parser.previous.type
    rule := get_rule(operator_type)
    parse_precedence(Precedence(u8(rule.precedence) + 1))

    using Token_Type
    #partial switch operator_type {
    case Bang_Equal: emit_bytes(Op_Code.Op_Equal, Op_Code.Op_Not)
    case Equal_Equal: emit_byte(Op_Code.Op_Equal)
    case Greater: emit_byte(Op_Code.Op_Greater)
    case Greater_Equal: emit_bytes(Op_Code.Op_Less, Op_Code.Op_Not)
    case Less: emit_byte(Op_Code.Op_Less)
    case Less_Equal: emit_bytes(Op_Code.Op_Equal, Op_Code.Op_Not)
    case Plus: emit_byte(Op_Code.Op_Add)
    case Minus: emit_byte(Op_Code.Op_Subtract)
    case Star: emit_byte(Op_Code.Op_Multiply)
    case Slash: emit_byte(Op_Code.Op_Divide)
    case: return
    }
}

literal :: proc() {
    #partial switch parser.previous.type {
        case Token_Type.False: emit_byte(Op_Code.Op_False)
        case Token_Type.Nil: emit_byte(Op_Code.Op_Nil)
        case Token_Type.True: emit_byte(Op_Code.Op_True)
        case: return
    }
}

str :: proc() {
    emit_constant(obj_val(copy_string(parser.previous.start + 1, parser.previous.length - 2)))
}

parse_precedence :: proc(precedence: Precedence) {
    advance_compiler()
    prefix_rule := get_rule(parser.previous.type).prefix
    if prefix_rule == nil {
        error("Expect expression.")
        return
    }

    prefix_rule()

    for precedence <= get_rule(parser.current.type).precedence {
        advance_compiler()
        infix_rule := get_rule(parser.previous.type).infix
        infix_rule()
    }
}

get_rule :: proc(type: Token_Type) -> ^Parse_Rule {
    return &rules[type]
}

