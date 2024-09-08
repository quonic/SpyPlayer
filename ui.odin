package main

import "aseprite"
import "core:fmt"
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

playlist_scrollbar: raylib.Rectangle
playlist_minus_button: raylib.Rectangle
playlist_position_button: raylib.Rectangle
playlist_plus_button: raylib.Rectangle
playlist_background: raylib.Rectangle


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
		color := slice.color
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
				}
			case "eq":
				eq_slider = {
					name = "eq",
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
				}
			case "meter":
				meter_slider = {
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
					tint_normal = raylib.WHITE,
					tint_pressed = raylib.LIGHTGRAY,
					tint_hover = raylib.GRAY,
					tint_disabled = raylib.DARKGRAY,
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
			}
			AddButton(&previous_button)
			AddButton(&play_button)
			AddButton(&pause_button)
			AddButton(&next_button)
			AddButton(&stop_button)
			AddSlider(&volume_slider)
			// AddSlider(&eq_slider)
			// AddSlider(&meter_slider)
			AddButton(&load_button)
			AddSlider(&seek_bar)
			AddList(&playlist_list)
			AddText(&current_song_text)

			AddText(&song_length_text)
			AddText(&play_time_text)
		}
	}
}

UserInterface :: proc() {
	DrawButtons()
	DrawSliders()
	DrawLists()
	DrawTexts()
	HandleButtonActions()
}

DrawButtons :: proc() {
	DrawButtonControl("previous", camera)
	DrawButtonControl("play", camera)
	DrawButtonControl("pause", camera)
	DrawButtonControl("next", camera)
	DrawButtonControl("stop", camera)
	DrawButtonControl("load", camera)
}

DrawSliders :: proc() {
	DrawSliderControl("volume", camera)
	DrawSliderControl("seek bar", camera)
	// DrawSliderControl("eq_slider", camera)
	// DrawSliderControl("meter_slider", camera)
}

DrawTexts :: proc() {
	DrawTextControl("current song", camera)
	DrawTextControl("song length", camera)
	DrawTextControl("play time", camera)
}

DrawLists :: proc() {
	DrawListControl("playlist", camera)
}

HandleButtonActions :: proc() {
	if GetButtonPressedState("load") == 1 {
		load()
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
	} else {
		Buttons["previous"].enabled = false
		Buttons["play"].enabled = false
		Buttons["pause"].enabled = false
		Buttons["next"].enabled = false
		Buttons["stop"].enabled = false
		Sliders["volume"].enabled = false
		Sliders["seek bar"].enabled = false
	}
}
