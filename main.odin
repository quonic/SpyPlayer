package main

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:prof/spall"
import "core:strings"
import "core:sync"
import "core:thread"
import "core:time"
import "vendor:raylib"

spall_ctx: spall.Context
@(thread_local)
spall_buffer: spall.Buffer

// SpyPlayer is a Music player that use raylib for the UI and miniaudio for the audio

camera: raylib.Camera2D = {
	offset   = {0, 0},
	target   = {0, 0},
	rotation = 0,
	zoom     = 1,
}

PlaybackState :: enum {
	Playing,
	Paused,
	Stopped,
	NoMusic,
}

media_play_state: PlaybackState = .NoMusic

currentStream: raylib.Music

textFont: raylib.Font
textSpacing: f32 = 2
textFontSize: f32 = 20

songProgress: f32 = 0

scrollTime: f64 = 0.1
lastScrollTime: f64 = 0

EnableToolTips: bool : true

MAX_SAMPLES :: 512
MAX_SAMPLES_PER_UPDATE :: 4096

N :: 4

TRACK_MEMORY_LEAKS :: #config(leaks, false)
OUTPUT_SPALL_TRACE :: #config(trace, false)

// Thread User Indices
LOAD_FROM_CONFIG :: 0
LOAD_FROM_DIR :: 1
LOAD_FROM_JSON :: 2
SAVE_TO_JSON :: 3

main :: proc() {
	when OUTPUT_SPALL_TRACE {
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
	// Initialize raylib
	raylib.InitWindow(600, 200, "SpyPlayer")
	raylib.SetWindowState(raylib.ConfigFlags{raylib.ConfigFlag.WINDOW_ALWAYS_RUN})
	defer raylib.CloseWindow()

	// Move the window to the primary monitor
	when ODIN_OS == .Linux {
		SetWindowToPrimaryMonitor(setFps = true)
	}

	loadStyle()

	// textFont = raylib.LoadFont("assets/fonts/MyFontHere.ttf")
	textFont = raylib.GetFontDefault()

	// Create the UI elements
	CreateUserInterface()
	defer CleanUpControls()

	// Initialize the audio device
	raylib.InitAudioDevice()
	defer raylib.CloseAudioDevice()

	// Set the audio buffer size
	raylib.SetAudioStreamBufferSizeDefault(MAX_SAMPLES_PER_UPDATE)


	{
		XDG_CONFIG_HOME := os.get_env("XDG_CONFIG_HOME", context.temp_allocator)
		if XDG_CONFIG_HOME == "" {
			XDG_CONFIG_HOME = os.get_env("HOME", context.temp_allocator)
			XDG_CONFIG_HOME = fmt.aprintf("%v/.config", XDG_CONFIG_HOME)
		}
		config_file = fmt.aprintf("%v/SpyPlayer/config.json", XDG_CONFIG_HOME)
		if os.exists(config_file) {
			t := thread.create(proc(t: ^thread.Thread) {
				task_load_from_config(t)
			})
			if t == nil {
				fmt.eprintln("Error creating task_load_from_config")
			}
			t.user_index = LOAD_FROM_CONFIG
			append(&threads, t)
			thread.start(t)
			Texts["current song"].text = fmt.caprintf("Playlist loading from config...")
			PlayListLoading = true
		}
	}

	lastScrollTime = raylib.GetTime()

	for !raylib.WindowShouldClose() {
		raylib.BeginDrawing()
		raylib.BeginMode2D(camera)
		raylib.ClearBackground(raylib.Color{81, 81, 81, 255})

		UserInterface()

		LoadingUpdate()
		CheckKeys()
		switch media_play_state {
		case .Playing:
			{

				if Lists["playlist"].active == -1 {
					Lists["playlist"].active = currentSongIndex
				}
				if Lists["playlist"].active != currentSongIndex {
					loadSelected()
					playSelected()
					UpdateCurrentSongText()
				}

				UpdatePlayTime()


				// Scroll the current song text when scrolling is enabled
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

				if raylib.IsMusicReady(currentStream) {
					raylib.UpdateMusicStream(currentStream)
				}
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
	save_config()
}

play :: proc() {
	if raylib.IsMusicReady(currentStream) {
		raylib.PlayMusicStream(currentStream)
		raylib.SetMusicVolume(currentStream, currentSongVolume)
		media_play_state = .Playing
		currentStream.looping = loop_song_toggle.checked
		UpdateCurrentSongText()
	} else {
		if len(playList) == 0 {
			media_play_state = .NoMusic
			return
		}
		currentSongIndex = 0
		currentSongPath = playList[currentSongIndex].path
		current_song_tags = playList[currentSongIndex].tags
		currentStream = raylib.LoadMusicStream(
			strings.clone_to_cstring(playList[currentSongIndex].path, context.temp_allocator),
		)
		raylib.AttachAudioStreamProcessor(currentStream, AudioProcessFFT)
		media_play_state = .Playing
		currentStream.looping = loop_song_toggle.checked
		raylib.PlayMusicStream(currentStream)
		raylib.SetMusicVolume(currentStream, currentSongVolume)
		UpdateCurrentSongText()
	}
}

loadSelected :: proc() {
	if raylib.IsMusicStreamPlaying(currentStream) || raylib.IsMusicReady(currentStream) {
		raylib.StopMusicStream(currentStream)
		raylib.DetachAudioStreamProcessor(currentStream, AudioProcessFFT)
		raylib.UnloadMusicStream(currentStream)
	}

	if Lists["playlist"].active == -1 {
		currentSongIndex = 0
	} else {
		currentSongIndex = Lists["playlist"].active
	}

	if len(playList) == 0 {
		return
	}
	current_song_tags = playList[currentSongIndex].tags
	currentStream = raylib.LoadMusicStream(
		strings.clone_to_cstring(playList[currentSongIndex].path, context.temp_allocator),
	)
	raylib.AttachAudioStreamProcessor(currentStream, AudioProcessFFT)

	raylib.SetMusicVolume(currentStream, currentSongVolume)
}

playSelected :: proc() {
	if media_play_state == .Playing {
		raylib.PlayMusicStream(currentStream)
		currentStream.looping = loop_song_toggle.checked
	}
}

pause :: proc() {
	if len(playList) == 0 {
		media_play_state = .NoMusic
		return
	}
	if raylib.IsMusicStreamPlaying(currentStream) {
		raylib.PauseMusicStream(currentStream)
		media_play_state = .Paused

		UpdateCurrentSongText()
	} else {
		play()
	}
}

stop :: proc() {
	if len(playList) == 0 {
		media_play_state = .NoMusic
		return
	}
	if raylib.IsMusicStreamPlaying(currentStream) || raylib.IsMusicReady(currentStream) {
		raylib.StopMusicStream(currentStream)
		raylib.DetachAudioStreamProcessor(currentStream, AudioProcessFFT)
	}
	media_play_state = .Stopped

	UpdateCurrentSongText()
}

next :: proc() {
	if len(playList) == 0 {
		media_play_state = .NoMusic
		return
	}
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
	raylib.AttachAudioStreamProcessor(currentStream, AudioProcessFFT)

	raylib.SetMusicVolume(currentStream, currentSongVolume)
	if media_play_state == .Playing {
		raylib.PlayMusicStream(currentStream)
	}
	currentStream.looping = loop_song_toggle.checked
	UpdateCurrentSongText()
}

previous :: proc() {
	if len(playList) == 0 {
		media_play_state = .NoMusic
		return
	}
	raylib.StopMusicStream(currentStream)
	raylib.DetachAudioStreamProcessor(currentStream, AudioProcessFFT)
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
	raylib.AttachAudioStreamProcessor(currentStream, AudioProcessFFT)

	raylib.SetMusicVolume(currentStream, currentSongVolume)
	if media_play_state == .Playing {
		raylib.PlayMusicStream(currentStream)
	}
	currentStream.looping = loop_song_toggle.checked
	UpdateCurrentSongText()
}

LoadingUpdate :: proc() {

}

load_from_dir :: proc() {
	media_play_state = .NoMusic
	playListLoaded = false
	PlayListLoading = true
	ClearPlaylist()
	ClearPlaylistList()
	t := thread.create(proc(t: ^thread.Thread) {
		task_prompt_load_from_dir(t)
	})
	if t == nil {
		fmt.eprintln("Error creating task_load_from_config")
	}
	t.user_index = LOAD_FROM_DIR
	append(&threads, t)
	thread.start(t)
	Texts["current song"].text = fmt.caprintf("Playlist loading...")
}

load_from_json :: proc() {
	media_play_state = .NoMusic
	PlayListLoading = true
	t := thread.create(proc(t: ^thread.Thread) {
		task_prompt_load_from_json(t)
	})
	if t == nil {
		fmt.eprintln("Error creating task_load_from_config")
	}
	t.user_index = LOAD_FROM_JSON
	append(&threads, t)
	thread.start(t)
	Texts["current song"].text = fmt.caprintf("Playlist loading...")
}

save_to_json :: proc() {
	t := thread.create(proc(t: ^thread.Thread) {
		task_prompt_save_to_json(t)
	})
	if t == nil {
		fmt.eprintln("Error creating task_load_from_config")
	}
	t.user_index = SAVE_TO_JSON
	append(&threads, t)
	thread.start(t)
	Texts["current song"].text = fmt.caprintf("Playlist saving...")
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

// Thread Pool

// Thanks to VOU-folks for this code: https://github.com/VOU-folks/odin-tcp-server-example/blob/main/main.odin

threads: [dynamic]^thread.Thread

@(init)
create_thread_pool :: proc() {
	threads = make([dynamic]^thread.Thread, 0)
	thread_cleaner()
}

destroy_thread_pool :: proc() {
	delete(threads)
}

thread_cleaner :: proc() {
	t := thread.create(proc(t: ^thread.Thread) {
		for {
			time.sleep(1 * time.Second)

			if len(threads) == 0 {
				continue
			}

			for i := 0; i < len(threads); {
				if PlayListLoading {
					if thread.is_done(t) &&
					   (threads[i].user_index == LOAD_FROM_CONFIG ||
							   threads[i].user_index == LOAD_FROM_JSON ||
							   threads[i].user_index == LOAD_FROM_DIR) {
						Texts["current song"].text = fmt.caprintf("Playlist loaded!")
						currentSongIndex = 0
						currentSongPath = playList[currentSongIndex].path
						current_song_tags = playList[currentSongIndex].tags
						currentStream = raylib.LoadMusicStream(
							strings.clone_to_cstring(
								playList[currentSongIndex].path,
								context.temp_allocator,
							),
						)
						raylib.AttachAudioStreamProcessor(currentStream, AudioProcessFFT)
						PlayListLoading = false
					}
				}

				if threads_cleaner := threads[i]; thread.is_done(threads_cleaner) {
					when ODIN_DEBUG {
						fmt.printf("Thread %d is done\n", threads_cleaner.user_index)
					}
					threads_cleaner.data = nil
					thread.destroy(threads_cleaner)

					ordered_remove(&threads, i)
				} else {
					i += 1
				}
			}
		}
	})
	thread.start(t)
}
