package main

import "base:intrinsics"
import "base:runtime"
import "command"
import c "core:c/libc"
import "core:encoding/json"
import "core:fmt"
import "core:io"
import "core:math"
import "core:mem"
import "core:os"
import "core:prof/spall"
import "core:strings"
import "core:sync"
import "core:thread"
import "core:time"
import "ffprobe"
import "file_dialog"
import "vendor:raylib"

spall_ctx: spall.Context
@(thread_local)
spall_buffer: spall.Buffer

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

currentSongIndex: i32 = 0
currentSongPath: string
currentSongVolume: f32 = 0.5
loadedSongPath: string

PlayListLoading: bool = false

currentStream: raylib.Music

textFont: raylib.Font
textSpacing: f32 = 2

current_time: f64
dt: f64
last_time: f64
fixed_step_timer: f64
fps_timer: f64
fps_counter: int
fps_value: f64

songProgress: f32 = 0

scrollTime: f64 = 0.1
lastScrollTime: f64 = 0

MAX_SAMPLES :: 512
MAX_SAMPLES_PER_UPDATE :: 4096

N :: 1

pool: thread.Pool

TRACK_MEMORY_LEAKS :: #config(leaks, false)
OUPUT_SPALL_TRACE :: #config(trace, false)

main :: proc() {
	when OUPUT_SPALL_TRACE {
		spall_ctx = spall.context_create("trace_test.spall")
		defer spall.context_destroy(&spall_ctx)

		buffer_backing := make([]u8, spall.BUFFER_DEFAULT_SIZE)
		spall_buffer = spall.buffer_create(buffer_backing, u32(sync.current_thread_id()))
		defer spall.buffer_destroy(&spall_ctx, &spall_buffer)
	}

	when TRACK_MEMORY_LEAKS {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		context.allocator = mem.tracking_allocator(&track)

		_main()

		for _, leak in track.allocation_map {
			if strings.contains(leak.location.file_path, "SpyPlayer") {
				fmt.printf("%v leaked %m\n", leak.location, leak.size)
			}
		}
		for bad_free in track.bad_free_array {
			if strings.contains(bad_free.location.file_path, "SpyPlayer") {
				fmt.printf(
					"%v allocation %p was freed badly\n",
					bad_free.location,
					bad_free.memory,
				)
			}
		}
	} else {
		_main()
	}
}

// Automatic profiling of every procedure:

@(instrumentation_enter)
spall_enter :: proc "contextless" (
	proc_address, call_site_return_address: rawptr,
	loc: runtime.Source_Code_Location,
) {
	spall._buffer_begin(&spall_ctx, &spall_buffer, "", "", loc)
}

@(instrumentation_exit)
spall_exit :: proc "contextless" (
	proc_address, call_site_return_address: rawptr,
	loc: runtime.Source_Code_Location,
) {
	spall._buffer_end(&spall_ctx, &spall_buffer)
}


_main :: proc() {
	// Create the thread pool
	thread.pool_init(&pool, allocator = context.allocator, thread_count = N)
	defer thread.pool_destroy(&pool)

	// Initialize raylib
	raylib.InitWindow(600, 200, "SpyPlayer")

	loadStyle()

	// textFont = raylib.LoadFont("assets/fonts/MyFontHere.ttf")
	textFont = raylib.GetFontDefault()

	// Create the UI elements
	CreateUserInterface()

	// Move the window to the primary monitor
	SetWindowToPrimaryMonitor(setFps = true)

	// Initialize the audio device
	raylib.InitAudioDevice()
	defer raylib.CloseAudioDevice()

	// Set the audio buffer size
	raylib.SetAudioStreamBufferSizeDefault(MAX_SAMPLES_PER_UPDATE)

	lastScrollTime = raylib.GetTime()

	for !raylib.WindowShouldClose() {
		raylib.BeginDrawing()
		raylib.BeginMode2D(camera)
		raylib.ClearBackground(raylib.Color{81, 81, 81, 255})

		UserInterface()

		LoadingUpdate()
		switch player_state {
		case .Playing:
			{

				if Lists["playlist"].active == -1 {
					Lists["playlist"].active = currentSongIndex
				}
				if Lists["playlist"].active != currentSongIndex {
					playSelected()
					UpdateCurrentSongText()
				}

				UpdatePlayTime()


				// Scrool the current song text when scrolling is enabled
				if Texts["current song"].text != "" && Texts["current song"].scrolling {
					// Scroll the text every scrollTime seconds
					if raylib.GetTime() - lastScrollTime > scrollTime {
						text: string = cast(string)Texts["current song"].text
						// Scroll the text
						Texts["current song"].text = fmt.caprintf("%v%v", text[1:], text[:1])
						// Update the last time we scrolled
						lastScrollTime = raylib.GetTime()
					}
				}
				songProgress =
					raylib.GetMusicTimePlayed(currentStream) /
					raylib.GetMusicTimeLength(currentStream)

				raylib.UpdateMusicStream(currentStream)
				if !raylib.IsMusicStreamPlaying(currentStream) {
					next()
				}
			}
		case .Paused:
			{
				if Lists["playlist"].active == -1 {
					Lists["playlist"].active = currentSongIndex
				}
				if Lists["playlist"].active != currentSongIndex {
					loadSelected()
					UpdateCurrentSongText()
				}
			}
		case .Stopped:
			{
				if Lists["playlist"].active == -1 {
					Lists["playlist"].active = currentSongIndex
				}
				if Lists["playlist"].active != currentSongIndex {
					loadSelected()
					UpdateCurrentSongText()
				}
			}
		case .NoMusic:
			{
			}
		}


		raylib.EndMode2D()
		raylib.EndDrawing()
	}
	raylib.CloseWindow()
	CleanUpControls()
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

play :: proc() {

	raylib.PlayMusicStream(currentStream)
	raylib.SetMusicVolume(currentStream, currentSongVolume)
	player_state = .Playing
	currentStream.looping = false // Prevent current song from looping TODO: Add a setting for this
	UpdateCurrentSongText()
}

loadSelected :: proc() {
	raylib.StopMusicStream(currentStream)
	raylib.UnloadMusicStream(currentStream)

	currentSongIndex = Lists["playlist"].active

	current_song_tags = playList[currentSongIndex].tags
	currentStream = raylib.LoadMusicStream(
		strings.clone_to_cstring(playList[currentSongIndex].path, context.temp_allocator),
	)

	raylib.SetMusicVolume(currentStream, currentSongVolume)
}

playSelected :: proc() {
	loadSelected()
	if player_state == .Playing {
		raylib.PlayMusicStream(currentStream)
	}
}

pause :: proc() {
	raylib.PauseMusicStream(currentStream)
	player_state = .Paused

	UpdateCurrentSongText()
}

stop :: proc() {
	raylib.StopMusicStream(currentStream)
	player_state = .Stopped

	UpdateCurrentSongText()
}

next :: proc() {
	raylib.StopMusicStream(currentStream)
	raylib.UnloadMusicStream(currentStream)
	if len(playList) > 0 {
		currentSongIndex += 1
		if currentSongIndex >= i32(len(playList)) {
			currentSongIndex = 0
		}
	}
	current_song_tags = playList[currentSongIndex].tags
	currentStream = raylib.LoadMusicStream(
		strings.clone_to_cstring(playList[currentSongIndex].path, context.temp_allocator),
	)

	raylib.SetMusicVolume(currentStream, currentSongVolume)
	if player_state == .Playing {
		raylib.PlayMusicStream(currentStream)
	}
	currentStream.looping = false
	UpdateCurrentSongText()
}

previous :: proc() {
	raylib.StopMusicStream(currentStream)
	raylib.UnloadMusicStream(currentStream)
	if len(playList) > 0 {
		currentSongIndex -= 1
		if currentSongIndex < 0 {
			currentSongIndex = i32(len(playList)) - 1
		}
	}
	current_song_tags = playList[currentSongIndex].tags
	currentStream = raylib.LoadMusicStream(
		strings.clone_to_cstring(playList[currentSongIndex].path),
	)

	raylib.SetMusicVolume(currentStream, currentSongVolume)
	if player_state == .Playing {
		raylib.PlayMusicStream(currentStream)
	}
	currentStream.looping = false
	UpdateCurrentSongText()
}

LoadingUpdate :: proc() {
	if PlayListLoading {
		Texts["current song"].text = fmt.caprintf("Playlist loading...")
		if thread.pool_num_done(&pool) >= N {
			thread.terminate(pool.threads[N - 1], 0)
			Texts["current song"].text = fmt.caprintf("Playlist loaded!")

			thread.pool_finish(&pool)
			currentSongIndex = 0
			currentSongPath = playList[currentSongIndex].path
			current_song_tags = playList[currentSongIndex].tags
			currentStream = raylib.LoadMusicStream(
				strings.clone_to_cstring(playList[currentSongIndex].path, context.temp_allocator),
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

UpdateCurrentSongText :: proc() {
	Texts["current song"].text = fmt.caprintf(
		"%v - %v",
		current_song_tags.title,
		current_song_tags.artist,
	)
	// Add some spaces to the end of the text
	if Texts["current song"].scrolling == false &&
	   MeasureTextDimensions("current song", Texts["current song"].text).x >
		   Texts["current song"].positionRec.width {
		Texts["current song"].scrolling = true
		Texts["current song"].text = fmt.caprintf(
			"%v - %v    ",
			current_song_tags.title,
			current_song_tags.artist,
		)
	} else {
		Texts["current song"].scrolling = false
	}

	UpdatePlayTime()

	Lists["playlist"].scrollIndex = currentSongIndex
	Lists["playlist"].active = currentSongIndex
}

UpdatePlayTime :: proc() {
	song_length := raylib.GetMusicTimeLength(currentStream)
	Texts["song length"].text = fmt.caprintf(
		"%02d:%02d",
		int(song_length / 60) % 60,
		int(song_length) % 60,
	)
	// Update the play time text
	play_time := raylib.GetMusicTimePlayed(currentStream)
	Texts["play time"].text = fmt.caprintf(
		"%02d:%02d",
		int(play_time / 60) % 60,
		int(play_time) % 60,
	)
	songProgress =
		raylib.GetMusicTimePlayed(currentStream) / raylib.GetMusicTimeLength(currentStream)
	Sliders["seek bar"].value = songProgress
}
