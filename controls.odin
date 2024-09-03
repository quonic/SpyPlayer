package main

import "core:fmt"
import "core:strings"
import "vendor:raylib"

Labels: map[string]^LabelControl
Buttons: map[string]^ButtonControl
Sliders: map[string]^SliderControl
Spinners: map[string]^SpinnerControl
Toggles: map[string]^ToggleControl
Texts: map[string]^TextControl
ProgressBars: map[string]^ProgressBarControl


AddLabel :: proc(label: ^LabelControl) -> bool {
	if label.name != "" || Labels[label.name] == nil {
		return false
	}
	Labels[label.name] = label
	return true
}

AddButton :: proc(button: ^ButtonControl) -> bool {
	if button.name == "" {
		return false
	}
	Buttons[button.name] = button
	return true
}

AddSlider :: proc(slider: ^SliderControl) -> bool {
	if slider.name == "" {
		return false
	}
	Sliders[slider.name] = slider
	return true
}

AddSpinner :: proc(spinner: ^SpinnerControl) -> bool {
	if spinner.name == "" {
		return false
	}
	Spinners[spinner.name] = spinner
	return true
}

AddToggle :: proc(toggle: ^ToggleControl) -> bool {
	if toggle.name == "" {
		return false
	}
	Toggles[toggle.name] = toggle
	return true
}

AddText :: proc(text: ^TextControl) -> bool {
	if text.name == "" {
		return false
	}
	Texts[text.name] = text
	return true
}

AddProgressBar :: proc(progressBar: ^ProgressBarControl) -> bool {
	if progressBar.name == "" {
		return false
	}
	ProgressBars[progressBar.name] = progressBar
	return true
}

IsHovering :: proc(box: raylib.Rectangle, camera: raylib.Camera2D) -> bool {
	return raylib.CheckCollisionPointRec(
		raylib.GetScreenToWorld2D(raylib.GetMousePosition(), camera),
		box,
	)
}

DrawLabelControl :: proc(name: string) {
	raylib.DrawTextEx(
		Labels[name].font,
		Labels[name].text,
		{Labels[name].positionRec.x + 2, Labels[name].positionRec.y + 1},
		Labels[name].fontSize,
		0,
		Labels[name].textColor,
	)
}

DrawTextControl :: proc(name: string, camera: raylib.Camera2D) {
	// Assert that the control exists
	assert(Texts[name] != {}, fmt.tprintf("Control %v does not exist", name))
	texture: raylib.Texture2D = Texts[name].texture
	sourceRec: raylib.Rectangle = Texts[name].positionSpriteSheet
	tint: raylib.Color = Texts[name].enabled ? Texts[name].tint_normal : Texts[name].tint_disabled
	if Texts[name].enabled {
		if IsHovering(Texts[name].positionRec, camera) {
			if raylib.IsMouseButtonDown(raylib.MouseButton.LEFT) {
				// Pressed state
				Texts[name].pressed = true
			} else if raylib.IsMouseButtonReleased(raylib.MouseButton.LEFT) {
				Texts[name].pressed = false
			} else {
				// Hover state
				Texts[name].pressed = false
			}

		} else {
			// Normal state
			Texts[name].pressed = false
		}
	} else {
		// Disabled state
	}

	raylib.DrawTexturePro(texture, sourceRec, Texts[name].positionRec, {0, 0}, 0, tint)

	// Make sure the text fits in the control
	if MeasureTextLength(name, Texts[name].text) > Texts[name].positionRec.width {
		text := string(Texts[name].text)
		for i := len(text) - 1; i >= 0; i -= 1 {
			text = text[:i]
			if MeasureTextLength(name, strings.clone_to_cstring(text)) <
			   Texts[name].positionRec.width {
				raylib.DrawTextEx(
					Texts[name].font,
					strings.clone_to_cstring(text),
					{Texts[name].positionRec.x + 2, Texts[name].positionRec.y + 1},
					Texts[name].fontSize,
					Texts[name].spacing,
					Texts[name].textColor,
				)
				break
			}
		}

	} else {
		raylib.DrawTextEx(
			Texts[name].font,
			Texts[name].text,
			{Texts[name].positionRec.x + 2, Texts[name].positionRec.y + 1},
			Texts[name].fontSize,
			Texts[name].spacing,
			Texts[name].textColor,
		)
	}
}

DrawButtonControl :: proc(name: string, camera: raylib.Camera2D) {
	texture: raylib.Texture2D = Buttons[name].texture
	sourceRec: raylib.Rectangle = Buttons[name].positionSpriteSheet
	tint: raylib.Color

	if Buttons[name].enabled {
		if IsHovering(Buttons[name].positionRec, camera) {
			if raylib.IsMouseButtonDown(raylib.MouseButton.LEFT) {
				// Pressed state
				Buttons[name].pressed = true
				tint = Buttons[name].tint_pressed
			} else if raylib.IsMouseButtonReleased(raylib.MouseButton.LEFT) {
				Buttons[name].pressed = false
				tint = Buttons[name].tint_normal
			} else {
				// Hover state
				Buttons[name].pressed = false
				tint = Buttons[name].tint_hover
			}

		} else {
			// Normal state
			Buttons[name].pressed = false
			tint = Buttons[name].tint_normal
		}
	} else {
		// Disabled state
		tint = Buttons[name].tint_disabled
	}

	raylib.DrawTexturePro(texture, sourceRec, Buttons[name].positionRec, {0, 0}, 0, tint)

}

DrawSliderControl :: proc(name: string, camera: raylib.Camera2D) {

	// Assert that the control exists
	assert(Sliders[name] != {}, fmt.tprintf("Control %v does not exist", name))
	texture: raylib.Texture2D = Sliders[name].texture
	sourceRec: raylib.Rectangle = Sliders[name].positionSpriteSheet
	tint: raylib.Color
	destRec := raylib.Rectangle {
		Sliders[name].positionRec.x,
		Sliders[name].positionRec.y,
		Sliders[name].positionRec.width,
		Sliders[name].positionRec.height,
	}
	xPosMin := destRec.x + 6
	xPosMax := destRec.x + destRec.width - 12

	if Sliders[name].enabled {
		if IsHovering(destRec, camera) {
			if raylib.IsMouseButtonDown(raylib.MouseButton.LEFT) {
				// Pressed state
				Sliders[name].pressed = true
				tint = Sliders[name].tint_pressed

				mousePos := raylib.GetScreenToWorld2D(raylib.GetMousePosition(), camera)
				if mousePos.x < xPosMin {
					Sliders[name].sliderPosition = xPosMin
				} else if mousePos.x > xPosMax {
					Sliders[name].sliderPosition = xPosMax
				} else {
					Sliders[name].sliderPosition = mousePos.x
				}
				// Save value
				Sliders[name].value =
					(Sliders[name].sliderPosition - xPosMin) / (xPosMax - xPosMin)
				if Sliders[name].valueReturnCallback != nil {
					Sliders[name].valueReturnCallback(Sliders[name].value)
				}
			} else if raylib.IsMouseButtonReleased(raylib.MouseButton.LEFT) {
				Sliders[name].pressed = false
				tint = Sliders[name].tint_normal
			} else {
				// Hover state
				Sliders[name].pressed = false
				tint = Sliders[name].tint_hover
				// Update slider position based on value
				Sliders[name].sliderPosition =
					(Sliders[name].value * (xPosMax - xPosMin)) + xPosMin
			}
		} else {
			// Normal state
			Sliders[name].pressed = false
			tint = Sliders[name].tint_normal
			// Update slider position based on value
			Sliders[name].sliderPosition = (Sliders[name].value * (xPosMax - xPosMin)) + xPosMin
		}
	} else {
		// Disabled state
		tint = Sliders[name].tint_disabled
		// Update slider position based on value
		Sliders[name].sliderPosition = (Sliders[name].value * (xPosMax - xPosMin)) + xPosMin
	}

	raylib.DrawTexturePro(texture, sourceRec, destRec, {0, 0}, 0, Sliders[name].tint_normal)
	raylib.DrawTexturePro(
		texture,
		Sliders[name].slider.sourceRec,
		{
			Sliders[name].sliderPosition,
			destRec.y +
			Sliders[name].positionRec.height / 2 -
			Sliders[name].slider.sourceRec.height / 2,
			Sliders[name].slider.sourceRec.width,
			Sliders[name].slider.sourceRec.height,
		},
		{0, 0},
		0,
		tint,
	)

}

DrawSpinnerControl :: proc(control: ^SpinnerControl) {
	mp := raylib.GetMousePosition()
	mousePos: [2]i32 = {cast(i32)mp.x, cast(i32)mp.y}
	if mousePos.x >= control.x &&
	   mousePos.x <= control.x + control.w &&
	   mousePos.y >= control.y &&
	   mousePos.y <= control.y + control.h {
		control.hoverAction(control)
	}

	if control.enabled {
		if raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT) {
			control.clickAction(control)
		}
		// Draw background
		raylib.DrawRectangle(control.x, control.y, control.w, control.h, control.backgroundColor)
		// Draw border
		raylib.DrawRectangleLinesEx(
			raylib.Rectangle {
				cast(f32)control.x,
				cast(f32)control.y,
				cast(f32)control.w,
				cast(f32)control.h,
			},
			cast(f32)control.borderWidth,
			control.borderColor,
		)

	} else {
		// Draw background
		raylib.DrawRectangle(
			control.x,
			control.y,
			control.w,
			control.h,
			raylib.Fade(control.backgroundColor, 0.5),
		)
		// Draw border
		raylib.DrawRectangleLinesEx(
			raylib.Rectangle {
				cast(f32)control.x,
				cast(f32)control.y,
				cast(f32)control.w,
				cast(f32)control.h,
			},
			cast(f32)control.borderWidth,
			raylib.Fade(control.borderColor, 0.5),
		)
	}
}

DrawToggleControl :: proc(control: ^ToggleControl) {
	mp := raylib.GetMousePosition()
	mousePos: [2]i32 = {cast(i32)mp.x, cast(i32)mp.y}
	if mousePos.x >= control.x &&
	   mousePos.x <= control.x + control.w &&
	   mousePos.y >= control.y &&
	   mousePos.y <= control.y + control.h {
		control.hoverAction(control)
	}

	if control.enabled {
		if raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT) {
			control.clickAction(control)
		}
		// Draw background
		raylib.DrawRectangle(control.x, control.y, control.w, control.h, control.backgroundColor)
		// Draw border
		raylib.DrawRectangleLinesEx(
			raylib.Rectangle {
				cast(f32)control.x,
				cast(f32)control.y,
				cast(f32)control.w,
				cast(f32)control.h,
			},
			cast(f32)control.borderWidth,
			control.borderColor,
		)

	} else {
		// Draw background
		raylib.DrawRectangle(
			control.x,
			control.y,
			control.w,
			control.h,
			raylib.Fade(control.backgroundColor, 0.5),
		)
		// Draw border
		raylib.DrawRectangleLinesEx(
			raylib.Rectangle {
				cast(f32)control.x,
				cast(f32)control.y,
				cast(f32)control.w,
				cast(f32)control.h,
			},
			cast(f32)control.borderWidth,
			raylib.Fade(control.borderColor, 0.5),
		)
	}
}

DrawProgressBarControl :: proc(control: ^ProgressBarControl) {
	mp := raylib.GetMousePosition()
	mousePos: [2]i32 = {cast(i32)mp.x, cast(i32)mp.y}
	if mousePos.x >= control.x &&
	   mousePos.x <= control.x + control.w &&
	   mousePos.y >= control.y &&
	   mousePos.y <= control.y + control.h {
		control.hoverAction(control)
	}

	if control.enabled {
		if raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT) {
			control.clickAction(control)
		}
		// Draw background
		raylib.DrawRectangle(control.x, control.y, control.w, control.h, control.backgroundColor)
		// Draw border
		raylib.DrawRectangleLinesEx(
			raylib.Rectangle {
				cast(f32)control.x,
				cast(f32)control.y,
				cast(f32)control.w,
				cast(f32)control.h,
			},
			cast(f32)control.borderWidth,
			control.borderColor,
		)

	} else {
		// Draw background
		raylib.DrawRectangle(
			control.x,
			control.y,
			control.w,
			control.h,
			raylib.Fade(control.backgroundColor, 0.5),
		)
		// Draw border
		raylib.DrawRectangleLinesEx(
			raylib.Rectangle {
				cast(f32)control.x,
				cast(f32)control.y,
				cast(f32)control.w,
				cast(f32)control.h,
			},
			cast(f32)control.borderWidth,
			raylib.Fade(control.borderColor, 0.5),
		)
	}
}

GetButtonPressedState :: proc(name: string) -> int {
	if Buttons[name].pressed {
		if !Buttons[name].wasPressed {
			Buttons[name].wasPressed = true
			return 1
		}
	} else {
		if Buttons[name].wasPressed {
			Buttons[name].wasPressed = false
			return 2
		}
	}
	return 0
}

MeasureTextLength :: proc(name: string, text: cstring) -> f32 {
	return(
		raylib.MeasureTextEx(Texts[name].font, text, Texts[name].fontSize, Texts[name].spacing).x \
	)
}


// Control that can be used to display text
LabelControl :: struct {
	name:        string,
	positionRec: raylib.Rectangle,
	text:        cstring,
	fontSize:    f32,
	textColor:   raylib.Color,
	scrolling:   bool,
	font:        raylib.Font,
	pressed:     bool,
	wasPressed:  bool,
	hovering:    bool,
}

// TextControl is a control that can be used to enter text
TextControl :: struct {
	name:                string,
	enabled:             bool,
	text:                cstring,
	font:                raylib.Font,
	fontSize:            f32,
	spacing:             f32,
	textColor:           raylib.Color,
	positionRec:         raylib.Rectangle,
	backgroundColor:     raylib.Color,
	borderColor:         raylib.Color,
	borderWidth:         i32,
	pressed:             bool,
	hovering:            bool,
	scrolling:           bool,
	tint:                raylib.Color,
	texture:             raylib.Texture2D,
	tint_normal:         raylib.Color,
	tint_pressed:        raylib.Color,
	tint_hover:          raylib.Color,
	tint_disabled:       raylib.Color,
	positionSpriteSheet: raylib.Rectangle,
	wasPressed:          bool,
}

// ButtonControl is a control that can be used to display a button
ButtonControl :: struct {
	name:                string,
	enabled:             bool,
	positionRec:         raylib.Rectangle,
	backgroundColor:     raylib.Color,
	borderColor:         raylib.Color,
	borderWidth:         i32,
	pressed:             bool,
	hovering:            bool,
	text:                cstring,
	font:                raylib.Font,
	tint:                raylib.Color,
	texture:             raylib.Texture2D,
	tint_normal:         raylib.Color,
	tint_pressed:        raylib.Color,
	tint_hover:          raylib.Color,
	tint_disabled:       raylib.Color,
	positionSpriteSheet: raylib.Rectangle,
	wasPressed:          bool,
}

// SliderControl is a control that can be used to display a slider
SliderControl :: struct {
	name:                string,
	enabled:             bool,
	positionRec:         raylib.Rectangle,
	pressed:             bool,
	hovering:            bool,
	tint:                raylib.Color,
	texture:             raylib.Texture2D,
	tint_normal:         raylib.Color,
	tint_pressed:        raylib.Color,
	tint_hover:          raylib.Color,
	tint_disabled:       raylib.Color,
	positionSpriteSheet: raylib.Rectangle,
	wasPressed:          bool,
	sliderPosition:      f32,
	slider:              SliderBar,
	value:               f32,
	valueReturnCallback: proc(value: f32),
}

SliderBar :: struct {
	sourceRec:      raylib.Rectangle,
	sliderPosition: raylib.Rectangle,
}

// SpinnerControl is a control that can be used to display a spinner
SpinnerControl :: struct {
	name:            string,
	enabled:         bool,
	x, y, w, h:      i32,
	backgroundColor: raylib.Color,
	borderColor:     raylib.Color,
	borderWidth:     i32,
	value:           i32,
	minValue:        i32,
	maxValue:        i32,
	barColor:        raylib.Color,
	clickAction:     proc(this: ^SpinnerControl),
	hoverAction:     proc(this: ^SpinnerControl),
}

// ToggleShape is an enum that represents the shape of the toggle
ToggleShape :: enum {
	Toggle_Square,
	Toggle_Circle,
}

// ToggleControl is a control that can be used to display a toggle
ToggleControl :: struct {
	name:            string,
	enabled:         bool,
	x, y, w, h:      i32,
	backgroundColor: raylib.Color,
	borderColor:     raylib.Color,
	borderWidth:     i32,
	checked:         bool,
	shape:           ToggleShape,
	checkColor:      raylib.Color,
	clickAction:     proc(this: ^ToggleControl),
	hoverAction:     proc(this: ^ToggleControl),
}

// ProgressBarControl is a control that can be used to display a progress bar
ProgressBarControl :: struct {
	name:            string,
	enabled:         bool,
	x, y, w, h:      i32,
	backgroundColor: raylib.Color,
	borderColor:     raylib.Color,
	borderWidth:     i32,
	value:           f32,
	minValue:        f32,
	maxValue:        f32,
	barColor:        raylib.Color,
	clickAction:     proc(this: ^ProgressBarControl),
	hoverAction:     proc(this: ^ProgressBarControl),
}
