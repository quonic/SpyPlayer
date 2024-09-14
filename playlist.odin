package main

import "base:intrinsics"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strings"
import "core:thread"
import "core:math"
import "core:time"
import "ffprobe"
import "file_dialog"
import "vendor:raylib"

Song :: struct {
	path:  string,
	frame: f32,
	tags:  ffprobe.Tags,
}

playList: [dynamic]Song

playListLoaded: bool = false

currentSongIndex: i32 = 0
currentSongPath: string
currentSongVolume: f32 = 0.5
loadedSongPath: string

PlayListLoading: bool = false

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
	totalProgress :f16= f16(len(fileinfo) - 1)
	progress:f16=0
	for file in fileinfo {
		// Check if file extension is mp3, wav, or flac supported by miniaudio
		if strings.ends_with(file.name, ".mp3") ||
		   strings.ends_with(file.name, ".wav") ||
		   strings.ends_with(file.name, ".flac") {
			progress = progress + 1
			Texts["current song"].text = fmt.caprintf("Loading: %v%%", math.round(progress / totalProgress * 100))
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
	for song, _ in playList {
		append(
			&Lists["playlist"].items,
			fmt.caprintf("%v - %v", song.tags.title, song.tags.artist),
		)
	}
}

AddSong :: proc(path: string) {
	frame := ffprobe.GetTags(path)
	append(&playList, Song{path = path, tags = frame.format.tags})
}

RemoveSong :: proc(path: string) {
	for song, i in playList {
		if song.path == path {
			ordered_remove(&playList, i)
			break
		}
	}
}

IsSongLoaded :: proc(path: string) -> bool {
	if playList[currentSongIndex].path == currentSongPath {
		return true
	}
	return false
}

LoadSong :: proc(path: string) {
	if loadedSongPath == path && raylib.IsMusicReady(currentStream) {
		return
	} else if loadedSongPath != path {
		current_song_tags = playList[currentSongIndex].tags
		currentStream = raylib.LoadMusicStream(
			strings.clone_to_cstring(playList[currentSongIndex].path),
		)
		for !raylib.IsMusicReady(currentStream) {
			thread.yield()
		}
		loadedSongPath = path
	}
}
