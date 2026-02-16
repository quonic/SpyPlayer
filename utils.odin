package main

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/cmplx"
import "core:os"
import "core:path/filepath"
import fft "fft"

GetXdgConfigHome :: proc() -> (string, os.Error) {
	XDG_CONFIG_HOME := os.get_env("XDG_CONFIG_HOME", context.temp_allocator)
	if XDG_CONFIG_HOME != "" {
		return XDG_CONFIG_HOME, nil
	} else {
		home := os.get_env("HOME", context.temp_allocator)
		return filepath.join({home, ".config"}, context.temp_allocator)
	}
}

GetConfigFilePath :: proc() -> (string, os.Error) {
	XDG_CONFIG_HOME, err := GetXdgConfigHome()
	if err != nil {
		return "", err
	}
	return filepath.join({XDG_CONFIG_HOME, "SpyPlayer", "config.json"}, context.temp_allocator)
}

newTempFile :: proc(extension: string) -> (path: string, err: runtime.Allocator_Error) {
	when ODIN_OS == .Windows {
		return filepath.join(
			{
				os.get_env("TEMP", context.temp_allocator),
				fmt.aprintf("temp_spyplayer.%s", extension),
			},
		)
	} else when ODIN_OS == .Linux || ODIN_OS == .Darwin {
		return filepath.join(
			{"/tmp", fmt.aprintf("temp_spyplayer.%s", extension)},
			context.temp_allocator,
		)
	}
}

inv_size := (1.5 + math.log2(f32(FFT_SIZE))) / f32(FFT_SIZE) * 2

AudioProcessFFT :: proc "c" (bufferData: rawptr, frames: u32) {
	if bufferData == nil || frames == 0 {
		return
	}

	samples := ([^]f32)(bufferData)

	// Prepare FFT input buffers (mono: left and right)

	for i := 0; i < FFT_SIZE; i += 1 {
		idx := i * 2
		if idx + 1 < int(frames) * 2 {
			g_spectrumState.leftInput[i] = samples[idx]
			g_spectrumState.rightInput[i] = samples[idx + 1]
		} else {
			g_spectrumState.leftInput[i] = 0.0
			g_spectrumState.rightInput[i] = 0.0
		}
	}
}
