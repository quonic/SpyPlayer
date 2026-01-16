package main

import "core:fmt"
import "core:mem"
import "core:os"
import "vendor:raylib"

page_size: int

update_page_size :: proc() {
	page_size = os.get_page_size()
}

debug_draw :: proc(tracking_allocator: ^mem.Tracking_Allocator) {
	// FPS Counter
	raylib.DrawText(fmt.caprintf("FPS: %d", raylib.GetFPS()), 10, 10, 20, raylib.RED)

	// Draw memory usage
	raylib.DrawText(
		fmt.caprintf(
			"Cur Mem Alloc: %.2f MB",
			f32(tracking_allocator.current_memory_allocated) / (1024.0 * 1024.0),
		),
		10,
		30,
		20,
		raylib.RED,
	)
	raylib.DrawText(
		fmt.caprintf(
			"Peak Mem Alloc: %.2f MB",
			f32(tracking_allocator.peak_memory_allocated) / (1024.0 * 1024.0),
		),
		10,
		50,
		20,
		raylib.RED,
	)
	raylib.DrawText(fmt.caprintf("Page Size: %d", page_size), 10, 70, 20, raylib.RED)
}
