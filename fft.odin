package main

import "base:intrinsics"
// import "core:c/libc"
import "core:fmt"
import "core:math"
import "core:math/cmplx"
import "core:testing"

// Converted from c++ to odin
// https://github.com/jdupuy/dj_fft/blob/master/dj_fft.h


bitr :: proc(y: uint, nb: uint) -> uint {
	x: uint = y
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
findMSB :: proc(x: uint) -> uint {
	assert(x > 0, "invalid input")
	p: uint = 0
	y: uint = x

	for y > 1 {
		y = y >> 1
		p = p + 1
	}

	return p
}

fft_pi :: f32(math.PI)

/*
 * Computes a Fourier transform, i.e.,
 * xo[k] = 1/sqrt(N) sum(j=0 -> N-1) xi[j] exp(i 2pi j k / N)
 * with O(N log N) complexity using the butterfly technique
 *
 * NOTE: Only works for arrays whose size is a power-of-two
 */
fft1d :: proc(xi: []f32, dir: f32) -> []f32 {
	cnt: uint = uint(len(xi))
	if cnt == 0 {
		return {}
	}
	msb: uint = findMSB(cnt)
	nrm: f32 = f32(1 / math.sqrt(f32(cnt)))
	xo := make([]f32, cnt)

	// fmt.printfln("cnt: %v", cnt)

	// pre-process the input data
	for j: uint = 0; j < cnt; j = j + 1 {
		if uint(len(xi)) > 0 {
			xo[j] = f32(nrm * xi[bitr(j, msb)])
		}
	}

	// fft passes
	for i: uint = 0; i < msb; i = i + 1 {
		bm: uint = 1 << uint(i) // butterfly mask
		bw: uint = 2 << uint(i) // butterfly width
		ang: f32 = dir * fft_pi / f32(bm) // precomputation

		// fft butterflies
		for j: uint = 0; j < (cnt / 2); j = j + 1 {
			i1: uint = ((j >> uint(i)) << uint(i + 1)) + j % bm // left wing
			i2: uint = i1 ~ bm // right wing

			z1, _ := cmplx.polar(ang * f32(i1 ~ bw)) // left wing rotation
			z2, _ := cmplx.polar(ang * f32(i2 ~ bw)) // right wing rotation

			tmp: f32 = xo[i1]

			xo[i1] += f32(z1) * xo[i2]
			xo[i2] = tmp + f32(z2) * xo[i2]
		}
	}

	return xo
}

@(test)
fft1d_f32_test :: proc(t: ^testing.T) {
	// Test with a known input
	x: [10]f32 = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
	y := fft1d(x[:], 0)
	fmt.printfln("%v", y)
	expected: [4]f32 = {0.5, 0.5, 0.5, 0.5}
	for i, v in y {
		assert(i == expected[v])
	}
}

@(test)
fft1d_f16_test :: proc(t: ^testing.T) {
	// Test with a known input
	x: [10]f32 = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
	y := fft1d(x[:], 0)
	fmt.printfln("%v", y)
	expected: [2]f32 = {0.70703125, 0.70703125}
	for i, v in y {
		assert(i == expected[v])
	}
}

// @(test)
// fft1d_u8_test :: proc(t: ^testing.T) {
// 	// Test with a known input
// 	x: [16]u8 = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
// 	y := fft1d(x[:], 0)
// 	fmt.printfln("%v", y)
// 	expected: [4]f32 = {0.5, 0.5, 0.5, 0.5}
// 	for i, v in y {
// 		assert(i == expected[v])
// 	}
// }

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


fft :: proc(data: ^[]complex64) {
	// DFT
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
				t: complex64 = data[a] - data[b]
				data[a] += data[b]
				data[b] = t * T
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
		if b > a {
			t: complex64 = data[a]
			data[a] = data[b]
			data[b] = t
		}
	}

	// Normalize
	f: complex64 = 1.0 / math.sqrt(f32(N))
	for i: uint = 0; i < N; i = i + 1 {data[i] *= f}
}
