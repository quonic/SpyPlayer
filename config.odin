package main

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "vendor:raylib"

Config :: struct {
	keys:                map[string]string,
	playlist:            [dynamic]Song,
	current_song_volume: f32,
}

config_file: string
config: Config

load_config :: proc() {
	XDG_CONFIG_HOME := os.get_env("XDG_CONFIG_HOME", context.temp_allocator)
	if XDG_CONFIG_HOME == "" {
		XDG_CONFIG_HOME = os.get_env("HOME", context.temp_allocator)
		XDG_CONFIG_HOME = fmt.aprintf("%v/.config", XDG_CONFIG_HOME)
	}
	config_file = fmt.aprintf("%v/SpyPlayer/config.json", XDG_CONFIG_HOME)
	config_data, read_error := os.read_entire_file_from_filename_or_err(config_file)
	if read_error != {} {
		// Config file doesn't exist, do nothing
		return
	}
	defer delete(config_data)

	err := json.unmarshal(config_data, &config)
	if err != nil {
		fmt.eprintf("Error unmarshalling data: %v", err)
		return
	}

	if config.keys == nil {
		SetDefaultKeyBindings()
	} else {
		SetKeyBindings(config.keys)
	}

	if config.playlist == nil {
		media_play_state = .NoMusic
		playListLoaded = true
		currentSongVolume = config.current_song_volume
		currentSongIndex = 0
		fmt.printf("Config loaded\n")
		return
	}

	// Load the playlist
	for song, _ in config.playlist {
		if raylib.FileExists(strings.clone_to_cstring(song.path, context.temp_allocator)) {
			append(&playList, Song{path = song.path, tags = song.tags})
		} else {
			fmt.eprintf("[Warn] File (%v) does not exist, skipping.", song.path)
		}
	}
	media_play_state = .Stopped
	UpdatePlaylistList()
	playListLoaded = true

	// Set the config values
	currentSongVolume = config.current_song_volume
	currentSongIndex = 0
	current_song_tags = playList[currentSongIndex].tags
	currentStream = raylib.LoadMusicStream(
		strings.clone_to_cstring(playList[currentSongIndex].path, context.temp_allocator),
	)
	when FEATURE_FFT {
		raylib.AttachAudioStreamProcessor(currentStream, AudioProcessFFT)
	}

	fmt.printf("Config loaded\n")
}

save_config :: proc() {
	XDG_CONFIG_HOME := os.get_env("XDG_CONFIG_HOME", context.temp_allocator)
	if XDG_CONFIG_HOME == "" {
		XDG_CONFIG_HOME = os.get_env("HOME", context.temp_allocator)
		XDG_CONFIG_HOME = fmt.aprintf("%v/.config", XDG_CONFIG_HOME)
	}
	config_dir := fmt.aprintf("%v/SpyPlayer", XDG_CONFIG_HOME)
	if !os.exists(config_dir) {
		os.make_directory(config_dir, 0o755)
	}
	config_file = fmt.aprintf("%v/SpyPlayer/config.json", XDG_CONFIG_HOME)

	// Check if the file already exists
	if os.exists(config_file) {
		// Overwrite the file by first removing it
		remove_error := os.remove(config_file)
		if remove_error != nil {
			// Failed to remove the file
			fmt.eprintf("Error removing file: %v", remove_error)
			Texts["current song"].text = fmt.caprintf("Error saving config! Remove error.")
			return
		}
	}

	config: Config = {
		keys                = GetKeyBindins(),
		playlist            = playList,
		current_song_volume = currentSongVolume,
	}

	// Marshal the playlist paths to JSON
	json_data, marshalerror := json.marshal(config)
	if marshalerror != nil {
		fmt.eprintf("Error marshalling data for config file: %v", marshalerror)
		return
	}

	// Write the JSON data to the file
	writesuccess := os.write_entire_file(config_file, json_data)
	if writesuccess == false {
		fmt.eprintf("Error writing config file: %v", writesuccess)
		return
	}

	fmt.printf("Config saved\n")
}
