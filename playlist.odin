package main

import "base:intrinsics"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strings"
import "core:thread"
import "core:time"
import "file_dialog"
import "vendor:raylib"

did_acquire :: proc(m: ^b64) -> (acquired: bool) {
	res, ok := intrinsics.atomic_compare_exchange_strong(m, false, true)
	return ok && res == false
}

task_prompt_load_playlist :: proc(t: thread.Task) {
	// TODO: Add a way to remember the last folder/playlist
	folder := file_dialog.open_file_dialog("*.mp3", directory = true)
	assert(os.exists(folder))
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
	ShufflePlaylist()

	time.sleep(1 * time.Millisecond)
	playListLoaded = true
	player_state = .Stopped
	UpdatePlaylistList()
}


ShufflePlaylist :: proc() {
	rand.shuffle(playList[:])
}

UpdatePlaylistList :: proc() {
	for song, i in playList {
		append(&Lists["playlist"].items, fmt.caprint(song.tags.title))
	}
}
