package fft

import "core:math"
import "core:math/bits"

reverse_bits :: #force_inline proc(value: uint, k: uint) -> (result: uint = 0) {
	for i in 0 ..< k {
		result |= ((value >> i) & 1) << (k - i - 1)
	}
	return result
}


// Decimation-in-time radix-2 FFT
FFT_Plan :: struct {
	fft_size:          uint,
	buffer:            []complex64,
	twiddle_lookup:    []complex64,
	scrambled_indexes: []uint,
}


create_fft_plan :: proc(fft_size: uint) -> (plan: FFT_Plan) {
	assert(bits.is_power_of_two(fft_size))

	plan.buffer = make([]complex64, fft_size)
	plan.twiddle_lookup = make([]complex64, fft_size)
	plan.scrambled_indexes = make([]uint, fft_size)
	plan.fft_size = fft_size
	phase_delta := math.TAU / f32(fft_size) // τ = 2π

	for i in 0 ..< fft_size {
		phase := phase_delta * f32(i)
		plan.twiddle_lookup[i] = complex(math.cos(phase), -math.sin(phase))
		plan.scrambled_indexes[i] = reverse_bits(uint(i), bits.log2(plan.fft_size))
	}
	return
}

destroy_fft_plan :: proc(plan: FFT_Plan) {
	delete(plan.buffer)
	delete(plan.twiddle_lookup)
	delete(plan.scrambled_indexes)
}

run_fft_plan :: proc "c" (plan: FFT_Plan, samples: []f32) #no_bounds_check {

	for sample, i in samples {
		j := plan.scrambled_indexes[i]
		plan.buffer[j] = complex(sample, 0)
	}

	RADIX :: uint(2)
	stride := uint(1)
	group_increment := RADIX
	twiddle_increment := plan.fft_size / RADIX
	butterfly_count := uint(1)

	for stride < plan.fft_size {
		group := uint(0)

		for group < plan.fft_size {
			k := uint(0)

			for b in 0 ..< butterfly_count {
				radix2_butterfly(
					&plan.buffer[group + b],
					&plan.buffer[group + b + stride],
					plan.twiddle_lookup[k],
				)
				k += twiddle_increment
			}
			group += group_increment
		}
		twiddle_increment /= RADIX
		group_increment *= RADIX
		butterfly_count *= RADIX
		stride *= RADIX
	}
}

radix2_butterfly :: #force_inline proc "c" (x: ^complex64, y: ^complex64, w: complex64) {
	a := x^ + w * y^
	b := x^ - w * y^
	x^ = a
	y^ = b
}
// TODO: real-time input optimization
