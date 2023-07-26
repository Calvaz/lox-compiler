package compiler

import "core:runtime"
import "core:fmt"

Op_Code :: enum u8 {
    Op_Return,
    Op_Negate,
    Op_Constant,
    Op_Nil,
    Op_True,
    Op_False,
    Op_Add,
    Op_Subtract,
    Op_Multiply,
    Op_Divide,
    Op_Not,
    Op_Equal,
    Op_Greater,
    Op_Less,
}

Chunk :: struct {
    count: int,
    capacity: int,
    data: rawptr,
    lines: rawptr,
    constants: Value_Array,
}

init_chunk :: proc(chunk: ^Chunk) -> ^Chunk{
    chunk.count = 0
    chunk.capacity = 0
    chunk.data = nil
    chunk.lines = nil
    init_value_array(&chunk.constants)
    return chunk
}

free_chunk :: proc(chunk: ^Chunk) {
    free_array(u8, chunk.data, chunk.capacity)
    free_array(int, chunk.lines, chunk.capacity)
    free_value_array(&chunk.constants)
    init_chunk(chunk)
}

write_chunk :: proc(chunk: ^Chunk, op: Op_Code, line: int) -> (err: runtime.Allocator_Error) {
    if chunk.capacity < chunk.count + 1 {
        old_capacity := chunk.capacity
        chunk.capacity = grow_capacity(chunk.capacity)
        data := grow_array(u8, chunk.data, old_capacity, chunk.capacity) or_return
        lines := grow_array(int, chunk.lines, old_capacity, chunk.capacity) or_return
        chunk.data = raw_data(data)
        chunk.lines = raw_data(lines)
    }

    data := ([^]u8)(chunk.data)
    data[chunk.count] = u8(op)
    l := ([^]int)(chunk.lines)
    l[chunk.count] = line
    chunk.count += 1
    return
}

add_constant :: proc(chunk: ^Chunk, value: Value) -> int {
    write_value_array(&chunk.constants, value)
    return chunk.constants.count - 1
}

disassemble_chunk :: proc(chunk: ^Chunk, name: string) {
    fmt.printf("== %v ==\n", name)

    for offset := 0; offset < chunk.count; {
        offset = disassemble_instruction(chunk, offset)
    }
}


