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
	# Precompute sine and cos
	X = Matrix{T}(undef,2,n)
	for i in 1:n
		X[1,i] = cospi(T(2*(i-1))/n)
		X[2,i] = sinpi(T(2*(i-1))/n)
	end
	# Multiply every sample to compute I & Q
    D = Matrix{T}(undef,2,length(signal))
    @inbounds for i in 1:length(signal)
        D[1,i] = X[1,mod1(i,n)]*signal[i]
        D[2,i] = X[2,mod1(i,n)]*signal[i]
    end
	return D
end

function average_IQ_seg(signal::Array{T},seg_len::Integer) where {T<:Real}
	# Reshape in 3D array by stacking segments in the third dimension
	A = reshape(signal,2,seg_len,:)
    # Average each segment (the second dimension)
    B = mean(A,2)
    # Return complex IQ values
    return reinterpret(Complex{T},vec(B))
end

function average_IQ_seg(signal::Array{T},seg_len::Integer,window) where {T<:Real}
	# Reshape in 3D array by stacking segments in the third dimension
    A = reshape(signal,2,seg_len,:)
    # Trim each segment as specified by "window"
    cut_i = floor(Int,window[1]/sum(window)*seg_len) + 1
    cut_f = ceil(Int,(window[1]+window[2])/sum(window)*seg_len)
    # Average each windowed segment (the second dimension)
    B = mean(view(A,:,cut_i:cut_f,:),2)
    # Return complex IQ values
    return reinterpret(Complex{T},vec(B))
end

function resize_signal!(signal::Vector,seg_len::Integer,zero_pad::Integer=0)
	# If the full vector is not divisible in an integer number of segments, the
    # last points will be removed. An optional zero-padding can also be applied
    n_seg = length(signal) ÷ seg_len
    tot_len = seg_len*n_seg + zero_pad
    if tot_len != length(signal)
        resize!(signal, tot_len)
    end
    @inbounds for i in (seg_len*n_seg+1) : tot_len
        signal[i] = zero(eltype(signal))
    end
end
