package main

// Decimation in time radix-2

import "core:c/libc"
import "core:fmt"
import "core:math"
import "core:math/cmplx"
import "core:mem"

// #include "fft.h"
// #include <math.h>
// #include <stdlib.h>
// #include <string.h>

// static int ctz(size_t N)
// {
// 	int ctz1 = 0;
//
// 	while (N) {
// 		ctz1++;
// 		N >>= 1;
// 	}
//
// 	return ctz1 - 1;
// }

@(private = "file")
ctz :: proc(N: u32) -> i32 {
	N := N
	ctz1: i32 = 0

	for N != 0 {
		ctz1 += 1
		N >>= 1
	}

	return ctz1 - 1
}

// static void nop_split(const float complex *x, float complex *X, size_t N)
// {
// 	for (size_t n = 0; n < N/2; n++) {
// 		X[0/2 + n] = x[2*n + 0];
// 		X[N/2 + n] = x[2*n + 1];
// 	}
// }

@(private = "file")
nop_split :: proc(x: [^]complex64, X: [^]complex64, N: int) {
	for n: int = 0; n < N / 2; n += 1 {
		X[0 / 2 + n] = x[2 * n + 0]
		X[N / 2 + n] = x[2 * n + 1]
	}
}

// static void fft_split(const float complex *x, float complex *X, size_t N, float complex phi)
// {
// 	for (size_t n = 0; n < N/2; n++) {
// 		X[0/2 + n] = x[2*n + 0] + x[2*n + 1] * cexpf(-2*(float)M_PI*I*phi);
// 		X[N/2 + n] = x[2*n + 0] - x[2*n + 1] * cexpf(-2*(float)M_PI*I*phi);
// 	}
// }

@(private = "file")
fft_split :: proc(x: [^]complex64, X: [^]complex64, N: u32, phi: complex64) {
	for n: u32 = 0; n < N / 2; n += 1 {
		X[0 / 2 + n] =
			x[2 * n + 0] +
			x[2 * n + 1] * cmplx.exp_complex64(complex64(complex(0.0, -2 * f32(math.PI))) * phi)
		X[N / 2 + n] =
			x[2 * n + 0] -
			x[2 * n + 1] * cmplx.exp_complex64(complex64(complex(0.0, -2 * f32(math.PI))) * phi)
	}
}

// static size_t revbits(size_t v, int J)
// {
// 	size_t r = 0;
//
// 	for (int j = 0; j < J; j++) {
// 		r |= ((v >> j) & 1) << (J - 1 - j);
// 	}
//
// 	return r;
// }

@(private = "file")
revbits :: proc(v: u32, J: i32) -> u32 {
	r: u32 = 0

	for j: u32 = 0; j < u32(J); j += 1 {
		r |= ((v >> j) & 1) << uint(transmute(u32)(J) - 1 - j)
	}

	return r
}

// static int nop_reverse(int b, float complex *buffers[2], size_t N)
// {
// 	int J = ctz(N);
//
// 	for (int j = 0; j < J - 1; j++, b++) {
// 		size_t delta = N >> j;
//
// 		for (size_t n = 0; n < N; n += delta) {
// 			nop_split(buffers[b&1] + n, buffers[~b&1] + n, delta);
// 		}
// 	}
//
// 	return b;
// }

@(private = "file")
nop_reverse :: proc(
	b: i32,
	/*float complex *buffers[2]*/
	buffers: [2][^]complex64,
	N: u32,
) -> i32 {
	b := b
	J: i32 = ctz(N)

	for j: i32 = 0; j < J - 1; j += 1  /* , b += 1 */{
		delta: u32 = N >> uint(j)

		for n: u32 = 0; n < N; n += delta {
			// nop_split( buffers[ b & 1 ] + n, buffers[ ~ b & 1] + n, delta )
			buf_a := mem.ptr_offset(buffers[b & 1], n)
			buf_b := mem.ptr_offset(buffers[~b & 1], n)
			nop_split(buf_a, buf_b, int(delta))
		}

		b += 1
	}

	return b
}

// static int fft_reverse(int b, float complex *buffers[2], size_t N)
// {
// 	int J = ctz(N);
//
// 	for (int j = 0; j < J; j++, b++) {
// 		size_t delta = N >> j;
//
// 		for (size_t n = 0; n < N; n += delta) {
// 			float complex phi = (float)revbits(n/delta, j) / (float)(2 << j);
// 			fft_split(buffers[b&1] + n, buffers[~b&1] + n, delta, phi);
// 		}
// 	}
//
// 	return b;
// }

@(private = "file")
fft_reverse :: proc(
	b: i32,
	/* float complex *buffers[2] */
	buffers: [2][^]complex64,
	N: u32,
) -> i32 {
	b := b
	J: i32 = ctz(N)

	for j: i32 = 0; j < J; j += 1  /* , b++ */{
		delta: u32 = N >> uint(j)

		for n: u32 = 0; n < N; n += delta {
			phi: complex64 = complex64(
				complex(
					(transmute(f32)revbits(u32(n) / delta, j)) /
					(transmute(f32)(u32(2) << uint(j))),
					0.0,
				),
			)
			buf_a := mem.ptr_offset(buffers[b & 1], n)
			buf_b := mem.ptr_offset(buffers[~b & 1], n)
			fft_split(buf_a, buf_b, delta, phi)
		}
		b += 1
	}

	return b
}

// int fft(float complex *vector, size_t N)
// {
// 	if (!N) return 0;
//
// 	if (N & (N - 1)) return 1;
//
// 	float complex *buffers[2] = { vector, malloc(N*sizeof(float complex)) };
//
// 	if (!buffers[1]) return -1;
//
// 	int b = 0;
//
// 	b = nop_reverse(b, buffers, N);
// 	b = fft_reverse(b, buffers, N);
// 	b = nop_reverse(b, buffers, N);
//
// 	memmove(vector, buffers[b&1], N*sizeof(float complex));
//
// 	free(buffers[1]);
//
// 	return 0;
// }

fft :: proc(vector: [^]complex64, N: int) -> int {
	if N <= 0 {
		return 0
	}

	N_a: u32 = u32(N)

	if (N_a & (N_a - 1)) != 0 {
		return 1
	}

	// float complex *buffers[2] = { vector, malloc(N*sizeof(float complex)) };
	buffers: [2][^]complex64 = [2][^]complex64{}
	buffers[0] = vector
	buffers[1] = make([^]complex64, N_a)

	if buffers[1] == nil {
		return -1
	}

	b: i32 = 0

	b = nop_reverse(b, buffers, N_a)
	b = fft_reverse(b, buffers, N_a)
	b = nop_reverse(b, buffers, N_a)

	libc.memmove(vector, buffers[b & 1], uint(N_a * size_of(complex64)))

	free(buffers[1])

	return 0
}
