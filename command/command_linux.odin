package command

import "core:bytes"
import "core:fmt"
import "core:mem"
import "core:strings"

when ODIN_OS == .Linux || ODIN_OS == .Darwin {
	foreign libc 
	{
		popen :: proc(command: cstring, type: cstring) -> ^FILE ---
		pclose :: proc(stream: ^FILE) -> i32 ---
		fgets :: proc "cdecl" (s: [^]byte, n: i32, stream: ^FILE) -> [^]u8 ---
		fgetc :: proc "cdecl" (stream: ^FILE) -> i32 ---
	}

	foreign import libc "system:c"
	FILE :: struct {}


	/* 
Run a command and return stdout

Example Usage:
```
	root_buf: [1024]byte
	data := root_buf[:]
	code, ok, out := run_executable("ls -lah", &data)
	fmt.println(string(out))
```
*/
	run_executable :: proc(command: string, stdout: ^[]byte) -> (u32, bool, []byte) {
		exit_code: u32 = 0

		fp := popen(strings.clone_to_cstring(command, context.temp_allocator), "r")
		if fp == nil {
			return 0, false, stdout[0:]
		}
		defer pclose(fp)

		read_buffer: [8]byte
		index: int

		for fgets(&read_buffer[0], size_of(read_buffer), fp) != nil {
			read := bytes.index_byte(read_buffer[:], 0)
			defer index += cast(int)read

			if read > 0 && index + cast(int)read <= len(stdout) {
				mem.copy(&stdout[index], &read_buffer[0], cast(int)read)
			}
		}

		return exit_code, true, stdout[0:index]
	}
}
