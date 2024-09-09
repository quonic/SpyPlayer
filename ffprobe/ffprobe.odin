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
