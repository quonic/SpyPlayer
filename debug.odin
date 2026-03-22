package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:os/old"
import "vendor:raylib"

page_size: int

update_page_size :: proc() {
	page_size = old.get_page_size()
}

last_memory_log_time: f64

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

	// About every minute, print memory usage to console
	if raylib.GetTime() - last_memory_log_time > 10.0 {
		fmt.printfln(
			"Current Memory Allocated: %.2f MB, Peak Memory Allocated: %.2f MB, Page Size: %d bytes",
			f32(tracking_allocator.current_memory_allocated) / (1024.0 * 1024.0),
			f32(tracking_allocator.peak_memory_allocated) / (1024.0 * 1024.0),
			page_size,
		)
		if len(tracking_allocator.bad_free_array) > 0 {
			fmt.printfln("Bad frees detected: %d", len(tracking_allocator.bad_free_array))
			for i in 0 ..< len(tracking_allocator.bad_free_array) {
				fmt.printfln(
					"  Bad free #%d: %v:%d:%d in %v, size: %d bytes",
					i,
					tracking_allocator.bad_free_array[i].location.file_path,
					tracking_allocator.bad_free_array[i].location.line,
					tracking_allocator.bad_free_array[i].location.column,
					tracking_allocator.bad_free_array[i].location.procedure,
					size_of(tracking_allocator.bad_free_array[i].memory),
				)
			}
		}
		last_memory_log_time = raylib.GetTime()
	}
}
