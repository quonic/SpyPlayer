package main

import "base:intrinsics"
import "core:fmt"
import "core:math"
import "core:strings"
import "vendor:raylib"

Labels: map[string]^LabelControl
Buttons: map[string]^ButtonControl
Sliders: map[string]^SliderControl
Spinners: map[string]^SpinnerControl
Toggles: map[string]^ToggleControl
Texts: map[string]^TextControl
ProgressBars: map[string]^ProgressBarControl
Lists: map[string]^ListControl
AudioVisualizers: map[string]^AudioVisualizerControl
Pictures: map[string]^PictureControl

AddAudioVisualizer :: proc(audioVisualizer: ^AudioVisualizerControl) -> bool {
	if audioVisualizer.name == "" {
		return false
	}
	AudioVisualizers[audioVisualizer.name] = audioVisualizer
	return true
}

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

AddList :: proc(list: ^ListControl) -> bool {
	if list.name == "" {
		return false
	}
	Lists[list.name] = list
	return true
}

AddPicture :: proc(picture: ^PictureControl) -> bool {
	if picture.name == "" {
		return false
	}
	Pictures[picture.name] = picture
	return true
}

ClearList :: proc(list: ^ListControl) {
	list.items = nil
}

CleanUpControls :: proc() {
	for name, _ in Lists {
		delete(Lists[name].items)
	}
	delete_map(Lists)
	delete_map(ProgressBars)
	delete_map(Sliders)
	delete_map(Spinners)
	delete_map(Toggles)
	delete_map(Texts)
	delete_map(Buttons)
	delete_map(Labels)
}

IsHovering :: proc(box: raylib.Rectangle, camera: raylib.Camera2D) -> bool {
	return raylib.CheckCollisionPointRec(
		raylib.GetScreenToWorld2D(raylib.GetMousePosition(), camera),
		box,
	)
}

DrawAudioVisualizerControl :: proc(name: string, camera: raylib.Camera2D) {
	texture: raylib.Texture2D = AudioVisualizers[name].texture
	sourceRec: raylib.Rectangle = AudioVisualizers[name].positionSpriteSheet
	tint: raylib.Color =
		AudioVisualizers[name].enabled ? AudioVisualizers[name].tint_normal : AudioVisualizers[name].tint_disabled

	// Draw the background image
	raylib.DrawTexturePro(texture, sourceRec, AudioVisualizers[name].positionRec, {0, 0}, 0, tint)

	// If the left channel bars array is empty, return and draw nothing
	if len(AudioVisualizers[name].leftChannelBars) == 0 {
		return
	}

	// Width of the control minus the borders
	Width := int(AudioVisualizers[name].positionRec.width) - 2
	// Half the height of the control minus the borders
	Height := (AudioVisualizers[name].positionRec.height * 0.5) - 2
	// Border width
	boarder: f32 = 1

	barCount := 0
	color := raylib.BLACK
	// Don't check bounds as we are doing our own bounds checking
	#no_bounds_check {
		for _, i in AudioVisualizers[name].leftChannelBars[:audioPeriod] {
			// Only do act every time the audio period is divisible by the width of the control (Width)
			if i % int(audioPeriod / Width) == 0 {
				// Average the left and right channel bars to fit with in the control
				averageLeft: f32
				averageRight: f32
				// Make sure that we are not drawing outside the control positionRec width
				if i + Width > len(AudioVisualizers[name].leftChannelBars) {
					averageLeft =
						math.sum(AudioVisualizers[name].leftChannelBars[i:audioPeriod]) /
						f32(len(AudioVisualizers[name].leftChannelBars[i:audioPeriod]))
					averageRight =
						math.sum(AudioVisualizers[name].rightChannelBars[i:audioPeriod]) /
						f32(len(AudioVisualizers[name].rightChannelBars[i:audioPeriod]))
				} else {
					averageLeft =
						math.sum(AudioVisualizers[name].leftChannelBars[i:i + Width]) /
						f32(len(AudioVisualizers[name].leftChannelBars[i:i + Width]))
					averageRight =
						math.sum(AudioVisualizers[name].rightChannelBars[i:i + Width]) /
						f32(len(AudioVisualizers[name].rightChannelBars[i:i + Width]))
				}
				// Make sure that Left is always positive
				averageLeft = math.abs(averageLeft)
				// Make sure that Right is always negative
				averageRight = math.abs(averageRight) * -1

				// x position of the current line
				x := i32(barCount) + i32(AudioVisualizers[name].positionRec.x + boarder)
				// Left Channel - Drawn from the top of the control, downwards
				raylib.DrawLine(
					x,
					i32(AudioVisualizers[name].positionRec.y + boarder),
					x,
					i32(
						AudioVisualizers[name].positionRec.y + boarder + f32(averageLeft * Height),
					),
					color,
				)
				// Right Channel - Drawn from the bottom of the control, upwards
				raylib.DrawLine(
					x,
					i32(
						AudioVisualizers[name].positionRec.y -
						boarder +
						AudioVisualizers[name].positionRec.height,
					),
					x,
					i32(
						AudioVisualizers[name].positionRec.y -
						boarder +
						AudioVisualizers[name].positionRec.height +
						f32(averageRight * Height),
					),
					color,
				)
				barCount = barCount + 1
			}
		}
	}
}

DrawPictureControl :: proc(name: string, camera: raylib.Camera2D) {
	// Assert that the control exists
	assert(Pictures[name] != {}, fmt.tprintf("Control %v does not exist", name))
	texture: raylib.Texture2D = Pictures[name].texture
	sourceRec: raylib.Rectangle = Pictures[name].positionSpriteSheet
	tint: raylib.Color =
		Pictures[name].enabled ? Pictures[name].tint_normal : Pictures[name].tint_disabled

	// Draw the background image
	raylib.DrawTexturePro(texture, sourceRec, Pictures[name].positionRec, {0, 0}, 0, tint)

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

	pos: raylib.Vector2
	if Texts[name].centered {
		pos = {
			Texts[name].positionRec.x +
			Texts[name].positionRec.width / 2 -
			MeasureTextDimensions(name, Texts[name].text).x / 2,
			Texts[name].positionRec.y +
			Texts[name].positionRec.height / 2 -
			MeasureTextDimensions(name, Texts[name].text).y / 2,
		}
	} else {
		pos = {Texts[name].positionRec.x + 2, Texts[name].positionRec.y + 1}
	}
	// Make sure the text fits in the control
	if MeasureTextDimensions(name, Texts[name].text).x > Texts[name].positionRec.width {
		text := string(Texts[name].text)
		for i := len(text) - 1; i >= 0; i -= 1 {
			text = text[:i]
			ctext := strings.clone_to_cstring(text)
			defer delete(ctext)
			if MeasureTextDimensions(name, ctext).x < Texts[name].positionRec.width {
				raylib.DrawTextEx(
					Texts[name].font,
					strings.clone_to_cstring(text, context.temp_allocator),
					pos,
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
			pos,
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
				Buttons[name].hovering = true
				ToolTipIsHovering = true
				ToolTipText = Buttons[name].tooltip
			}

		} else {
			// Normal state
			Buttons[name].pressed = false
			tint = Buttons[name].tint_normal
			Buttons[name].hovering = false
			ResetToolTip(Buttons[name])
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
	xPosMin := destRec.x + Sliders[name].sliderPositionInset
	xPosMax := destRec.x + destRec.width - Sliders[name].sliderPositionInset * 2

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

DrawListControl :: proc(name: string, camera: raylib.Camera2D) {
	// TODO: Rewrite this using similar logic as GuiListViewEx and GuiScrollBar
	// https://github.com/raysan5/raygui/blob/master/src/raygui.h#L3351
	// https://github.com/raysan5/raygui/blob/master/src/raygui.h#L5305

	// Assert that the control exists
	assert(Lists[name] != {}, fmt.tprintf("Control %v does not exist", name))
	if len(Lists[name].items) == 0 {return}

	texture: raylib.Texture2D = Lists[name].texture
	sourceRec: raylib.Rectangle = Lists[name].positionSpriteSheet
	tint: raylib.Color = Lists[name].enabled ? Lists[name].tint_normal : Lists[name].tint_disabled

	// Draw the background image
	raylib.DrawTexturePro(texture, sourceRec, Lists[name].positionRec, {0, 0}, 0, tint)

	list: [^]cstring = raw_data(Lists[name].items)
	_ = raylib.GuiListViewEx(
		{
			Lists[name].positionRec.x + 2,
			Lists[name].positionRec.y + 2,
			Lists[name].positionRec.width - 5,
			Lists[name].positionRec.height - 4,
		},
		list,
		i32(len(Lists[name].items)),
		&Lists[name].scrollIndex,
		&Lists[name].active,
		&Lists[name].focus,
	)
}

DrawScrollBar :: proc(
	bounds: raylib.Rectangle,
	indexValue: i32,
	minValue: i32,
	maxValue: i32,
	tint: raylib.Color = raylib.WHITE,
	scrollSpeed: i32 = 1,
	stateBar: i32 = 0, // 0 = normal, 1 = hover, 2 = pressed, 3 = disabled
	boarderWidth: i32 = 0,
	scrollSliderSize: i32 = 16,
	scrollPadding: i32 = 0,
) -> i32 {
	value: i32 = indexValue
	state: i32 = stateBar
	isVertical := bounds.height > bounds.width

	arrowsVisible: bool = false
	spinnerSize :=
		arrowsVisible ? (isVertical ? i32(bounds.width) - 2 * boarderWidth : i32(bounds.height) - 2 * boarderWidth) : 0
	arrowUpLeft: raylib.Rectangle
	arrowDownRight: raylib.Rectangle

	scrollbar: raylib.Rectangle

	slider: raylib.Rectangle

	if value > maxValue {
		value = maxValue
	}
	if value < minValue {
		value = minValue
	}
	valueRange := maxValue - minValue
	if valueRange <= 0 {
		valueRange = 1
	}

	sliderSize := scrollSliderSize
	if sliderSize < 1 {
		sliderSize = 1
	}

	arrowUpLeft = {
		bounds.x + f32(boarderWidth),
		bounds.y + f32(boarderWidth),
		f32(spinnerSize),
		f32(spinnerSize),
	}

	if isVertical {
		arrowDownRight = {
			bounds.x + f32(boarderWidth),
			bounds.y + bounds.height - f32(spinnerSize) - f32(boarderWidth),
			f32(spinnerSize),
			f32(spinnerSize),
		}
		scrollbar = {
			bounds.x + f32(boarderWidth + scrollPadding),
			arrowUpLeft.y + arrowUpLeft.height,
			bounds.width - f32(2 * boarderWidth - 2 * scrollPadding - spinnerSize),
			arrowUpLeft.height - 2 * f32(boarderWidth),
		}

		sliderSize = f32(sliderSize) >= scrollbar.height ? i32(scrollbar.height - 2) : sliderSize
		slider = {
			bounds.x + f32(boarderWidth + scrollPadding),
			scrollbar.y + f32(value - minValue) * (scrollbar.height - f32(sliderSize)),
			bounds.width - 2 * f32(boarderWidth + scrollPadding),
			f32(sliderSize),
		}
	} else // horizontal
	{
		arrowDownRight = {
			bounds.x + bounds.width - f32(spinnerSize) - f32(boarderWidth),
			bounds.y + f32(boarderWidth),
			f32(spinnerSize),
			f32(spinnerSize),
		}
		scrollbar = {
			arrowUpLeft.x + arrowUpLeft.width,
			bounds.y + f32(boarderWidth + scrollPadding),
			arrowUpLeft.width - arrowDownRight.width - 2 * f32(boarderWidth),
			bounds.height - f32(2 * boarderWidth + scrollPadding),
		}

		sliderSize = f32(sliderSize) >= scrollbar.width ? i32(scrollbar.width - 2) : sliderSize
		slider = {
			scrollbar.x + f32(value - minValue) * (scrollbar.width - f32(sliderSize)),
			bounds.y + f32(boarderWidth + scrollPadding),
			f32(sliderSize),
			bounds.height - 2 * f32(boarderWidth + scrollPadding),
		}
	}

	// Update control
	if state != 3 {
		mousePoint := raylib.GetMousePosition()
		if raylib.CheckCollisionPointRec(mousePoint, bounds) {
			state = 1 // hover / focused

			wheel := i32(raylib.GetMouseWheelMove())
			if wheel != 0 {{value += wheel}

				if raylib.IsMouseButtonDown(raylib.MouseButton.LEFT) {
					if raylib.CheckCollisionPointRec(mousePoint, arrowUpLeft) {
						value -= valueRange / scrollSpeed
					} else if raylib.CheckCollisionPointRec(mousePoint, arrowDownRight) {
						value += valueRange / scrollSpeed
					} else if !raylib.CheckCollisionPointRec(mousePoint, scrollbar) {
						if isVertical {
							value =
								i32(
									(mousePoint.y - scrollbar.y - slider.height / 2) *
									f32(valueRange),
								) /
									i32(scrollbar.height - slider.height) +
								minValue
						} else {
							value =
								i32(
									(mousePoint.x - scrollbar.x - slider.width / 2) *
									f32(valueRange),
								) /
									i32(scrollbar.width - slider.width) +
								minValue
						}
						state = 2 // pressed
					}
				}
			}
			state = 1
			if raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT) {
				state = 2
			}
		}
		if value > maxValue {
			value = maxValue
		}
		if value < minValue {
			value = minValue
		}
	}

	// Draw control
	raylib.DrawRectanglePro(bounds, raylib.Vector2{bounds.width, bounds.height}, 0, tint)

	raylib.DrawRectanglePro(
		scrollbar,
		raylib.Vector2{scrollbar.width, scrollbar.height},
		0,
		raylib.Fade(tint, 0.5),
	)
	raylib.DrawRectanglePro(
		slider,
		raylib.Vector2{slider.width, slider.height},
		0,
		raylib.Fade(tint, 0.5),
	)
	return value
}

DrawToggleControl :: proc(name: string, camera: raylib.Camera2D) {
	texture: raylib.Texture2D = Toggles[name].texture
	sourceRec: raylib.Rectangle = Toggles[name].positionSpriteSheet
	tint: raylib.Color
	destRec := raylib.Rectangle {
		Toggles[name].positionRec.x,
		Toggles[name].positionRec.y,
		Toggles[name].positionRec.width,
		Toggles[name].positionRec.height,
	}

	if Toggles[name].enabled {
		if IsHovering(destRec, camera) {
			if raylib.IsMouseButtonDown(raylib.MouseButton.LEFT) {
				// Pressed state
				Toggles[name].pressed = true
				tint = Toggles[name].tint_pressed
			} else if raylib.IsMouseButtonReleased(raylib.MouseButton.LEFT) {
				Toggles[name].pressed = false
				tint = Toggles[name].tint_normal
			} else {
				// Hover state
				Toggles[name].pressed = false
				tint = Toggles[name].tint_hover
				Toggles[name].hovering = true
				ToolTipIsHovering = true
				ToolTipText = Toggles[name].tooltip
			}
		} else {
			// Normal state
			Toggles[name].pressed = false
			tint = Toggles[name].tint_normal
			Toggles[name].hovering = false
			ResetToolTip(Toggles[name])
		}
	} else {
		// Disabled state
		tint = Toggles[name].tint_disabled
	}
	raylib.DrawTexturePro(texture, sourceRec, destRec, {0, 0}, 0, tint)
	if !Toggles[name].checked {
		raylib.DrawTexturePro(
			texture,
			Toggles[name].toggleTextureUnchecked,
			{
				destRec.x + Toggles[name].togglePositionOffset.x,
				destRec.y + Toggles[name].togglePositionOffset.y,
				Toggles[name].togglePositionOffset.width,
				Toggles[name].togglePositionOffset.height,
			},
			{0, 0},
			0,
			tint,
		)
	} else {
		raylib.DrawTexturePro(
			texture,
			Toggles[name].toggleTextureChecked,
			{
				destRec.x + Toggles[name].togglePositionOffset.x,
				destRec.y + Toggles[name].togglePositionOffset.y,
				Toggles[name].togglePositionOffset.width,
				Toggles[name].togglePositionOffset.height,
			},
			{0, 0},
			0,
			tint,
		)
	}
}

ToolTipDelay: i32 = 0
ToolTipDelayTimer: i32 = 0
ToolTipIsHovering: bool = false
ToolTipText: string

/*
```bash

# The text to display
text: string
# The x and y position of the tooltip
posx: int
posy: int
# The camera to use for drawing
camera: raylib.Camera2D
# The font to use for drawing
textFont: raylib.Font
# The font size to use for drawing
textFontSize: f32
# Whether the tooltip is currently hovering
isHovering: bool
# The delay, in frames, before the tooltip is displayed
delay: i32 = 60
```
*/
DrawToolTip :: proc(
	text: string,
	posx, posy: f32,
	camera: raylib.Camera2D,
	textFont: raylib.Font,
	textFontSize: f32,
	isHovering: bool,
	delay: i32 = 60,
) {
	posx := posx
	posy := posy
	ToolTipDelay = delay
	ToolTipText = text

	textOutput := strings.clone_to_cstring(text, context.temp_allocator)

	if isHovering {
		textDimentions := raylib.MeasureTextEx(textFont, textOutput, textFontSize, 1)
		if textDimentions.x < 0 {textDimentions.x = 0}
		if textDimentions.y < 0 {textDimentions.y = 0}
		if posx + textDimentions.x > f32(raylib.GetScreenWidth()) {
			posx = posx - textDimentions.x
		}
		if posx < 0 {
			posx = textDimentions.x / 2
		}
		if textDimentions.y > f32(raylib.GetScreenHeight()) {
			posy = posy - textDimentions.y
		} else {
			posy = posy - textDimentions.y
		}
		raylib.DrawRectangle(
			i32(posx),
			i32(posy),
			i32(textDimentions.x),
			i32(textDimentions.y),
			raylib.Color{0, 0, 0, 128},
		)
		raylib.DrawTextEx(
			textFont,
			textOutput,
			raylib.Vector2{posx, posy},
			textFontSize,
			1,
			raylib.WHITE,
		)
	}
}

ToolTippableControls :: union {
	ButtonControl,
	ToggleControl,
}

ResetToolTip :: proc(
	Control: $T,
) where intrinsics.type_is_struct(ButtonControl) ||
	intrinsics.type_is_struct(ToggleControl) {
	if ToolTipText != Control.name {
		ToolTipText = ""
		ToolTipDelayTimer = 0
		ToolTipIsHovering = false
	}
}

GetTogglePressedState :: proc(name: string) -> int {
	if Toggles[name].pressed {
		if !Toggles[name].wasPressed {
			Toggles[name].wasPressed = true
			return 1
		}
	} else {
		if Toggles[name].wasPressed {
			Toggles[name].wasPressed = false
			return 2
		}
	}
	return 0
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

MeasureTextDimensions :: proc(name: string, text: cstring) -> raylib.Vector2 {
	return raylib.MeasureTextEx(Texts[name].font, text, Texts[name].fontSize, Texts[name].spacing)
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
	centered:            bool,
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
	tooltip:             string,
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
	tooltip:             string,
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
	sliderPositionInset: f32,
	value:               f32,
	valueReturnCallback: proc(value: f32),
	tooltip:             string,
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
	Toggle_X,
	Toggle_Circle,
	Toggle_Check,
}

// ToggleControl is a control that can be used to display a toggle
ToggleControl :: struct {
	name:                   string,
	enabled:                bool,
	texture:                raylib.Texture2D,
	positionSpriteSheet:    raylib.Rectangle,
	pressed:                bool,
	tint_pressed:           raylib.Color,
	tint_normal:            raylib.Color,
	tint_hover:             raylib.Color,
	tint_disabled:          raylib.Color,
	toggleTextureUnchecked: raylib.Rectangle,
	toggleTextureChecked:   raylib.Rectangle,
	togglePositionOffset:   raylib.Rectangle,
	positionRec:            raylib.Rectangle,
	backgroundColor:        raylib.Color,
	borderColor:            raylib.Color,
	wasPressed:             bool,
	borderWidth:            i32,
	checked:                bool,
	shape:                  ToggleShape,
	checkColor:             raylib.Color,
	hovering:               bool,
	tooltip:                string,
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
	tooltip:         string,
}

// ListControl
ListControl :: struct {
	name:                string,
	enabled:             bool,
	positionRec:         raylib.Rectangle,
	text:                cstring,
	fontSize:            f32,
	textColor:           raylib.Color,
	centered:            bool,
	pressed:             bool,
	hovering:            bool,
	spacing:             f32,
	font:                raylib.Font,
	positionSpriteSheet: raylib.Rectangle,
	tint:                raylib.Color,
	tintSelected:        raylib.Color,
	texture:             raylib.Texture2D,
	tint_normal:         raylib.Color,
	tint_pressed:        raylib.Color,
	tint_hover:          raylib.Color,
	tint_disabled:       raylib.Color,
	items:               [dynamic]cstring, // The list of items to display. TODO: Might change to string
	scrollIndex:         i32, // The index of the currently selected item in the list
	active:              i32,
	focus:               i32,
	scrollbarVertical:   bool,
	scrollbarWidth:      f32,
	scrollSpeed:         i32,
	sliderSize:          f32,
	tooltip:             string,
}

AudioVisualizerControl :: struct {
	name:                string,
	enabled:             bool,
	positionRec:         raylib.Rectangle,
	leftChannelBars:     []f32,
	rightChannelBars:    []f32,
	barColors:           []raylib.Color,
	tint:                raylib.Color,
	texture:             raylib.Texture2D,
	positionSpriteSheet: raylib.Rectangle,
	tint_normal:         raylib.Color,
	tint_disabled:       raylib.Color,
	tooltip:             string,
}

PictureControl :: struct {
	name:                string,
	enabled:             bool,
	positionRec:         raylib.Rectangle,
	texture:             raylib.Texture2D,
	positionSpriteSheet: raylib.Rectangle,
	tint_normal:         raylib.Color,
	tint_disabled:       raylib.Color,
	tooltip:             string,
}
