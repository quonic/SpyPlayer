package main

import "core:fmt"
import "core:os"
import "core:strings"
import "file_dialog"
import "vendor:raylib"

PromptLoadPlaylist :: proc() {
	// TODO: Add a way to remember the last folder/playlist
	folder := file_dialog.open_file_dialog("*.mp3", directory = true)
	assert(os.exists(folder))
	musicList := raylib.LoadDirectoryFiles(strings.clone_to_cstring(folder))
	handle, handleerror := os.open(folder)
	assert(handleerror == nil, fmt.tprintf("Error opening directory: %v", handleerror))
	fileinfo, fileinfoerror := os.read_dir(handle, 100)
	assert(fileinfoerror == nil, fmt.tprintf("Error reading directory: %v", fileinfoerror))
	for file in fileinfo {
		// check if file extension is mp3
		if strings.ends_with(file.name, ".mp3") {
			AddSong(file.fullpath)
		}
	}
}
