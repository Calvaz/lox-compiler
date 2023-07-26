package compiler

import "core:mem"

copy_string :: proc(chars: rawptr, length: int) -> ^Obj_String {
    heap_chars := allocate([]rune, length + 1)
    mem.copy(&heap_chars, chars, length)
    heap_chars[length] = ' '
    return allocate_string(&heap_chars, length)
}

allocate_string :: proc(chars: rawptr, length: int) -> ^Obj_String {
    s := (^Obj_String)(allocate_obj(size_of(Obj_String), Obj_Type.String))
    s.length = length
    s.chars = chars
    return s
}

allocate_obj :: proc(size: int, type: Obj_Type) -> ^Obj {
    data, _ := reallocate(nil, 0, size)
    object := (^Obj)(&data)
    object.type = type
    return object
}

print_object :: proc(obj: Value) {
    switch obj_type(obj) {
        case Obj_Type.String: fmt.printf("%s", as_cstring(obj))
    }
}
