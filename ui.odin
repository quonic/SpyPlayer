package main

import "aseprite"
import "core:encoding/json"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:time"
import "ffprobe"
import "vendor:raylib"

window_texture: raylib.Texture2D
previous_button: ButtonControl
play_button: ButtonControl
pause_button: ButtonControl
next_button: ButtonControl
stop_button: ButtonControl
close_button: ButtonControl
min_button: ButtonControl
menu_button: ButtonControl
current_song_text: TextControl
volume_slider: SliderControl
eq_slider: SliderControl
meter_slider: SliderControl
load_button: ButtonControl
seek_bar: SliderControl
seek_time_left_text: TextControl
seek_time_current_text: TextControl
playlist_text: TextControl
slider_bar: raylib.Rectangle

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
			case "close":
				close_button = {
					name = "close",
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
			case "min":
				min_button = {
					name = "min",
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
			case "menu":
				menu_button = {
					name = "menu",
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
					textColor = raylib.DARKGRAY,
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
			case "seek time left":
				seek_time_left_text = {
					name = "seek time left",
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
			case "seek time current":
				seek_time_current_text = {
					name = "seek time current",
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
			case "playlist":
				playlist_text = {
					name = "playlist",
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
			}
			AddButton(&previous_button)
			AddButton(&play_button)
			AddButton(&pause_button)
			AddButton(&next_button)
			AddButton(&stop_button)
			AddButton(&close_button)
			AddButton(&min_button)
			AddButton(&menu_button)
			AddText(&current_song_text)
			AddSlider(&volume_slider)
			AddSlider(&eq_slider)
			AddSlider(&meter_slider)
			AddButton(&load_button)
			AddSlider(&seek_bar)
			AddText(&seek_time_left_text)
			AddText(&seek_time_current_text)
			AddText(&playlist_text)
		}
	}
}

UserInterface :: proc() {
	DrawButtons()
	DrawSliders()
	DrawTexts()
	HandleButtonActions()
	HandleSliderValues()
}

DrawButtons :: proc() {
	DrawButtonControl("previous", camera)
	DrawButtonControl("play", camera)
	DrawButtonControl("pause", camera)
	DrawButtonControl("next", camera)
	DrawButtonControl("stop", camera)
	DrawButtonControl("load", camera)
	DrawButtonControl("close", camera)
	DrawButtonControl("min", camera)
	DrawButtonControl("menu", camera)
}

DrawSliders :: proc() {
	DrawSliderControl("volume", camera)
	// DrawSliderControl("eq_slider", camera)
	// DrawSliderControl("meter_slider", camera)
}

DrawTexts :: proc() {
	DrawTextControl("current song", camera)
	// DrawTextControl("seek time left", camera)
	// DrawTextControl("seek time current", camera)
	// DrawTextControl("playlist", camera)
}

HandleSliderValues :: proc() {
	raylib.SetMusicVolume(currentStream, Sliders["volume"].value)
}

HandleButtonActions :: proc() {
	if GetButtonPressedState("load") == 1 {
		fmt.println("load")
		load()
	}
	if GetButtonPressedState("menu") == 1 {
		fmt.println("menu")
	}
	if GetButtonPressedState("close") == 1 {
		fmt.println("close")
		raylib.CloseWindow()
		os.exit(0)
	}
	if GetButtonPressedState("min") == 1 {
		fmt.println("min")
		raylib.MinimizeWindow()
	}
	if playListLoaded {
		if Buttons["play"].enabled == false {
			Buttons["previous"].enabled = true
			Buttons["play"].enabled = true
			Buttons["pause"].enabled = true
			Buttons["next"].enabled = true
			Buttons["stop"].enabled = true
			Sliders["volume"].enabled = true
		}
		if GetButtonPressedState("previous") == 1 {
			fmt.println("Previous")
			previous()
		}
		if GetButtonPressedState("play") == 1 {
			fmt.println("Play")
			play()
		}
		if GetButtonPressedState("pause") == 1 {
			fmt.println("Pause")
			pause()
		}
		if GetButtonPressedState("next") == 1 {
			fmt.println("Next")
			next()
		}
		if GetButtonPressedState("stop") == 1 {
			fmt.println("Stop")
			stop()
		}
	} else {
		Buttons["previous"].enabled = false
		Buttons["play"].enabled = false
		Buttons["pause"].enabled = false
		Buttons["next"].enabled = false
		Buttons["stop"].enabled = false
		Sliders["volume"].enabled = false
	}
}
