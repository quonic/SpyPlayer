# FFT Real-Time Input Optimization

## Performance Characteristics

### Real-Valued Input Properties

For real-valued inputs (like audio samples), the FFT output has Hermitian symmetry:
- `X[k] = conj(X[N-k])` for k = 1..N-1
- `X[0]` and `X[N/2]` are real-valued

This means:
- Only bins 0 to N/2 contain unique information
- The current implementation computes all N bins but this is acceptable for simplicity
- Future optimization could implement a true RFFT to compute only N/2+1 bins

### Cache Locality

The Cooley-Tukey FFT algorithm processes data in stages with increasing stride. The `#no_bounds_check` annotation and grouped butterfly processing help maintain cache efficiency:

1. **Stage 1**: stride=1, processes adjacent pairs (excellent cache locality)
2. **Stage 2**: stride=2, processes pairs 2 apart
3. **Stage N**: stride=N/2, processes pairs N/2 apart

### Complexity

- Time Complexity: O(N log N) where N = FFT_SIZE (1024)
- Space Complexity: O(N) for buffers
- Real-time Performance: Suitable for 44.1kHz audio at 1024-point FFT

## Future Optimizations

Potential further improvements (not implemented to keep changes minimal):

1. **True RFFT**: Implement a specialized real FFT that only computes N/2+1 output bins
2. **SIMD**: Use platform-specific SIMD instructions for complex arithmetic
3. **Parallel Processing**: Process left/right channels in parallel threads
4. **Windowing**: Apply window function (Hann, Hamming) for better frequency resolution
5. **Overlap-Add**: Implement overlap-add for smoother spectrum updates

## References

- Cooley-Tukey FFT Algorithm
- Decimation-in-time (DIT) radix-2 FFT
- Hermitian symmetry of real-valued DFT
