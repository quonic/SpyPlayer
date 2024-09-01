package main

import "base:intrinsics"
import "command"
import c "core:c/libc"
import "core:encoding/json"
import "core:fmt"
import "core:io"
import "core:math"
import "core:os"
import "core:strings"
import "core:thread"
import "core:time"
import "ffprobe"
import "file_dialog"
import "vendor:raylib"

// SpyPlayer is a Music player that use raylib for the UI and miniaudio for the audio

stream: raylib.AudioStream

camera: raylib.Camera2D = {
	offset   = {0, 0},
	target   = {0, 0},
	rotation = 0,
	zoom     = 1,
}

PlayerState :: enum {
	Playing,
	Paused,
	Stopped,
	NoMusic,
}

player_state: PlayerState = .NoMusic

Song :: struct {
	path:  string,
	frame: f32,
	tags:  ffprobe.Tags,
}

playList: [dynamic]Song

playListLoaded: bool = false

currentSongIndex: int = 0
currentSongPath: string
currentSongPlayPosition: f32 = 0
currentSongVolume: f32 = 0.5
currentSongLength: f32 = 0
loadedSongPath: string

PlayListLoading: bool = false

currentStream: raylib.Music


MAX_SAMPLES :: 512
MAX_SAMPLES_PER_UPDATE :: 4096

N :: 1

pool: thread.Pool

main :: proc() {
	// Create the thread pool
	thread.pool_init(&pool, allocator = context.allocator, thread_count = N)
	defer thread.pool_destroy(&pool)

	// Initialize raylib
	raylib.InitWindow(600, 200, "SpyPlayer")

	// Create the UI elements
	CreateUserInterface()

	// Move the window to the primary monitor
	SetWindowToPrimaryMonitor(setFps = true)

	// Initialize the audio device
	raylib.InitAudioDevice()
	defer raylib.CloseAudioDevice()

	// Set the audio buffer size
	raylib.SetAudioStreamBufferSizeDefault(MAX_SAMPLES_PER_UPDATE)

	// https://github.com/MineBill/Engin3/blob/master/engine/file_dialog_linux.odin

	for !raylib.WindowShouldClose() {
		raylib.BeginDrawing()
		raylib.BeginMode2D(camera)
		raylib.ClearBackground(raylib.BLACK)

		// Draw the UI
		UserInterface()

		LoadingUpdate()
		switch player_state {
		case .Playing:
			{
				currentSongPlayPosition = raylib.GetMusicTimePlayed(currentStream)
				currentSongLength = raylib.GetMusicTimeLength(currentStream)
				if currentSongPlayPosition >= currentSongLength {
					next()
				}
				raylib.UpdateMusicStream(currentStream)
			}
		case .Paused:
			{
				currentSongPlayPosition = raylib.GetMusicTimePlayed(currentStream)
				currentSongLength = raylib.GetMusicTimeLength(currentStream)
			}
		case .Stopped:
			{
				currentSongPlayPosition = 0
				currentSongLength = raylib.GetMusicTimeLength(currentStream)
			}
		case .NoMusic:
			{
				currentSongPlayPosition = 0
				currentSongLength = 0
			}
		}


		raylib.EndMode2D()
		raylib.EndDrawing()
	}
	raylib.CloseWindow()
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
	fmt.println("LoadSong")
	if loadedSongPath == path && raylib.IsMusicReady(currentStream) {
		fmt.println("Already loaded")
		return
	} else if loadedSongPath != path {
		fmt.println("Loading")
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

play :: proc() {

	raylib.PlayMusicStream(currentStream)
	raylib.SetMusicVolume(currentStream, currentSongVolume)
	fmt.println("Playing")
	player_state = .Playing

	UpdateCurrentSongLabel()
}

pause :: proc() {
	raylib.PauseMusicStream(currentStream)
	fmt.println("Pausing")
	player_state = .Paused

	UpdateCurrentSongLabel()
}

stop :: proc() {
	raylib.StopMusicStream(currentStream)
	fmt.println("Stopping")
	player_state = .Stopped

	UpdateCurrentSongLabel()
}

next :: proc() {
	raylib.StopMusicStream(currentStream)
	raylib.UnloadMusicStream(currentStream)
	if len(playList) > 0 {
		currentSongIndex += 1
		if currentSongIndex >= len(playList) {
			currentSongIndex = 0
		}
	}
	current_song_tags = playList[currentSongIndex].tags
	currentStream = raylib.LoadMusicStream(
		strings.clone_to_cstring(playList[currentSongIndex].path),
	)

	if player_state == .Playing {
		fmt.println("Play")
		raylib.SetMusicVolume(currentStream, currentSongVolume)
		raylib.PlayMusicStream(currentStream)
	}
	fmt.println("Next")

	UpdateCurrentSongLabel()
}

previous :: proc() {
	raylib.StopMusicStream(currentStream)
	raylib.UnloadMusicStream(currentStream)
	if len(playList) > 0 {
		currentSongIndex -= 1
		if currentSongIndex < 0 {
			currentSongIndex = len(playList) - 1
		}
	}
	current_song_tags = playList[currentSongIndex].tags
	currentStream = raylib.LoadMusicStream(
		strings.clone_to_cstring(playList[currentSongIndex].path),
	)

	if player_state == .Playing {
		fmt.println("Play")
		raylib.SetMusicVolume(currentStream, currentSongVolume)
		raylib.PlayMusicStream(currentStream)
	}
	fmt.println("Previous")

	UpdateCurrentSongLabel()
}

LoadingUpdate :: proc() {
	if PlayListLoading {
		Texts["current song"].text = fmt.caprintf("Playlist loading...")
		if thread.pool_num_done(&pool) >= N {
			thread.terminate(pool.threads[N - 1], 0)
			Texts["current song"].text = fmt.caprintf("Playlist loaded!")

			fmt.printfln("Playlist loaded!")

			thread.pool_finish(&pool)
			currentSongIndex = 0
			currentSongPath = playList[currentSongIndex].path
			current_song_tags = playList[currentSongIndex].tags
			currentStream = raylib.LoadMusicStream(
				strings.clone_to_cstring(playList[currentSongIndex].path),
			)
			PlayListLoading = false
		}
	}
}

load :: proc() {
	thread.pool_add_task(
		&pool,
		allocator = context.allocator,
		procedure = task_prompt_load_playlist,
		data = nil,
		user_index = 0,
	)
	thread.pool_start(&pool)
	Texts["current song"].text = fmt.caprintf("Playlist loading...")
	PlayListLoading = true
}

UpdateCurrentSongLabel :: proc() {
	fmt.println("UpdateCurrentSongLabel")
	Texts["current song"].text = fmt.caprintf(
		"%v - %v",
		current_song_tags.title,
		current_song_tags.artist,
	)
}
