package ffprobe


import "../command"
import "core:encoding/ini"
import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:strings"

Format :: struct {
	filename:         string `json:"filename"`,
	nb_streams:       int `json:"nb_streams"`,
	nb_programs:      int `json:"nb_programs"`,
	format_name:      string `json:"format_name"`,
	format_long_name: string `json:"format_long_name"`,
	start_time:       string `json:"start_time"`,
	duration:         string `json:"duration"`,
	size:             string `json:"size"`,
	bit_rate:         string `json:"bit_rate"`,
	probe_score:      int `json:"probe_score"`,
	tags:             Tags `json:"tags"`,
}

Tags :: struct {
	title:       string `json:"title"`,
	artist:      string `json:"artist"`,
	album:       string `json:"album"`,
	description: string `json:"description"`,
	comment:     string `json:"comment"`,
	genre:       string `json:"genre"`,
	date:        string `json:"date"`,
	track:       string `json:"track"`,
	disc:        string `json:"disc"`,
}

GetTags :: proc(file_name: string) -> (result: struct {
		format: Format,
	}) {

	cmd := fmt.aprintf("ffprobe -v quiet -print_format json -show_format \"%s\"", file_name)
	root_buf: [1024 * 16]byte
	data := root_buf[:]
	code, ok, stdout := command.run_executable(cmd, &data)
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
