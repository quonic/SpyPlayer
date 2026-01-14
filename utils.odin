package main

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/cmplx"
import "core:os"
import "core:path/filepath"
import fft "fft"

GetXdgConfigHome :: proc() -> (string, os.Error) {
	XDG_CONFIG_HOME := os.get_env("XDG_CONFIG_HOME")
	if XDG_CONFIG_HOME != "" {
		return XDG_CONFIG_HOME, nil
	} else {
		return filepath.join({os.get_env("HOME"), ".config"})
	}
}

GetConfigFilePath :: proc() -> (string, os.Error) {
	XDG_CONFIG_HOME, err := GetXdgConfigHome()
	if err != nil {
		return "", err
	}
	return filepath.join({XDG_CONFIG_HOME, "SpyPlayer", "config.json"}), nil
}

newTempFile :: proc(extension: string) -> string {
	when ODIN_OS == .Windows {
		return filepath.join({os.get_env("TEMP"), fmt.aprintf("temp_spyplayer.%s", extension)})
	} else when ODIN_OS == .Linux || ODIN_OS == .Darwin {
		return filepath.join({"/tmp", fmt.aprintf("temp_spyplayer.%s", extension)})
	}
}

AudioProcessFFT :: proc "c" (bufferData: rawptr, frames: u32) {
	if bufferData == nil || frames == 0 {
		return
	}

	samples := ([^]f32)(bufferData)
	inv_size := (1.5 + math.log2(f32(FFT_SIZE))) / f32(FFT_SIZE) * 2

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

	// Run FFT on left channel and compute its power spectrum
	fft.run_fft_plan(g_spectrumState.plan, g_spectrumState.leftInput[:])

	// Compute power spectrum for left channel
	for i := 0; i < FFT_SIZE; i += 1 {
		c := g_spectrumState.plan.buffer[i]
		re := real(c)
		im := imag(c)
		power := (re * re + im * im) * inv_size
		g_spectrumState.left_spectrum[i] = power
	}

	// Run FFT on right channel and compute its power spectrum
	fft.run_fft_plan(g_spectrumState.plan, g_spectrumState.rightInput[:])

	// Compute power spectrum for right channel
	for i := 0; i < FFT_SIZE; i += 1 {
		c := g_spectrumState.plan.buffer[i]
		re := real(c)
		im := imag(c)
		power := (re * re + im * im) * inv_size
		g_spectrumState.right_spectrum[i] = power
	}
}
