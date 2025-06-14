package main

import "aseprite"
import "core:fmt"
import "core:math"
import "ffprobe"
import "vendor:raylib"

window_texture: raylib.Texture2D
previous_button: ButtonControl
play_button: ButtonControl
pause_button: ButtonControl
next_button: ButtonControl
stop_button: ButtonControl
current_song_text: TextControl
volume_slider: SliderControl
eq_slider: SliderControl
meter_slider: SliderControl
load_button: ButtonControl
seek_bar: SliderControl
song_length_text: TextControl
play_time_text: TextControl
playlist_list: ListControl
slider_bar: raylib.Rectangle
loop_song_toggle: ToggleControl
add_song_button: ButtonControl
remove_song_button: ButtonControl
meter_bar: AudioVisualizerControl
song_time_divider: PictureControl
shuffle_button: ButtonControl

playlist_scrollbar: raylib.Rectangle
playlist_minus_button: raylib.Rectangle
playlist_position_button: raylib.Rectangle
playlist_plus_button: raylib.Rectangle
playlist_background: raylib.Rectangle

save_playlist_button: ButtonControl
load_playlist_button: ButtonControl

radio_unchecked: raylib.Rectangle
radio_checked: raylib.Rectangle

spriteSheet: aseprite.Aseprite

current_song_tags: ffprobe.Tags

CreateUserInterface :: proc() {
	CreateUI()
}

CreateUI :: proc() {
	spriteSheet, ok := aseprite.ReadAsespriteJsonFile("assets/window.json")
	assert(ok, fmt.tprintf("Error reading file"))
	window_texture = raylib.LoadTexture(fmt.caprintf("assets/%s", spriteSheet.meta.image))

	for slice, _ in spriteSheet.meta.slices {
		name := slice.name
		// color := slice.color
		keys := slice.keys

		for key, _ in keys {
			switch name {
			case "previous":
				previous_button = {
					name = name,
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tooltip = "Previous",
				}
			case "play":
				play_button = {
					name = "play",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					tooltip = "Play",
				}
			case "next":
				next_button = {
					name = "next",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					tooltip = "Next",
				}
			case "stop":
				stop_button = {
					name = "stop",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					tooltip = "Stop",
				}
			case "pause":
				pause_button = {
					name = "pause",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					tooltip = "Pause",
				}
			case "current song":
				current_song_text = {
					name = "current song",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					text = "",
					fontSize = 20,
					font = textFont,
					spacing = textSpacing,
					scrolling = false,
					textColor = raylib.BLACK,
					centered = false,
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
				}
			case "volume":
				for k, _ in spriteSheet.meta.slices {
					switch k.name {
					case "slider bar":
						slider_bar = {
							k.keys[0].bounds.x,
							k.keys[0].bounds.y,
							k.keys[0].bounds.w,
							k.keys[0].bounds.h,
						}
					}
				}
				volume_slider = {
					name = "volume",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					sliderPositionInset = 6,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					sliderPosition = key.bounds.x + 6 + (currentSongVolume * key.bounds.w),
					slider = {
						sourceRec = slider_bar,
						sliderPosition = {
							x = key.bounds.x,
							y = key.bounds.y,
							width = key.bounds.w,
							height = key.bounds.h,
						},
					},
					value = 0.5,
					valueReturnCallback = proc(value: f32) {
						raylib.SetMusicVolume(currentStream, value)
						currentSongVolume = value
					},
					tooltip = "Volume",
				}
			case "load":
				load_button = {
					name = "load",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					tooltip = "Load music from a directory",
				}
			case "seek bar":
				for k, _ in spriteSheet.meta.slices {
					switch k.name {
					case "seeker bar":
						slider_bar = {
							k.keys[0].bounds.x,
							k.keys[0].bounds.y,
							k.keys[0].bounds.w,
							k.keys[0].bounds.h,
						}
					}
				}
				seek_bar = {
					name = "seek bar",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					sliderPositionInset = 6,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					sliderPosition = key.bounds.x + 6 + (songProgress * key.bounds.w),
					slider = {
						sourceRec = slider_bar,
						sliderPosition = {
							x = key.bounds.x,
							y = key.bounds.y,
							width = key.bounds.w,
							height = key.bounds.h,
						},
					},
					value = 0,
					valueReturnCallback = proc(value: f32) {
						//Convert value that is between 0 and 1 to a time in seconds based on the song length
						if raylib.IsMusicStreamPlaying(currentStream) {
							raylib.SeekMusicStream(
								currentStream,
								raylib.GetMusicTimeLength(currentStream) * value,
							)
						}
					},
				}
			case "song length":
				song_length_text = {
					name = "song length",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					text = "00:00",
					fontSize = 20,
					font = textFont,
					spacing = textSpacing,
					centered = true,
					scrolling = false,
					textColor = raylib.BLACK,
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
				}
			case "play time":
				play_time_text = {
					name = "play time",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					text = "00:00",
					fontSize = 20,
					font = textFont,
					spacing = textSpacing,
					centered = true,
					scrolling = false,
					textColor = raylib.BLACK,
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
				}
			case "playlist":
				for k, _ in spriteSheet.meta.slices {
					switch k.name {
					case "playlist scrollbar":
						playlist_scrollbar = {
							k.keys[0].bounds.x,
							k.keys[0].bounds.y,
							k.keys[0].bounds.w,
							k.keys[0].bounds.h,
						}
					case "playlist minus button":
						playlist_minus_button = {
							k.keys[0].bounds.x,
							k.keys[0].bounds.y,
							k.keys[0].bounds.w,
							k.keys[0].bounds.h,
						}
					case "playlist plus button":
						playlist_plus_button = {
							k.keys[0].bounds.x,
							k.keys[0].bounds.y,
							k.keys[0].bounds.w,
							k.keys[0].bounds.h,
						}
					case "playlist background":
						playlist_background = {
							k.keys[0].bounds.x,
							k.keys[0].bounds.y,
							k.keys[0].bounds.w,
							k.keys[0].bounds.h,
						}
					}
				}
				playlist_list = {
					name = "playlist",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					fontSize = 14,
					active = 0,
					font = textFont,
					spacing = textSpacing,
					tintSelected = raylib.GREEN,
					tint = raylib.WHITE,
					textColor = raylib.DARKGRAY,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					scrollIndex = 0,
					scrollSpeed = 10,
					sliderSize = 20,
					scrollbarVertical = true,
				}
			case "loop song":
				for k, _ in spriteSheet.meta.slices {
					switch k.name {
					case "radio unchecked":
						radio_unchecked = {
							k.keys[0].bounds.x,
							k.keys[0].bounds.y,
							k.keys[0].bounds.w,
							k.keys[0].bounds.h,
						}
					case "radio checked":
						radio_checked = {
							k.keys[0].bounds.x,
							k.keys[0].bounds.y,
							k.keys[0].bounds.w,
							k.keys[0].bounds.h,
						}
					}
				}

				loop_song_toggle = {
					name = "loop song",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					wasPressed = false,
					togglePositionOffset = {x = 2, y = 4, width = 9, height = 9},
					toggleTextureUnchecked = radio_unchecked,
					toggleTextureChecked = radio_checked,
					tint_pressed = raylib.LIGHTGRAY,
					tint_normal = raylib.WHITE,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					checked = false,
					shape = ToggleShape.Toggle_Circle,
					checkColor = raylib.Color{0, 0, 0, 0},
					tooltip = "Loop current song",
				}
			case "add song":
				add_song_button = {
					name = "add song",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					tooltip = "Add a song to playlist",
				}
			case "remove song":
				remove_song_button = {
					name = "remove song",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					tooltip = "Remove selected song from playlist",
				}
			case "save playlist":
				save_playlist_button = {
					name = "save playlist",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					tooltip = "Save playlist",
				}
			case "load playlist":
				load_playlist_button = {
					name = "load playlist",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					tooltip = "Load playlist",
				}
			case "meter":
				meter_bar = {
					name = "meter",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.BLACK,
					tint_disabled = raylib.DARKGRAY,
					leftChannelBars = {},
					rightChannelBars = {},
					barColors = []raylib.Color {
						raylib.RED,
						raylib.RED,
						raylib.GREEN,
						raylib.GREEN,
						raylib.BLUE,
						raylib.BLUE,
						raylib.YELLOW,
						raylib.YELLOW,
						raylib.ORANGE,
						raylib.ORANGE,
						raylib.PURPLE,
						raylib.PURPLE,
					},
				}
			case "song time divider":
				song_time_divider = {
					name = "song time divider",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_disabled = raylib.DARKGRAY,
				}
			case "shuffle":
				shuffle_button = {
					name = "shuffle",
					enabled = true,
					positionRec = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint = raylib.WHITE,
					texture = window_texture,
					positionSpriteSheet = {
						x = key.bounds.x,
						y = key.bounds.y,
						width = key.bounds.w,
						height = key.bounds.h,
					},
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
					tooltip = "Shuffle",
				}
			}
			AddButton(&previous_button)
			AddButton(&play_button)
			AddButton(&pause_button)
			AddButton(&next_button)
			AddButton(&stop_button)
			AddToggle(&loop_song_toggle)
			AddSlider(&volume_slider)
			// AddSlider(&eq_slider)
			// AddSlider(&meter_slider)
			AddButton(&load_button)
			AddSlider(&seek_bar)
			AddList(&playlist_list)
			AddText(&current_song_text)
			AddAudioVisualizer(&meter_bar)
			AddPicture(&song_time_divider)
			AddButton(&shuffle_button)

			AddText(&song_length_text)
			AddText(&play_time_text)
			AddButton(&add_song_button)
			AddButton(&remove_song_button)
			AddButton(&save_playlist_button)
			AddButton(&load_playlist_button)
		}
	}
}

UserInterface :: proc() {
	DrawButtons()
	DrawPictures()
	DrawSliders()
	DrawLists()
	DrawTexts()
	DrawToggles()
	when FEATURE_FFT {DrawAudioVisualizers()}
	if EnableToolTips {DrawToolTips()}
	HandleButtonActions()
}

DrawToolTips :: proc() {
	for button in Buttons {
		DrawToolTip(
			Buttons[button].tooltip,
			Buttons[button].positionRec.x,
			Buttons[button].positionRec.y,
			camera,
			textFont,
			textFontSize,
			Buttons[button].hovering,
		)
	}
	for toggle in Toggles {
		DrawToolTip(
			Toggles[toggle].tooltip,
			Toggles[toggle].positionRec.x,
			Toggles[toggle].positionRec.y,
			camera,
			textFont,
			textFontSize,
			Toggles[toggle].hovering,
		)
	}
}

DrawButtons :: proc() {
	DrawButtonControl("previous", camera)
	DrawButtonControl("play", camera)
	DrawButtonControl("pause", camera)
	DrawButtonControl("next", camera)
	DrawButtonControl("stop", camera)
	DrawButtonControl("load", camera)
	DrawButtonControl("add song", camera)
	DrawButtonControl("remove song", camera)
	DrawButtonControl("save playlist", camera)
	DrawButtonControl("load playlist", camera)
	DrawButtonControl("shuffle", camera)
}

DrawSliders :: proc() {
	DrawSliderControl("volume", camera)
	DrawSliderControl("seek bar", camera)
	// DrawSliderControl("eq_slider", camera)
	// DrawSliderControl("meter_slider", camera)
}

DrawPictures :: proc() {
	DrawPictureControl("song time divider", camera)
}

DrawTexts :: proc() {
	DrawTextControl("current song", camera)
	DrawTextControl("song length", camera)
	DrawTextControl("play time", camera)
}

DrawLists :: proc() {
	DrawListControl("playlist", camera)
}

DrawToggles :: proc() {
	DrawToggleControl("loop song", camera)
}

DrawAudioVisualizers :: proc() {
	DrawAudioVisualizerControl("meter", songProgress, camera)
}

HandleButtonActions :: proc() {
	if GetButtonPressedState("load") == 1 {
		media_play_state = .NoMusic
		playListLoaded = false
		PlayListLoading = true
		ClearPlaylist()
		ClearPlaylistList()
		load_from_dir()
		Texts["current song"].text = fmt.caprintf("Playlist loading...")
	}
	if GetButtonPressedState("load playlist") == 1 {
		media_play_state = .NoMusic
		PlayListLoading = true
		load_from_json()
		Texts["current song"].text = fmt.caprintf("Playlist loading...")
	}
	if playListLoaded {
		if Buttons["play"].enabled == false {
			Buttons["previous"].enabled = true
			Buttons["play"].enabled = true
			Buttons["pause"].enabled = true
			Buttons["next"].enabled = true
			Buttons["stop"].enabled = true
			Sliders["volume"].enabled = true
			Sliders["seek bar"].enabled = true
			Toggles["loop song"].enabled = true
			Buttons["add song"].enabled = true
			Buttons["remove song"].enabled = true
			Buttons["save playlist"].enabled = true
			Buttons["shuffle"].enabled = true
		}
		if GetButtonPressedState("save playlist") == 1 {
			save_to_json()
			Texts["current song"].text = fmt.caprintf("Playlist saving...")
		}
		if GetTogglePressedState("loop song") == 1 {
			currentStream.looping = !loop_song_toggle.checked
			loop_song_toggle.checked = !loop_song_toggle.checked
		}
		if GetButtonPressedState("previous") == 1 {
			previous()
		}
		if GetButtonPressedState("play") == 1 {
			play()
		}
		if GetButtonPressedState("pause") == 1 {
			pause()
		}
		if GetButtonPressedState("next") == 1 {
			next()
		}
		if GetButtonPressedState("stop") == 1 {
			stop()
		}
		if GetButtonPressedState("add song") == 1 {
			fmt.printf("Add song\n")
		}
		if GetButtonPressedState("remove song") == 1 {
			fmt.printf("Remove song\n")
		}
		if GetButtonPressedState("shuffle") == 1 {
			ShufflePlaylist()
		}
	} else {
		Buttons["previous"].enabled = false
		Buttons["play"].enabled = false
		Buttons["pause"].enabled = false
		Buttons["next"].enabled = false
		Buttons["stop"].enabled = false
		Sliders["volume"].enabled = false
		Sliders["seek bar"].enabled = false
		Toggles["loop song"].enabled = false
		Buttons["add song"].enabled = false
		Buttons["remove song"].enabled = false
		Buttons["save playlist"].enabled = false
		Buttons["shuffle"].enabled = false
	}
}
