package main

import "base:intrinsics"
import "core:encoding/json"
import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:os"
import "core:os/os2"
import "core:strings"
import "core:thread"
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

task_prompt_load_from_dir :: proc(t: ^thread.Thread) {
	PlayListLoading = true
	playListLoaded = false
	// TODO: Add a way to remember the last folder/playlist
	folder := file_dialog.open_file_dialog("*.mp3", directory = true)
	assert(os.exists(folder))

	handle, handleerror := os.open(folder)
	assert(handleerror == nil, fmt.tprintf("Error opening directory: %v", handleerror))

	fileinfo, fileinfoerror := os.read_dir(handle, -1)
	assert(fileinfoerror == nil, fmt.tprintf("Error reading directory: %v", fileinfoerror))

	totalProgress: f16 = f16(len(fileinfo) - 1)
	progress: f16 = 0

	for file in fileinfo {
		// Check if file extension is mp3, wav, or flac supported by miniaudio
		if strings.ends_with(file.name, ".mp3") ||
		   strings.ends_with(file.name, ".wav") ||
		   strings.ends_with(file.name, ".flac") {
			progress = progress + 1
			Texts["current song"].text = fmt.caprintf(
				"Loading: %v%%",
				math.round(progress / totalProgress * 100),
			)
			AddSong(file.fullpath)
		}
	}

	ShufflePlaylist()

	time.sleep(1 * time.Millisecond)

	playListLoaded = true
	media_play_state = .Stopped

	UpdatePlaylistList()
}

ShufflePlaylist :: proc() {
	// If we have at least 2 songs in the playlist shhuffle
	if len(Lists["playlist"].items) >= 2 {
		// Save the current song
		currentSongPlaying := playList[Lists["playlist"].active]
		currentSongPlayingIndex := Lists["playlist"].active
		currentSongTime := raylib.GetMusicTimePlayed(currentStream)
		if media_play_state == .Playing || media_play_state == .Paused {
			ClearList(Lists["playlist"])
			rand.shuffle(playList[:])
			currentSongIndex = currentSongPlayingIndex
			UpdatePlaylistList()
			Texts["current song"].text = fmt.caprintf(
				"%v - %v",
				current_song_tags.title,
				current_song_tags.artist,
			)
			for song, i in playList[:] {
				if song.path == currentSongPlaying.path {
					Lists["playlist"].active = i32(i)
					Lists["playlist"].scrollIndex = i32(i)
					Texts["current song"].text = fmt.caprintf(
						"%v - %v",
						song.tags.title,
						song.tags.artist,
					)
					break
				}
			}
			raylib.SeekMusicStream(currentStream, currentSongTime)
		} else if media_play_state == .Stopped {
			ClearList(Lists["playlist"])
			rand.shuffle(playList[:])
			currentSongIndex = currentSongPlayingIndex
			UpdatePlaylistList()
			for song, i in playList[:] {
				if song.path == currentSongPlaying.path {
					Lists["playlist"].active = i32(i)
					Lists["playlist"].scrollIndex = i32(i)
					Texts["current song"].text = fmt.caprintf(
						"%v - %v",
						song.tags.title,
						song.tags.artist,
					)
					break
				}
			}
			loadSelected()
		}
	}
}

UpdatePlaylistList :: proc() {
	for song, _ in playList {
		append(
			&Lists["playlist"].items,
			fmt.caprintf("%v - %v", song.tags.title, song.tags.artist),
		)
	}
}

ClearPlaylistList :: proc() {
	playList = nil
	Lists["playlist"].items = nil
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

SavePlaylist :: proc() {
	playlist_file := file_dialog.save_file_dialog("*.json")
	if playlist_file == "" {
		return
	}

	// Check if the file already exists
	if os.exists(playlist_file) {
		// File exists, ask the user if they want to overwrite it
		if file_dialog.show_popup(
			   "Overwrite File?",
			   "File already exists. Overwrite?",
			   .Question,
		   ) ==
		   true {
			// Overwrite the file by first removing it
			remove_error := os.remove(playlist_file)
			if remove_error != nil {
				// Failed to remove the file
				fmt.eprintf("Error removing file: %v", remove_error)
				Texts["current song"].text = fmt.caprintf("Error saving playlist! Remove error.")
				return
			}
		} else {
			// Don't overwrite the file
			return
		}
	}

	// Paths to the songs in the playlist
	paths: [dynamic]string
	defer delete(paths)

	// Get the paths to the songs in the playlist
	for song, _ in playList {
		append(&paths, song.path)
	}

	// Marshal the playlist paths to JSON
	json_data, marshalerror := json.marshal(paths)
	if marshalerror != nil {
		fmt.eprintf("Error marshalling data: %v", marshalerror)
		Texts["current song"].text = fmt.caprintf("Error saving playlist! Marshal error.")
		return
	}

	// Write the JSON data to the file
	writeerror := os.write_entire_file(playlist_file, json_data)
	if writeerror != true {
		fmt.eprintf("Error writing file: %v", writeerror)
		Texts["current song"].text = fmt.caprintf("Error saving playlist! Write error.")
		return
	}

	// Notify the user that the playlist was saved
	Texts["current song"].text = fmt.caprintf("Playlist saved!")
}

LoadPlaylist :: proc(path: string = "", clear: bool = true) {
	playlist_file: string
	if path == "" {
		playlist_file = file_dialog.open_file_dialog("*.json")
		if playlist_file == "" {
			return
		}
	} else {
		playlist_file = path
	}
	playlist_data, read_error := os.read_entire_file_from_filename_or_err(playlist_file)
	if read_error != {} {
		fmt.eprintf("Error reading file: %v", read_error)
		Texts["current song"].text = fmt.caprintf("Error loading playlist! Read error.")
		return
	}
	defer delete(playlist_data)

	paths: [dynamic]string
	defer delete(paths)

	err := json.unmarshal(playlist_data, &paths)
	if err != nil {
		fmt.eprintf("Error unmarshalling data: %v", err)
		Texts["current song"].text = fmt.caprintf("Error loading playlist! Unmarshal error.")
		return
	}

	if clear {
		// Clear the current playlist
		ClearPlaylist()
		ClearPlaylistList()
	}

	// Add the paths to the playlist
	for current_item, _ in paths {
		current_path := current_item
		if os.is_file_path(current_item) {
			// Check for leading "./" and replace with current working directory
			if strings.starts_with(current_item, "./") {
				current_path = fmt.aprintf("%v/%v", os.get_current_directory(), current_item[2:])
			}
			AddSong(current_path)
		}
	}
}

ClearPlaylist :: proc() {

	stop()
	playList = nil
	// for _, i in playList {
	// 	unordered_remove(&playList, i)
	// }

	currentSongIndex = 0
	currentSongPath = ""
	current_song_tags = ffprobe.Tags{}

}
