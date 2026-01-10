package main

import "base:runtime"
import "core:fmt"
import "core:math"
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
	context = runtime.default_context()

	// Safety check
	if bufferData == nil || frames == 0 {
		return
	}

	// Cast buffer to f32 array (interleaved stereo: L, R, L, R, ...)
	samples := ([^]f32)(bufferData)

	// Process samples with 50% overlap (FFT_HOP_SIZE)
	// We need FFT_SIZE samples, so collect frames until we have enough

	framesNeeded := u32(FFT_HOP_SIZE)
	if u32(g_spectrumState.samplesAccumulated) + frames < framesNeeded {
		g_spectrumState.samplesAccumulated += int(frames)
		return
	}

	// Shift overlap buffer (keep last 512 samples) and append new samples
	// Copy old samples [512..1023] to [0..511]
	for i := 0; i < FFT_HOP_SIZE; i += 1 {
		g_spectrumState.leftOverlap[i] = g_spectrumState.leftOverlap[i + FFT_HOP_SIZE]
		g_spectrumState.rightOverlap[i] = g_spectrumState.rightOverlap[i + FFT_HOP_SIZE]
	}

	// De-interleave new samples into second half of overlap buffer
	samplesToCopy := min(int(frames), FFT_HOP_SIZE)
	for i := 0; i < samplesToCopy; i += 1 {
		g_spectrumState.leftOverlap[FFT_HOP_SIZE + i] = samples[i * 2] // Left channel
		g_spectrumState.rightOverlap[FFT_HOP_SIZE + i] = samples[i * 2 + 1] // Right channel
	}

	// Apply Hanning window to overlap buffers (in-place on scratch copy)
	for i := 0; i < FFT_SIZE; i += 1 {
		g_spectrumState.leftScratch[i * 2] =
			g_spectrumState.leftOverlap[i] * g_spectrumState.hanningWindow[i]
		g_spectrumState.leftScratch[i * 2 + 1] = 0 // Imaginary part = 0 for real input

		g_spectrumState.rightScratch[i * 2] =
			g_spectrumState.rightOverlap[i] * g_spectrumState.hanningWindow[i]
		g_spectrumState.rightScratch[i * 2 + 1] = 0
	}

	// Perform FFT on both channels
	fft.rfft(g_spectrumState.leftScratch[:], true)
	fft.rfft(g_spectrumState.rightScratch[:], true)

	// Compute magnitudes and convert to dB, then bin into 64 bars
	DB_FLOOR :: -60.0
	DB_RANGE :: 60.0
	EMA_ALPHA :: 0.2

	for barIdx := 0; barIdx < NUM_BARS; barIdx += 1 {
		binStart := g_spectrumState.binEdges[barIdx]
		binEnd := g_spectrumState.binEdges[barIdx + 1]

		if binEnd <= binStart {
			binEnd = binStart + 1
		}

		// Average magnitude across bins in this bar range
		leftSum: f32 = 0
		rightSum: f32 = 0
		binCount := binEnd - binStart

		for bin := binStart; bin < binEnd; bin += 1 {
			// FFT output is interleaved complex [re, im, re, im, ...]
			idx := bin * 2
			if idx + 1 < len(g_spectrumState.leftScratch) {
				leftRe := g_spectrumState.leftScratch[idx]
				leftIm := g_spectrumState.leftScratch[idx + 1]
				leftMag := math.sqrt(leftRe * leftRe + leftIm * leftIm)

				rightRe := g_spectrumState.rightScratch[idx]
				rightIm := g_spectrumState.rightScratch[idx + 1]
				rightMag := math.sqrt(rightRe * rightRe + rightIm * rightIm)

				leftSum += leftMag
				rightSum += rightMag
			}
		}

		leftAvg := leftSum / f32(binCount)
		rightAvg := rightSum / f32(binCount)

		// Convert to dB
		leftDB := f32(20.0) * math.log10(leftAvg + 1e-10) // Add epsilon to avoid log(0)
		rightDB := f32(20.0) * math.log10(rightAvg + 1e-10)

		// Clamp and normalize to [0, 1]
		leftDB = max(leftDB, DB_FLOOR)
		rightDB = max(rightDB, DB_FLOOR)

		leftNorm := (leftDB - DB_FLOOR) / DB_RANGE
		rightNorm := (rightDB - DB_FLOOR) / DB_RANGE

		leftNorm = clamp(leftNorm, 0, 1)
		rightNorm = clamp(rightNorm, 0, 1)

		// Apply EMA smoothing to write buffer
		g_spectrumState.leftBarsWrite[barIdx] =
			EMA_ALPHA * leftNorm + (1.0 - EMA_ALPHA) * g_spectrumState.leftBarsWrite[barIdx]
		g_spectrumState.rightBarsWrite[barIdx] =
			EMA_ALPHA * rightNorm + (1.0 - EMA_ALPHA) * g_spectrumState.rightBarsWrite[barIdx]
	}

	// Publish to read buffer (lock-free copy)
	for i := 0; i < NUM_BARS; i += 1 {
		g_spectrumState.leftBarsRead[i] = g_spectrumState.leftBarsWrite[i]
		g_spectrumState.rightBarsRead[i] = g_spectrumState.rightBarsWrite[i]
	}

	// Reset sample accumulator
	g_spectrumState.samplesAccumulated = 0
}
