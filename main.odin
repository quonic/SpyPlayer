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
	name:  string,
	path:  string,
	frame: f32,
	tags:  ffprobe.Tags,
}

playList: [dynamic]Song

playListLoaded: bool = false
playListLoaded_terminate_thread: bool = false

currentSong: int
currentSongPlayPosition: f32 = 0
currentSongVolume: f32 = 1
currentSongLength: f32 = 0

currentStream: raylib.Music


MAX_SAMPLES :: 512
MAX_SAMPLES_PER_UPDATE :: 4096

print_mutex := b64(false)

main :: proc() {

	did_acquire :: proc(m: ^b64) -> (acquired: bool) {
		res, ok := intrinsics.atomic_compare_exchange_strong(m, false, true)
		return ok && res == false
	}
	task_prompt_load_playlist :: proc(t: thread.Task) {
		for !did_acquire(&print_mutex) {thread.yield()} 	// Allow one thread to print at a time.
		PromptLoadPlaylist()
		print_mutex = false
		time.sleep(1 * time.Millisecond)
		playListLoaded = true
	}

	N :: 1

	pool: thread.Pool
	thread.pool_init(&pool, allocator = context.allocator, thread_count = N)
	defer thread.pool_destroy(&pool)

	thread.pool_add_task(
		&pool,
		allocator = context.allocator,
		procedure = task_prompt_load_playlist,
		data = nil,
		user_index = 0,
	)
	thread.pool_start(&pool)


	raylib.InitWindow(600, 200, "SpyPlayer")
	CreateUserInterface()

	SetWindowToPrimaryMonitor(setFps = true)

	raylib.InitAudioDevice()
	defer raylib.CloseAudioDevice()

	raylib.SetAudioStreamBufferSizeDefault(MAX_SAMPLES_PER_UPDATE)

	// https://github.com/MineBill/Engin3/blob/master/engine/file_dialog_linux.odin

	for !raylib.WindowShouldClose() {
		raylib.BeginDrawing()
		raylib.BeginMode2D(camera)
		raylib.ClearBackground(raylib.BLACK)

		UserInterface()
		if len(playList) == 0 {
			player_state = .NoMusic
		}
		if thread.pool_num_done(&pool) < N {
			thread.yield()
		} else {
			if !playListLoaded_terminate_thread && playListLoaded {
				thread.terminate(pool.threads[N - 1], 0)
				fmt.println("Canceled last thread")
				print_mutex = false

				thread.pool_finish(&pool)
				playListLoaded_terminate_thread = true
			}
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

RemoveSong :: proc(name: string) {
	for song, i in playList {
		if song.name == name {
			ordered_remove(&playList, i)
			break
		}
	}
}


play :: proc() {

	current_song_tags = playList[currentSong].tags
	if !raylib.IsMusicStreamPlaying(currentStream) {
		currentStream = raylib.LoadMusicStream(
			strings.clone_to_cstring(playList[currentSong].path),
		)
		for !raylib.IsMusicReady(currentStream) {
			thread.yield()
		}
	}
	raylib.SetMusicVolume(currentStream, currentSongVolume)
	if player_state == .Paused {
		raylib.ResumeMusicStream(currentStream)
	} else {
		raylib.PlayMusicStream(currentStream)
	}

	player_state = .Playing

	UpdateCurrentSongLabel()
}

pause :: proc() {
	player_state = .Paused
	raylib.PauseMusicStream(currentStream)
}

stop :: proc() {
	player_state = .Stopped
	raylib.StopMusicStream(currentStream)
}

next :: proc() {
	raylib.StopMusicStream(currentStream)
	raylib.UnloadMusicStream(currentStream)
	player_state = .NoMusic
	if len(playList) > 0 {
		currentSong += 1
		if currentSong >= len(playList) {
			currentSong = 0
		}
		play()
	}
}

previous :: proc() {
	raylib.StopMusicStream(currentStream)
	raylib.UnloadMusicStream(currentStream)
	player_state = .NoMusic
	if len(playList) > 0 {
		currentSong -= 1
		if currentSong < 0 {
			currentSong = len(playList) - 1
		}
		play()
	}
}

UpdateCurrentSongLabel :: proc() {
	Texts["current song"].text = fmt.caprintf(
		"%v - %v",
		current_song_tags.title,
		current_song_tags.artist,
	)
}
