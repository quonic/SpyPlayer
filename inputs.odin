#+feature dynamic-literals
package main

import "core:fmt"
import "vendor:raylib"

SEEK_SECONDS :: 5

// Default Key Bindings
// X - Play
// C - Pause / Play
// V - Stop
// Z - Previous
// B - Next
// UP - Volume Up
// DOWN - Volume Down
// LEFT - Seek backwards
// RIGHT - Seek forwards
// R - Repeat current song
// S - Shuffle
DefaultKeyBindings: map[string]raylib.KeyboardKey = {
	"play"                = raylib.KeyboardKey.X,
	"pause"               = raylib.KeyboardKey.C,
	"stop"                = raylib.KeyboardKey.V,
	"previous"            = raylib.KeyboardKey.Z,
	"next"                = raylib.KeyboardKey.B,
	"volume_up"           = raylib.KeyboardKey.UP,
	"volume_down"         = raylib.KeyboardKey.DOWN,
	"seek_backwards"      = raylib.KeyboardKey.LEFT,
	"seek_forwards"       = raylib.KeyboardKey.RIGHT,
	"repeat_current_song" = raylib.KeyboardKey.R,
	"shuffle"             = raylib.KeyboardKey.S,
}

PlayKey: raylib.KeyboardKey
PauseKey: raylib.KeyboardKey
StopKey: raylib.KeyboardKey
PreviousKey: raylib.KeyboardKey
NextKey: raylib.KeyboardKey
VolumeUpKey: raylib.KeyboardKey
VolumeDownKey: raylib.KeyboardKey
SeekBackwardsKey: raylib.KeyboardKey
SeekForwardsKey: raylib.KeyboardKey
RepeatCurrentSongKey: raylib.KeyboardKey
ShuffleKey: raylib.KeyboardKey

SetDefaultKeyBindings :: proc() {
	for key, _ in DefaultKeyBindings {
		if key == "play" {
			PlayKey = DefaultKeyBindings[key]
		} else if key == "pause" {
			PauseKey = DefaultKeyBindings[key]
		} else if key == "stop" {
			StopKey = DefaultKeyBindings[key]
		} else if key == "previous" {
			PreviousKey = DefaultKeyBindings[key]
		} else if key == "next" {
			NextKey = DefaultKeyBindings[key]
		} else if key == "volume_up" {
			VolumeUpKey = DefaultKeyBindings[key]
		} else if key == "volume_down" {
			VolumeDownKey = DefaultKeyBindings[key]
		} else if key == "seek_backwards" {
			SeekBackwardsKey = DefaultKeyBindings[key]
		} else if key == "seek_forwards" {
			SeekForwardsKey = DefaultKeyBindings[key]
		} else if key == "repeat_current_song" {
			RepeatCurrentSongKey = DefaultKeyBindings[key]
		} else if key == "shuffle" {
			ShuffleKey = DefaultKeyBindings[key]
		}
	}
}

SetKeyBindings :: proc(keys: map[string]string) {
	// Set the default key bindings before setting the new ones
	SetDefaultKeyBindings()
	// Set the new key bindings
	for key, name in keys {
		for keyboard_key, _ in raylib.KeyboardKey {
			if key == fmt.tprintf("%v", keyboard_key) {
				switch name {
				case "play":
					PlayKey = keyboard_key
				case "pause":
					PauseKey = keyboard_key
				case "stop":
					StopKey = keyboard_key
				case "previous":
					PreviousKey = keyboard_key
				case "next":
					NextKey = keyboard_key
				case "volume_up":
					VolumeUpKey = keyboard_key
				case "volume_down":
					VolumeDownKey = keyboard_key
				case "seek_backwards":
					SeekBackwardsKey = keyboard_key
				case "seek_forwards":
					SeekForwardsKey = keyboard_key
				case "repeat_current_song":
					RepeatCurrentSongKey = keyboard_key
				case "shuffle":
					ShuffleKey = keyboard_key
				}
			}
		}
	}
}

GetKeyBindins :: proc() -> map[string]string {
	keys: map[string]string
	defer delete(keys)
	for keyboard_key, _ in raylib.KeyboardKey {
		#partial switch keyboard_key {
		case PlayKey:
			keys["play"] = fmt.tprintf("%v", keyboard_key)
		case PauseKey:
			keys["pause"] = fmt.tprintf("%v", keyboard_key)
		case StopKey:
			keys["stop"] = fmt.tprintf("%v", keyboard_key)
		case PreviousKey:
			keys["previous"] = fmt.tprintf("%v", keyboard_key)
		case NextKey:
			keys["next"] = fmt.tprintf("%v", keyboard_key)
		case VolumeUpKey:
			keys["volume_up"] = fmt.tprintf("%v", keyboard_key)
		case VolumeDownKey:
			keys["volume_down"] = fmt.tprintf("%v", keyboard_key)
		case SeekBackwardsKey:
			keys["seek_backwards"] = fmt.tprintf("%v", keyboard_key)
		case SeekForwardsKey:
			keys["seek_forwards"] = fmt.tprintf("%v", keyboard_key)
		case RepeatCurrentSongKey:
			keys["repeat_current_song"] = fmt.tprintf("%v", keyboard_key)
		case ShuffleKey:
			keys["shuffle"] = fmt.tprintf("%v", keyboard_key)
		}
	}
	return keys
}

CheckKeys :: proc() {
	if playListLoaded {
		// Play
		if raylib.IsKeyPressed(raylib.KeyboardKey.X) {
			play()
		}
		// Pause / Play
		if raylib.IsKeyPressed(raylib.KeyboardKey.C) {
			pause()
		}
		// Stop
		if raylib.IsKeyPressed(raylib.KeyboardKey.V) {
			stop()
		}
		// Previous
		if raylib.IsKeyPressed(raylib.KeyboardKey.Z) {
			previous()
		}
		// Next
		if raylib.IsKeyPressed(raylib.KeyboardKey.B) {
			next()
		}
		// Seek backwards
		if raylib.IsKeyPressed(raylib.KeyboardKey.LEFT) {
			if raylib.IsMusicStreamPlaying(currentStream) {
				Sliders["seek bar"].value -= SEEK_SECONDS
				raylib.SeekMusicStream(
					currentStream,
					raylib.GetMusicTimePlayed(currentStream) - SEEK_SECONDS,
				)
			}
		}
		// Seek forwards
		if raylib.IsKeyPressed(raylib.KeyboardKey.RIGHT) {
			if raylib.IsMusicStreamPlaying(currentStream) {
				Sliders["seek bar"].value += SEEK_SECONDS
				raylib.SeekMusicStream(
					currentStream,
					raylib.GetMusicTimePlayed(currentStream) + SEEK_SECONDS,
				)
			}
		}
		// Shuffle
		if raylib.IsKeyPressed(raylib.KeyboardKey.S) {
			ShufflePlaylist()
		}
		// Volume Up
		if raylib.IsKeyPressed(raylib.KeyboardKey.UP) {
			if volume_slider.value >= 1.0 {
				volume_slider.value = 1.0
			} else {
				volume_slider.value += 0.1
			}
			raylib.SetMusicVolume(currentStream, volume_slider.value)
			currentSongVolume = volume_slider.value

		}
		// Volume Down
		if raylib.IsKeyPressed(raylib.KeyboardKey.DOWN) {
			if volume_slider.value <= 0.0 {
				volume_slider.value = 0.0
			} else {
				volume_slider.value -= 0.1
			}
			raylib.SetMusicVolume(currentStream, volume_slider.value)
			currentSongVolume = volume_slider.value
		}


		// Repeat current song
		if raylib.IsKeyPressed(raylib.KeyboardKey.R) {
			currentStream.looping = !loop_song_toggle.checked
			loop_song_toggle.checked = !loop_song_toggle.checked
		}
	}
}
