package main

import "base:intrinsics"
// import "core:c/libc"
// import "core:fmt"
import "core:math"
import "core:math/cmplx"

// Converted from c++ to odin
// https://github.com/jdupuy/dj_fft/blob/master/dj_fft.h


bitr :: proc(y: int, nb: int) -> int {
	x: int = y
	assert(nb > 0 && 32 > nb, "invalid bit count")
	x = (x << 16) | (x >> 16)
	x = ((x & 0x00FF00FF) << 8) | ((x & 0xFF00FF00) >> 8)
	x = ((x & 0x0F0F0F0F) << 4) | ((x & 0xF0F0F0F0) >> 4)
	x = ((x & 0x33333333) << 2) | ((x & 0xCCCCCCCC) >> 2)
	x = ((x & 0x55555555) << 1) | ((x & 0xAAAAAAAA) >> 1)

	return (x >> uint(32 - nb)) & (0xFFFFFFFF >> uint(32 - nb))
}

/*
 * Returns offset to most significant bit
 * NOTE: only works for positive power of 2s
 * examples:
 * 1b      -> 0d
 * 100b    -> 2d
 * 100000b -> 5d
 */
findMSB :: proc(x: int) -> int {
	assert(x > 0, "invalid input")
	p: int = 0
	y: int = x

	for y > 1 {
		y = y >> 1
		p = p + 1
	}

	return p
}

/*
 * Computes a Fourier transform, i.e.,
 * xo[k] = 1/sqrt(N) sum(j=0 -> N-1) xi[j] exp(i 2pi j k / N)
 * with O(N log N) complexity using the butterfly technique
 *
 * NOTE: Only works for arrays whose size is a power-of-two
 */
fft1d :: proc(xi: []$T, dir: T) -> []T where intrinsics.type_is_complex(T) {
	assert((size_of(T) & (size_of(T) - 1)) == 0, "invalid input size")
	cnt: int = size_of(T)
	msb: int = findMSB(cnt)
	nrm: T = T(1 / math.sqrt(f32(cnt)))
	xo := make([]T, cnt)

	// pre-process the input data
	for j: int = 0; j < cnt; j = j + 1 {
		if len(xi) > 0 {
			xo[j] = nrm * xi[bitr(j, msb)]
		}
	}

	// fft passes
	for i: int = 0; i < msb; i = i + 1 {
		bm: int = 1 << uint(i) // butterfly mask
		bw: int = 2 << uint(i) // butterfly width
		ang: T = T(dir) * math.PI / T(f32(bm)) // precomputation

		// fft butterflies
		for j: int = 0; j < (cnt / 2); j = j + 1 {
			i1: int = ((j >> uint(i)) << uint(i + 1)) + j % bm // left wing
			i2: int = i1 ~ bm // right wing

			z1, _ := cmplx.polar(ang * T(f32(i1 ~ bw))) // left wing rotation
			z2, _ := cmplx.polar(ang * T(f32(i2 ~ bw))) // right wing rotation

			tmp: T = xo[i1]

			xo[i1] += T(z1) * xo[i2]
			xo[i2] = tmp + T(z2) * xo[i2]
		}
	}

	return xo
}

// fft :: proc(x: ^[]complex64) {
// 	N := len(x)
// 	if N <= 1 {return}
// 	even: []complex64 = x[0: N / 2: 2]
// 	odd: []complex64 = x[1: N / 2: 2]
// 	fft(even)
// 	fft(odd)

// 	for k: int = 0; k < N / 2; k = k + 1 {
// 		t: complex64 = cmplx.polar_complex64(complex(1.0, 2 * math.PI * k / N)) * odd[k]
// 		x[k] = even[k] + t
// 		x[k + N / 2] = even[k] - t
// 	}
// }
