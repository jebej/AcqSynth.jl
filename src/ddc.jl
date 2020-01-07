# Digital down conversion
function ddc4!(signal::Vector)
    # Downmix the signal to dc, assuming that the signal is sampled at 4x the
    # signal frequency. This method avoids computing sine & cosine values.
    # Returns an array with points [I[1],Q[1],I[2],Q[2],I[3],Q[3],...]
    @inbounds for i in 1:4:length(signal)
        # Multiply every other sample (I2 & Q2) by -1 to downconvert
        signal[i+2] = -signal[i+2]
        signal[i+3] = -signal[i+3]
    end
    return signal
end

function ddcn(signal::Vector{T},n::Integer) where {T<:Real}
	# Downconvert signal assuming that the sampling frequency is an integer
	# multiple of the IF (if n==4, use the ddc4! function)
	out = similar(signal,2*length(signal))
	# Precompute sine and cos
	X = similar(signal,2,n)
	for i in 1:n
		X[1,i] = cospi(T(2*i)/n)
		X[2,i] = sinpi(T(2*i)/n)
	end
	# Multiply every sample to compute I & Q
    @inbounds for i in 1:length(signal)
        out[2i-1] = X[1,i%n]*signal[i]
        out[2i]   = X[2,i%n]*signal[i]
    end
	return out
end

function average_IQ_seg(signal::Vector{T},seg_len::Integer) where {T<:Real}
	# First reshape in 3D array of segments
	A = reshape_IQ_seg(signal,seg_len)
    # Average each segment (the second dimension)
    B = mean(A,2)
    # Return complex IQ values
    return reinterpret(Complex{T},vec(B))
end

function average_IQ_seg(signal::Vector{T},seg_len::Integer,window) where {T<:Real}
	# First reshape in 3D array of segments
    A = reshape_IQ_seg(signal,seg_len)
    # Trim each segment as specified by "window"
    cut_i = floor(Int,window[1]/sum(window)*seg_len) + 1
    cut_f = ceil(Int,(window[1]+window[2])/sum(window)*seg_len)
    # Average each windowed segment (the second dimension)
    B = mean(view(A,:,cut_i:cut_f,:),2)
    # Return complex IQ values
    return reinterpret(Complex{T},vec(B))
end

function reshape_IQ_seg(signal::Vector{T},seg_len::Integer) where {T<:Real}
    # Reshape a signal vector into a 3D IQ array of segments.
	# If the full vector is not divisible in an integer number of
    # segments, the last points will be removed.
    # Warning: this function will modify the input signal array
    n_seg = length(signal) ÷ seg_len
    # First, eliminate points at end of signal that do not belong to a segment
    resize!(signal,2*n_seg*seg_len) # factor of 2 for I & Q
    # Reshape into 3D array by stacking segments in the third dimension
    # The first dimension (size 2) corresponds to I & Q
    return reshape(signal,2,seg_len,n_seg)
end
