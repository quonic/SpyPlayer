package aseprite

import "core:encoding/json"
import "core:fmt"
import "core:os"

Aseprite :: struct {
	frames: map[string]Frame,
	meta:   Meta,
}

Meta :: struct {
	app:     string,
	version: string,
	image:   string,
	format:  string,
	size:    Size,
	scale:   f32,
	slices:  [dynamic]Slice,
}

Frame :: struct {
	frame:            Bounds,
	rotated:          bool,
	trimmed:          bool,
	spriteSourceSize: Bounds,
	sourceSize:       Size,
	duration:         int,
}

Slice :: struct {
	name:  string,
	color: string,
	keys:  [dynamic]Key,
}

Key :: struct {
	frame:  int,
	bounds: Bounds,
}

Bounds :: struct {
	x: f32,
	y: f32,
	w: f32,
	h: f32,
}

Size :: struct {
	w: int,
	h: int,
}


ReadAsespriteJsonFile :: proc(
	filename: string,
	allocator := context.allocator,
) -> (
	aseprite: ^Aseprite,
	ok: bool,
) {
	data := os.read_entire_file(filename) or_return
	defer delete(data)

	aseprite = new(Aseprite)
	err := json.unmarshal(data, aseprite)
	assert(err == nil, fmt.tprintf("Error: %v", err))
	ok = err == nil
	return
}

import "core:testing"

@(test)
test_read_aseprite_json_file :: proc(_: ^testing.T) {
	// Note: Replace with your own test data or remove this test
	// I've created this test for validating the parser in my own project
	test_file := "assets/window.json"
	test_aseprite, ok := ReadAsespriteJsonFile(test_file)
	if ok == false && test_aseprite != nil {
		assert(test_aseprite.frames["window.aseprite"].frame.x == 0)
		assert(test_aseprite.frames["window.aseprite"].frame.y == 0)
		assert(test_aseprite.frames["window.aseprite"].frame.w == 600)
		assert(test_aseprite.frames["window.aseprite"].frame.h == 200)
		assert(test_aseprite.frames["window.aseprite"].rotated == false)
		assert(test_aseprite.frames["window.aseprite"].trimmed == false)
		assert(test_aseprite.frames["window.aseprite"].spriteSourceSize.x == 0)
		assert(test_aseprite.frames["window.aseprite"].spriteSourceSize.y == 0)
		assert(test_aseprite.frames["window.aseprite"].spriteSourceSize.w == 600)
		assert(test_aseprite.frames["window.aseprite"].spriteSourceSize.h == 200)
		assert(test_aseprite.frames["window.aseprite"].sourceSize.w == 600)
		assert(test_aseprite.frames["window.aseprite"].sourceSize.h == 200)
		assert(test_aseprite.frames["window.aseprite"].duration == 100)

		assert(test_aseprite.meta.app == "http://www.aseprite.org/")
		// assert(test_aseprite.meta.version == "1.3.8.1-x64") // Version will change, was tested with Aseprite 1.3.8.1-x64
		assert(test_aseprite.meta.image == "window.png")
		assert(test_aseprite.meta.format == "RGBA8888")
		assert(test_aseprite.meta.size.w == 600)
		assert(test_aseprite.meta.size.h == 200)
		assert(test_aseprite.meta.scale == 1)
		assert(test_aseprite.meta.slices[0].name == "previous")
		assert(test_aseprite.meta.slices[0].color == "#0000ffff")
		assert(test_aseprite.meta.slices[0].keys[0].frame == 0)
		assert(test_aseprite.meta.slices[0].keys[0].bounds.x == 6)
		assert(test_aseprite.meta.slices[0].keys[0].bounds.y == 145)
		assert(test_aseprite.meta.slices[0].keys[0].bounds.w == 50)
		assert(test_aseprite.meta.slices[0].keys[0].bounds.h == 50)
	} else {
		assert(false, "Error reading file")
	}
}
