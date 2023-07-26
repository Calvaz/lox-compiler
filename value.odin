package compiler

import "core:runtime"
import "core:fmt"
import "core:mem"

Value_Array :: struct {
    capacity: int,
    count: int,
    values: rawptr,
}

Value_Type :: enum {
    Bool,
    Nil,
    Number,
    Obj,
}

Value :: struct {
    type: Value_Type,
    as: Types,
}

Types :: union {
    bool,
    f32,
    ^Obj,
}

Obj :: struct {
    type: Obj_Type,
}

Obj_Type :: enum {
    String,
}

Obj_String :: struct {
    obj: Obj,
    length: int,
    chars: rawptr,
}

init_value_array :: proc(array: ^Value_Array) {
    array.values = nil
    array.capacity = 0
    array.count = 0
}

write_value_array :: proc(array: ^Value_Array, value: f32) -> (err: runtime.Allocator_Error) {
    if array.capacity < array.count + 1 {
        old_capacity := array.capacity
        array.capacity = grow_capacity(old_capacity)
        data := grow_array(f64, array.values, old_capacity, array.capacity) or_return
        array.values = raw_data(data)
    }

    data := ([^]f32)(array.values)
    data[array.count] = value
    fmt.println(data[array.count])
    array.count += 1
    return
}

free_value_array :: proc(array: ^Value_Array) {
    free_array(f32, array.values, array.capacity)
    init_value_array(array)
}

print_value :: proc(value: Value) {
    switch value.type {
        case Value_Type.Bool: 
            fmt.printf(as_bool(value) ? "true" : "false") 

        case Value_Type.Nil: fmt.printf("nil")
        case Value_Type.Number: fmt.printf("%g", as_number(value))
        case Value_Type.Obj: print_object(value)
    }
}

bool_val :: proc(value: bool) -> Value {
    return Value{ type = Value_Type.Bool, as = value }
}

nil_val :: proc() -> Value {
    return Value{ type = Value_Type.Nil, as = 0 }
}

number_val :: proc(value: f32) -> Value {
    return Value{ type = Value_Type.Number, as = value }
}

obj_val :: proc(object: Obj) -> Value {
    return Value{ type = Value_Type.Number, as = &object }
}

as_bool :: proc(value: Value) -> bool {
    return value.as.(bool)
}

as_number :: proc(value: Value) -> f32 {
    return value.as.(f32)
}

as_obj :: proc(value: Value) -> ^Obj {
    return value.as.(^Obj)
}

is_bool :: proc(value: Value) -> bool {
    return value.type == Value_Type.Bool
}

is_nil :: proc(value: Value) -> bool {
    return value.type == Value_Type.Nil
}

is_number :: proc(value: Value) -> bool {
    return value.type == Value_Type.Number
}

is_obj :: proc(value: Value) -> bool {
    return value.type == Value_Type.Obj
}

values_equal :: proc(a: Value, b: Value) -> bool {
    if a.type != b.type do return false

    using Value_Type
    switch a.type {
        case Bool: return as_number(a) == as_number(b)
        case Number: return as_bool(a) == as_bool(b)
        case Nil: return true
        case Obj: 
            a_string := as_string(a)
            b_string := as_string(b)
            return a_string.length == b_string.length && a_string.chars == b_string.chars

        case: return false
    }
}

obj_type :: proc(value: Value) -> Obj_Type {
    return as_obj(value).type
}

is_string :: proc(value: Value) -> bool {
    return is_obj_type(value, Obj_Type.String)
}

is_obj_type :: proc(value: Value, type: Obj_Type) -> bool {
    return is_obj(value) && as_obj(value).type == type
}

as_string :: proc(value: Value) -> ^Obj_String {
    return (^Obj_String)(as_obj(value))
}

as_cstring :: proc(value: Value) -> rawptr {
    return (^Obj_String)(as_obj(value)).chars
}

