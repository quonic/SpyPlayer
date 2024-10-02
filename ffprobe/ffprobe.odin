package ffprobe


import "../command"
import "core:encoding/json"
import "core:fmt"

Format :: struct {
	filename:         string,
	nb_streams:       int,
	nb_programs:      int,
	format_name:      string,
	format_long_name: string,
	start_time:       string,
	duration:         string,
	size:             string,
	bit_rate:         string,
	probe_score:      int,
	tags:             Tags,
}

Tags :: struct {
	title:       string,
	artist:      string,
	album:       string,
	description: string,
	comment:     string,
	genre:       string,
	date:        string,
	track:       string,
	disc:        string,
}

GetTags :: proc(file_name: string) -> (result: struct {
		format: Format,
	}) {

	cmd := fmt.aprintf("ffprobe -v quiet -print_format json -show_format \"%s\"", file_name)
	root_buf: [1024 * 16]byte
	data := root_buf[:]
	_, ok, stdout := command.run_executable(cmd, &data)
	if !ok {
		return {}
	}
	err := json.unmarshal(stdout, &result)
	if err != nil {
		// Never reached
		fmt.println(err)
	}
	return result
}

/*

// TODO: Get os2.process_exec working inorder to replace command.run_executable

import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:os/os2"
import "core:thread"

GetTags :: proc(file_name: string) -> (result: struct {
		format: Format,
	}) {

	std_out: ^os2.File
	std_in: ^os2.File
	std_err: ^os2.File

	cmd := fmt.aprintf("ffprobe -v quiet -print_format json -show_format \"%s\"", file_name)
	root_buf, aloc_err := mem.make_slice([]byte, 1024 * 16)
	assert(aloc_err == nil, "Failed to allocate memory for tags")
	data := root_buf[:]

	state, stdout, stderr, proc_err := os2.process_exec(
		os2.Process_Desc {
			working_dir = os.get_current_directory(context.allocator),
			command = {cmd},
			env = os2.environ(context.allocator),
			stderr = std_err,
			stdout = std_out,
			stdin = std_in,
		},
		context.allocator,
	)
	if !state.success && state.exit_code != 0 && proc_err != nil {
		fmt.eprintfln("[Error] ffprobe exited with code %v", state.exit_code)
		fmt.eprintfln("[Error] %v", stderr)
		return {}
	}
	for !state.exited {
		thread.yield()
	}
	fmt.printfln("stdout: %v", stdout)
	fmt.printfln("stderr: %v", stderr)
	err := json.unmarshal(stdout, &result)
	if err != nil {
		// Never reached
		fmt.println(err)
	}
	return result
}
*/
