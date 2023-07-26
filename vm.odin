package compiler

import "core:fmt"
import "core:os"

STACK_MAX :: 256
vm := Vm{}

Vm :: struct {
    chunk: ^Chunk,
    ip: rawptr,
    stack: [STACK_MAX]Value,
    count: int,
}

Interpret_Result :: enum {
    Interpret_Ok,
    Interpret_Compile_Error,
    Interpret_Runtime_Error,
}

init_vm :: proc() {
    reset_stack()
}

free_vm :: proc() {
    
}

interpret :: proc(source: string) -> Interpret_Result {
    chunk := Chunk{}
    init_chunk(&chunk)

    if !compile(source, &chunk) {
        free_chunk(&chunk)
        return Interpret_Result.Interpret_Compile_Error
    }

    vm.chunk = &chunk
    vm.ip = vm.chunk.data

    result := run()
    free_chunk(&chunk)
    return result
}

run :: proc() -> Interpret_Result {
    using Interpret_Result
    using Op_Code

    for {
        if DEBUG_TRACE_EXECUTION {
            fmt.printf("        ")
            for i := 0; i < vm.count; i += 1 {
                fmt.printf("[ ")
                print_value(vm.stack[i])
                fmt.printf(" ]")
            }
            fmt.printf("\n")
            disassemble_instruction(vm.chunk, ((^int)(vm.ip)^ - (^int)(vm.chunk.data)^))
        }

        switch _read_byte(); Op_Code((^int)(vm.ip)^) {
            case Op_Return: 
                print_value(_pop())
                fmt.printf("\n")
                return Interpret_Ok

            case Op_Constant:
                constant := _read_constant()
                _push(number_val(constant))

            case Op_Nil: _push(nil_val())

            case Op_True: _push(bool_val(true))

            case Op_False: _push(bool_val(false))

            case Op_Negate:
                if (!is_number(peek_vm(0))) {
                    runtime_error("Operand must be a number.")
                    return Interpret_Result.Interpret_Runtime_Error
                }
                _push(number_val(-as_number(_pop())))

            case Op_Add:
                if is_string(peek_vm(0)) && is_string(peek_vm(1)) {
                    concatenate()

                } else if is_number(peek_vm(0)) && is_number(peek_vm(1)) {
                    b := as_number(_pop())
                    a := as_number(_pop())
                    _push(number_val(a + b))
                
                } else {
                    runtime_error("Operands must be two numbers or two strings.")
                    return Interpret_Result.Interpret_Runtime_Error
                }

            case Op_Subtract:
                _binary_op(number_val, "-")

            case Op_Multiply:
                _binary_op(number_val, "*")

            case Op_Divide:
                _binary_op(number_val, "/")

            case Op_Not:
                _push(bool_val(is_falsey(_pop())))

            case Op_Equal:
                b := _pop()
                a := _pop()
                _push(bool_val(values_equal(a, b)))

            case Op_Greater:
                _binary_op(bool_val, ">")

            case Op_Less:
                _binary_op(bool_val, "<")
        }
    }
}

@private
_read_byte :: proc() {
    (^int)(vm.ip)^ += 1
}

@private
_read_constant :: proc() -> f32 {
    val := ([^]f32)(vm.chunk.constants.values)
    _read_byte()
    constant := val[(^int)(vm.ip)^]
    return constant
}

@private
_binary_op :: proc(type: proc(value: Types) -> Value, op: string) -> Maybe(Interpret_Result) {
    //for false {
        if !is_number(peek_vm(0)) || !is_number(peek_vm(1)) {
            runtime_error("Operands must be numbers.")
            return Interpret_Result.Interpret_Runtime_Error
        }
        b := as_number(_pop())
        a := as_number(_pop())
        switch op {
            case "+": _push(type(a + b))
            case "-": _push(type(a - b))
            case "*": _push(type(a * b))
            case "/": _push(type(a / b))
        }
    //}
    return nil
}

reset_stack :: proc() {
    vm.count = 0
}

_push :: proc(value: Value) {
    vm.count += 1
    vm.stack[vm.count] = value
}

_pop :: proc() -> Value {
    val := vm.stack[vm.count]
    vm.count -= 1
    return val
}

peek_vm :: proc(distance: int) -> Value {
    return vm.stack[vm.count - 1 - distance]
}

is_falsey :: proc(value: Value) -> bool {
    return is_nil(value) || (is_bool(value) && !as_bool(value))
}

runtime_error :: proc(format: string, args: ..string) {
    fmt.fprintf(os.stderr, format, args)
    instruction := ((^int)(vm.ip)^ - (^int)(vm.chunk.data)^) - 1
    line := ([^]int)(vm.chunk.lines)[instruction]
    fmt.fprintf(os.stderr, "[line %d] in script\n", line)
    reset_stack()
}

concatenate :: proc() {
    b := as_string(_pop())
    a := as_string(_pop())

    length := a.length + b.length
    chars := allocate(rune, length + 1)
}
