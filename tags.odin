package main

import "core:os"
import "core:strings"
import "core:unicode/utf8"

// Originally from https://github.com/mfbulut/MusicPlayer/blob/main/src/metadata.odin
// LICENSE: GPLv3 - https://github.com/mfbulut/MusicPlayer/blob/main/LICENSE
// Modified to remove os2 dependency

// Reads id3 tags

ID3_Frame_Header :: struct {
	id:    [4]u8,
	size:  int,
	flags: [2]u8,
}

Tags :: struct {
	title:        string,
	artist:       string,
	album:        string,
	year:         string,
	genre:        string,
	track:        string,
	comment:      string,
	album_artist: string,
}

bytes_to_string :: proc(data: []u8) -> (string, bool) {
	if len(data) == 0 {
		return "", false
	}

	start_pos := 0
	if data[0] == 0x00 || data[0] == 0x01 || data[0] == 0x02 || data[0] == 0x03 {
		start_pos = 1
	}

	end_pos := len(data)
	for i in start_pos ..< len(data) {
		if data[i] == 0 {
			end_pos = i
			break
		}
	}

	if end_pos <= start_pos {
		return "", false
	}

	text_data := data[start_pos:end_pos]
	text_str := string(text_data)

	if !utf8.valid_string(text_str) {
		return "", false
	}

	return strings.clone(text_str), true
}

load_id3_tags :: proc(filepath: string) -> (tags: Tags, success: bool) {
	file, err := os.open(filepath)
	if err != os.ERROR_NONE {
		return
	}
	defer os.close(file)
	header_buffer: [10]u8

	bytes_read, read_err := os.read(file, header_buffer[:10])
	if read_err != os.ERROR_NONE || bytes_read < 10 {
		return
	}

	if !strings.has_prefix(string(header_buffer[:3]), "ID3") {
		return
	}

	version := header_buffer[3]

	size :=
		(int(header_buffer[6]) & 0x7F) << 21 |
		(int(header_buffer[7]) & 0x7F) << 14 |
		(int(header_buffer[8]) & 0x7F) << 7 |
		(int(header_buffer[9]) & 0x7F)

	pos := 10

	if header_buffer[5] & 0x40 != 0 {
		ext_header_size_buf: [4]u8

		bytes_read, read_err = os.read(file, ext_header_size_buf[:4])
		if read_err != os.ERROR_NONE || bytes_read < 4 {
			return
		}

		extended_size :=
			int(ext_header_size_buf[0]) << 24 |
			int(ext_header_size_buf[1]) << 16 |
			int(ext_header_size_buf[2]) << 8 |
			int(ext_header_size_buf[3])

		os.seek(file, i64(extended_size), os.SEEK_CUR)
		pos += 4 + extended_size
	}

	frame_header_buf: [10]u8

	for pos < size {
		bytes_read, read_err = os.read(file, frame_header_buf[:10])
		if read_err != os.ERROR_NONE || bytes_read < 10 {
			break
		}

		frame: ID3_Frame_Header
		frame.id[0] = frame_header_buf[0]
		frame.id[1] = frame_header_buf[1]
		frame.id[2] = frame_header_buf[2]
		frame.id[3] = frame_header_buf[3]
		frame_id := string(frame.id[:])

		if frame.id[0] == 0 && frame.id[1] == 0 && frame.id[2] == 0 && frame.id[3] == 0 {
			break
		}

		frame.size = 0
		if version >= 4 {
			frame.size =
				(int(frame_header_buf[4]) & 0x7F) << 21 |
				(int(frame_header_buf[5]) & 0x7F) << 14 |
				(int(frame_header_buf[6]) & 0x7F) << 7 |
				(int(frame_header_buf[7]) & 0x7F)
		} else {
			frame.size =
				int(frame_header_buf[4]) << 24 |
				int(frame_header_buf[5]) << 16 |
				int(frame_header_buf[6]) << 8 |
				int(frame_header_buf[7])
		}

		frame.flags[0] = frame_header_buf[8]
		frame.flags[1] = frame_header_buf[9]

		switch frame_id {
		case "TIT2", "TPE1", "TALB", "TDRC", "TYER", "TCON", "TRCK", "COMM", "TPE2":
			frame_data := make([]u8, frame.size)
			defer delete(frame_data)

			bytes_read, read_err = os.read(file, frame_data)
			if read_err != os.ERROR_NONE || bytes_read < frame.size {
				break
			}

			switch frame_id {
			case "TIT2":
				tags.title = bytes_to_string(frame_data) or_return
			case "TPE1":
				tags.artist = bytes_to_string(frame_data) or_return
			case "TALB":
				tags.album = bytes_to_string(frame_data) or_return
			case "TDRC", "TYER":
				tags.year = bytes_to_string(frame_data) or_return
			case "TCON":
				genre_str := bytes_to_string(frame_data) or_return
				tags.genre = genre_str
			case "TRCK":
				tags.track = bytes_to_string(frame_data) or_return
			case "COMM":
				if len(frame_data) > 4 {
					comment_start := 4
					for i in comment_start ..< len(frame_data) {
						if frame_data[i] == 0 {
							comment_start = i + 1
							break
						}
					}
					if comment_start < len(frame_data) {
						tags.comment = bytes_to_string(frame_data[comment_start:]) or_return
					}
				}
			case "TPE2":
				tags.album_artist = bytes_to_string(frame_data) or_return
			}
		case:
			os.seek(file, i64(frame.size), os.SEEK_CUR)
		}

		pos += 10 + frame.size
	}

	has_any_tags :=
		tags.title != "" ||
		tags.artist != "" ||
		tags.album != "" ||
		tags.year != "" ||
		tags.genre != "" ||
		tags.track != "" ||
		tags.comment != "" ||
		tags.album_artist != ""

	return tags, has_any_tags
}
