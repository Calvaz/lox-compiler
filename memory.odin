package compiler

import "core:runtime"
import "core:os"
import "core:fmt"

grow_capacity :: proc(cap: int) -> int {
    cap := 8 if cap < 8 else cap * 2
    return cap
}

grow_array :: proc($T: typeid, pointer: rawptr, old_count: int, new_count: int) -> (data: []T, err: runtime.Allocator_Error) {
    data = transmute([]T)reallocate(pointer, size_of(T) * old_count, size_of(T) * new_count) or_return
    return
}

free_array :: proc($T: typeid, pointer: rawptr, old_count: int) -> (data: []T, err: runtime.Allocator_Error) {
    data = transmute([]T)reallocate(pointer, size_of(T) * old_count, 0) or_return
    return
}

reallocate :: proc(pointer: rawptr, old_size, new_size: int) -> (data: []u8, err: runtime.Allocator_Error) {
    if new_size == 0 {
        free(pointer)
        return nil, nil
    }

    if new_size == old_size {
        return (^[]u8)(pointer)^, nil
    }

    new_memory := runtime.mem_resize(pointer, old_size, new_size) or_return
    if new_memory == nil {
        os.exit(1)
    }
    return new_memory, nil
}

allocate :: proc($T: typeid, count: int) -> T {
    data, _ := reallocate(nil, 0, size_of(T) * count)
    return (^T)(&data)^
}
