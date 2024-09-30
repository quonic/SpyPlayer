package main

import "base:intrinsics"
import "base:runtime"
import "core:c"
import "core:fmt"
import "core:math"
import "core:mem"

audioPeriod: int : 3600
currentLeftChannel: [dynamic]complex64
currentRightChannel: [dynamic]complex64
currentPeriod: int = 0
canFillVizualizerBuffer: bool = true
canCopyVizualizerBuffer: bool = false

AudioProcessFFT :: proc "c" (buffer: rawptr, frames: c.uint) {
	context = runtime.default_context()
	if buffer == nil || frames == 0 {
		return
	}
	if mem.check_zero_ptr(buffer, int(currentStream.frameCount)) {
		fmt.printfln("Buffer is zero")
		return
	}
	if !canFillVizualizerBuffer {
		return
	}
	if canFillVizualizerBuffer && currentPeriod >= audioPeriod {
		// If we can fill the buffer and the current period is 3600, reset the buffer
		currentPeriod = 0
		currentLeftChannel = {}
		currentRightChannel = {}
		canCopyVizualizerBuffer = false
	}

	#no_bounds_check {
		fs := mem.slice_ptr(cast(^[2]f32)(buffer), int(frames))
		for i in 0 ..< int(frames) {
			if fs[i][0] != 0 {
				append(&currentLeftChannel, fs[i][0])
			}
			if fs[i][1] != 0 {
				append(&currentRightChannel, fs[i][1])
			}
		}
		currentPeriod += int(frames)
		if currentPeriod >= audioPeriod {
			// Stop filling the buffer
			canFillVizualizerBuffer = false
			// We can copy the buffer
			canCopyVizualizerBuffer = true
		}
	}
}

fft :: proc(buffer: []complex64) -> []f32 {
	data := buffer
	// DFT
	#no_bounds_check {
		N: uint = uint(len(data))
		k: uint = N
		n: uint
		thetaT: f64 = math.PI / f64(N)
		phiT: complex64 = complex(math.cos(thetaT), -math.sin(thetaT))
		T: complex64
		for k > 1 {
			n = k
			k >>= 1
			phiT = phiT * phiT
			T = 1.0
			for l: uint = 0; l < k; l = l + 1 {
				for a: uint = l; a < N; a += n {
					b: uint = a + k
					if b < N { 	// Ensure 'b' is within valid range
						t: complex64 = data[a] - data[b]
						data[a] += data[b]
						data[b] = t * T
					}
				}
				T *= phiT
			}
		}

		// Decimate
		m: uint = (uint)(math.log2(f64(N)))
		for a: uint = 0; a < N; a = a + 1 {
			b: uint = a
			// Reverse bits
			b = (((b & 0xaaaaaaaa) >> 1) | ((b & 0x55555555) << 1))
			b = (((b & 0xcccccccc) >> 2) | ((b & 0x33333333) << 2))
			b = (((b & 0xf0f0f0f0) >> 4) | ((b & 0x0f0f0f0f) << 4))
			b = (((b & 0xff00ff00) >> 8) | ((b & 0x00ff00ff) << 8))
			b = ((b >> 16) | (b << 16)) >> (32 - m)
			if b < N && b > a { 	// Ensure 'b' is within valid range and prevent redundant swaps
				t: complex64 = data[a]
				data[a] = data[b]
				data[b] = t
			}
		}

		// Normalize
		f: complex64 = 1.0 / math.sqrt(f32(N))
		for i: uint = 0; i < N; i = i + 1 {data[i] *= f}
		return transmute([]f32)(data)
	}
}
