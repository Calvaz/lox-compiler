package compiler

import "core:fmt"
import "core:os"

main :: proc() {
    init_vm()

    args := os.args
    fmt.println(args)

    if len(args) == 1 {
        repl()

    } else if len(args) == 2 {
        run_file(args[1])
    
    } else {
        fmt.fprintf(os.stderr, "Usage: [path] \n")
        os.exit(64)
    }
    free_vm()
}

repl :: proc() {
    
    buffer: [256]u8     
    for {
        fmt.printf("> ")

        for {     
            bytes_r, err := os.read(os.stdin, buffer[:]);     
            if err < 0 {         
                fmt.println(fmt.tprintf("Error while reading the file: %v", err))     
            }
            interpret(string(buffer[:bytes_r]))
        }

    }
}

run_file :: proc(path: string) {     
    file: []byte     
    if file, success := os.read_entire_file_from_filename(path); !success {         
        fmt.printf("Could not read file %v")
        os.exit(74)
    }
    result := interpret(transmute(string)file)
    delete(file)

    if result == Interpret_Result.Interpret_Compile_Error {         
        os.exit(65)     
    }

    if result == Interpret_Result.Interpret_Runtime_Error {         
        os.exit(70)     
    }
}

