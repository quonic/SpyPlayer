package main

import c "core:c/libc"
import "core:fmt"
import "core:os"
import "core:strings"

foreign import libc "system:c"

@(default_calling_convention = "c")
foreign libc {
	popen :: proc(command, type: cstring) -> ^c.FILE ---
	pclose :: proc(f: ^c.FILE) -> c.int ---
}

execute_binary :: proc(fullpath: string) -> (output: string) {
	location_buf: [1024]byte
	file := popen(cstr(fullpath), "r")
	defer pclose(file)

	c.fgets(raw_data(location_buf[:]), len(location_buf), file)
	output = string(location_buf[:])
	output, _ = strings.replace_all(output, "\n", "", context.temp_allocator)
	return strings.clone(output)
}

cstr :: proc(s: string, allocator := context.temp_allocator) -> cstring {
	return strings.clone_to_cstring(s, allocator)
}
