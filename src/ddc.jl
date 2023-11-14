# Digital down conversion

function read_seg_samples_ddc(boardnum,numblocks,n::Integer,seg_len,window,v_offset=0f0,v_conv=0.350f0)
    # read from the card and downconvert + average segments, and return as an array of complex IQ points
    seg_IQ = read_seg_waveforms_ddc(boardnum,numblocks,n,seg_len,v_offset,v_conv)
    # return windowed segment averages
    return average_IQ_seg(seg_IQ, window)
end

function read_seg_waveforms_ddc(boardnum,numblocks,n::Integer,seg_len,v_offset=0f0,v_conv=0.350f0)
    # read from the card, downconvert segments, and return as an array of complex IQ points
    # n is the ratio of the sampling frequency to the IF, it must be an integer multiple of 4
    # first, trigger the board and download data
    if ASYNC_ACQN[] # acquisition was already started asynchronously, wait for task to be complete
        wait(ASYNC_TASK[])
        ASYNC_ACQN[] = false
    else # start acquisition (will block until complete)
        setup_acquire(boardnum,numblocks)
    end
    if iszero(first(get_averager(boardnum)))
        signal = get_volts_12(boardnum,numblocks,v_offset,v_conv)
    else # averaging is enabled
        signal = get_volts_16(boardnum,numblocks,v_offset,v_conv)
    end
    # calc the length of the actual signal, given the segment length
    sig_len = (length(signal)÷seg_len) * seg_len
    if n > 4 && (n÷4)*4 == n # if needed, decimate
        r = n÷4 # decimation rate
        signal = decim_fir(signal, r, sig_len)
        seg_len = (seg_len÷2r)*2 # segment length must be an even number
        resize!(signal, (length(signal)÷seg_len)*seg_len) # resize to integer number of segments
    elseif n == 4 # resize vector to contain whole number of segments
        resize!(signal, sig_len)
    else
        throw(ArgumentError("Fs/IF ratio must be an integer multiple of 4 that is also ≥ 4"))
    end
    # subtract dc component
    signal .= signal .- mean(signal, dims=1)
    # downmix with efficient method (x2 decimation since signal is split into I & Q components)
    baseband = ddc4!(signal)
    # return IQ segments as complex array
    return reshape(reinterpret(Complex{Float32},baseband), seg_len÷2, :)
end

function decim_fir(signal::AbstractVector, rate::Integer, sig_len::Integer=length(signal))
    # create LPF FIR decimator object
    lpf = FIRDecimator(rate)
    # resize signal vector to right length and decimate with FIR filter
    req_zeros = inputlength(lpf, sig_len÷rate) - sig_len
    return decimate(lpf, resize_signal!(signal, sig_len, req_zeros))
end

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

function average_IQ_seg(seg_IQ::AbstractMatrix{T}) where {T<:Complex}
    # Average over segments (the first dimension)
    IQz = mean(seg_IQ,dims=1)
    # Return complex IQ value vector
    return vec(IQz)
end

function average_IQ_seg(seg_IQ::AbstractMatrix{T},window) where {T<:Complex}
    # Trim each segment as specified by "window"
    seg_len = size(seg_IQ,1)
    cut_i = floor(Int,window[1]/sum(window)*seg_len) + 1
    cut_f = ceil(Int,(window[1]+window[2])/sum(window)*seg_len)
    # Average each windowed segment (the first dimension)
    IQz = mean(view(seg_IQ,cut_i:cut_f,:),dims=1)
    # Return complex IQ values
    return vec(IQz)
end

function resize_signal!(signal::Vector{T}, sig_len::Integer, zero_pad::Integer=0) where T
	# Resize the signal to (sig_len+zero_pad). The indices past sig_len are zeroed-out
    tot_len = sig_len + zero_pad
    resize!(signal, tot_len)
    @simd for i in (sig_len+1) : tot_len
        @inbounds signal[i] = zero(T)
    end
    return signal
end

function resize_signal!(signal::AbstractVector{T}, sig_len::Integer, zero_pad::Integer=0) where T
	# Resize the signal to (sig_len+zero_pad). The indices past sig_len are zeroed-out
    return vcat(signal[1:sig_len], zeros(T,zero_pad))
end
