package command

import "core:bytes"
import c "core:c/libc"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:os/os2"
import "core:path/filepath"
import "core:path/slashpath"
import "core:strings"
import win32 "core:sys/windows"

when ODIN_OS == .Darwin || ODIN_OS == .Linux || ODIN_OS == .NetBSD {
	foreign libc 
	{
		popen :: proc(command: cstring, type: cstring) -> ^FILE ---
		pclose :: proc(stream: ^FILE) -> i32 ---
		fgets :: proc "cdecl" (s: [^]byte, n: i32, stream: ^FILE) -> [^]u8 ---
		fgetc :: proc "cdecl" (stream: ^FILE) -> i32 ---
	}

	foreign import libc "system:c"
	FILE :: struct {}
}

when ODIN_OS == .Windows {

	FORMAT_MESSAGE_FROM_SYSTEM :: 0x00001000
	FORMAT_MESSAGE_IGNORE_INSERTS :: 0x00000200

	foreign import kernel32 "system:kernel32.lib"

	@(default_calling_convention = "std")
	foreign kernel32 {
		@(link_name = "FormatMessageA")
		format_message_a :: proc(flags: u32, source: rawptr, message_id: u32, langauge_id: u32, buffer: cstring, size: u32, va: rawptr) -> u32 ---
	}
}

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
	when ODIN_OS == .Windows {
		stdout_read: win32.HANDLE
		stdout_write: win32.HANDLE

		attributes: win32.SECURITY_ATTRIBUTES
		attributes.nLength = size_of(win32.SECURITY_ATTRIBUTES)
		attributes.bInheritHandle = true
		attributes.lpSecurityDescriptor = nil

		if win32.CreatePipe(&stdout_read, &stdout_write, &attributes, 0) == false {
			return 0, false, stdout[0:]
		}

		if !win32.SetHandleInformation(stdout_read, win32.HANDLE_FLAG_INHERIT, 0) {
			return 0, false, stdout[0:]
		}

		startup_info: win32.STARTUPINFOW
		process_info: win32.PROCESS_INFORMATION

		startup_info.cb = size_of(win32.STARTUPINFOW)

		startup_info.hStdError = stdout_write
		startup_info.hStdOutput = stdout_write
		startup_info.dwFlags |= win32.STARTF_USESTDHANDLES

		if !win32.CreateProcessW(
			nil,
			&win32.utf8_to_utf16(command)[0],
			nil,
			nil,
			true,
			0,
			nil,
			nil,
			&startup_info,
			&process_info,
		) {
			return 0, false, stdout[0:]
		}

		win32.CloseHandle(stdout_write)

		index: int
		read: u32

		read_buffer: [50]byte

		success: win32.BOOL = true

		for success {
			success = win32.ReadFile(stdout_read, &read_buffer[0], len(read_buffer), &read, nil)

			if read > 0 && index + cast(int)read <= len(stdout) {
				mem.copy(&stdout[index], &read_buffer[0], cast(int)read)
			}

			index += cast(int)read
		}

		stdout[index + 1] = 0

		win32.WaitForSingleObject(process_info.hProcess, win32.INFINITE)
		win32.GetExitCodeProcess(process_info.hProcess, &exit_code)
		win32.CloseHandle(stdout_read)
	}
	when ODIN_OS == .Darwin || ODIN_OS == .Linux || ODIN_OS == .NetBSD {
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
	}
	return exit_code, true, stdout[0:index]
}
