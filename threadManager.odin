package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"
import "core:thread"
import "core:time"
import "file_dialog"
import "vendor:raylib"

// Thread User Indices
LOAD_FROM_CONFIG :: 0
LOAD_FROM_DIR :: 1
LOAD_FROM_JSON :: 2
SAVE_TO_JSON :: 3
AUDIO_PROCESS :: 4

// Thread Pool
threads: [dynamic]^thread.Thread

load_from_dir :: proc() {
	t := thread.create(
	proc(t: ^thread.Thread) {
		PlayListLoading = true
		playListLoaded = false
		// TODO: Add a way to remember the last folder/playlist
		folder := file_dialog.open_file_dialog("*.mp3", directory = true)
		assert(os.exists(folder), fmt.tprintf("Folder does not exist: %v", folder))

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
	},
	)
	if t == nil {
		fmt.eprintln("Error creating task_load_from_config")
	}
	t.user_index = LOAD_FROM_DIR
	append(&threads, t)
	thread.start(t)
}

load_from_json :: proc() {
	t := thread.create(proc(t: ^thread.Thread) {
		PlayListLoading = true
		playListLoaded = false
		LoadPlaylist(clear = true)

		time.sleep(1 * time.Millisecond)
		playListLoaded = true
		media_play_state = .Stopped
		UpdatePlaylistList()
	})
	if t == nil {
		fmt.eprintln("Error creating task_load_from_config")
	}
	t.user_index = LOAD_FROM_JSON
	append(&threads, t)
	thread.start(t)
}

save_to_json :: proc() {
	t := thread.create(proc(t: ^thread.Thread) {
		SavePlaylist()
	})
	if t == nil {
		fmt.eprintln("Error creating task_load_from_config")
	}
	t.user_index = SAVE_TO_JSON
	append(&threads, t)
	thread.start(t)
}

@(init)
create_thread_pool :: proc() {
	// Thanks to VOU-folks for this code: https://github.com/VOU-folks/odin-tcp-server-example/blob/main/main.odin
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
