package compiler

import "core:fmt"

DEBUG_PRINT_CODE :: true
DEBUG_TRACE_EXECUTION :: true

disassemble_instruction :: proc(chunk: ^Chunk, offset: int) -> int {
    fmt.printf("%04d ", offset)
    lines := ([^]int)(chunk.lines)
    if offset > 0 && lines[offset] == lines[offset - 1] {
        fmt.printf("   | ")
    
    } else {
        fmt.printf("%4d ", lines[offset])
    }

    data := ([^]u8)(chunk.data)
    instruction := data[offset]
    using Op_Code

    switch Op_Code(instruction) {
    case Op_Return:
        return simple_instruction("OP_RETURN", offset)

    case Op_Constant:
        return constant_instruction("OP_CONSTANT", chunk, offset)

    case Op_Negate:
        return simple_instruction("OP_NEGATE", offset)

    case Op_Add:
        return simple_instruction("OP_ADD", offset)

    case Op_Subtract:
        return simple_instruction("OP_SUBTRACT", offset)

    case Op_Multiply:
        return simple_instruction("OP_MULTIPLY", offset)

    case Op_Divide:
        return simple_instruction("OP_DIVIDE", offset)

    case Op_Nil:
        return simple_instruction("OP_NIL", offset)

    case Op_True:
        return simple_instruction("OP_TRUE", offset)

    case Op_False:
        return simple_instruction("OP_FALSE", offset)

    case Op_Not:
        return simple_instruction("OP_NOT", offset)

    case Op_Equal:
        return simple_instruction("OP_EQUAL", offset)

    case Op_Greater:
        return simple_instruction("OP_GREATER", offset)

    case Op_Less:
        return simple_instruction("OP_LESS", offset)

    case: 
        fmt.printf("Unknown opcode %d\n", instruction)
        return offset + 1
    }
}

simple_instruction :: proc(name: string, offset: int) -> int {
    fmt.printf("%s \n", name)
    return offset + 1
}

constant_instruction :: proc(name: string, chunk: ^Chunk, offset: int) -> int {
    data := ([^]u8)(chunk.data)
    constant := data[offset + 1]
    fmt.printf("%-16s %4d '", name, constant)
    constant_values := ([^]Value)(chunk.constants.values)
    print_value(constant_values[constant])
    fmt.printf("'\n")
    return offset + 2
}
