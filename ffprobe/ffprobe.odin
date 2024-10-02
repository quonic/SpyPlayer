package ffprobe

import "core:encoding/json"
import "core:fmt"
import "core:os/os2"
import "core:strings"

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

TagResult :: struct {
	format: Format,
}

GetTags :: proc(file_name: string) -> (result: TagResult) {

	// NOTE: Must replace spaces in file names with "\ "
	// Can not use "\"file name.mp3\"" as in an argument with os2.process_exec
	replaced_spaces, _ := strings.replace_all(file_name, " ", "\\ ")
	cmd := []string {
		"ffprobe",
		"-v",
		"quiet",
		"-print_format",
		"json",
		"-show_format",
		replaced_spaces,
	}

	state, stdout, stderr, proc_err := os2.process_exec(
		os2.Process_Desc{command = cmd},
		context.allocator,
	)
	defer delete(stdout)
	defer delete(stderr)

	if state.exit_code != 0 || proc_err != nil {
		fmt.printfln("Error: Process Error: %v", proc_err)
		fmt.printfln("----------------- STDOUT --------------------")
		fmt.printfln("%s", transmute(string)stdout)
		fmt.printfln("----------------- STDERR --------------------")
		fmt.printfln("%s", transmute(string)stderr)
		fmt.printfln("----------------- STATUS --------------------")
		fmt.printfln("%v", state)
		return {format = Format{filename = file_name, tags = {title = file_name}}}
	}

	err := json.unmarshal(stdout, &result)
	if err != nil {
		// Never reached
		fmt.println(err)
	}
	return result
}
