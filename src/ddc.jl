# Digital down conversion
function ddc4!(signal::Array)
    # Downmix the signal to dc, assuming that the signal is sampled at 4x the
    # signal frequency. This methods avoids computing cosine values.
    # Returns an array with points [I[1],Q[1],I[2],Q[2],I[3],Q[3],...]
    @inbounds for i = 1:4:length(signal)
        # Multiply every other sample (I2 & Q2) by -1 to downconvert
        signal[i+2] = -signal[i+2]
        signal[i+3] = -signal[i+3]
    end
    return signal
end

function average_seg_IQ(signal::Vector{T},seg_len::Integer) where {T<:Real}
    # Average an IQ signal over segments. If the full vector is not divisible in
    # an integer number of segments, the last points will be removed.
    # Warning: this function will modify the input signal array
    n_seg = length(signal) ÷ seg_len
    # First, eliminate points that do not belong to a segment
    resize!(signal,n_seg*seg_len)
    # Reshape into 3D array by stacking segments in the third dimension
    # The first dimension (size 2) corresponds to I and Q
    A = reshape(signal,2,seg_len÷2,n_seg)
    # Average over each segment
    B = mean(A,2)
    # Return complex IQ values
    return reinterpret(Complex{T},vec(B))
end

function average_seg_IQ(signal::Vector{T},seg_len::Integer,window) where {T<:Real}
    # Average an IQ signal over segments. If the full vector is not divisible in
    # an integer number of segments, the last points will be removed.
    # Warning: this function will modify the input signal array
    n_seg = length(signal) ÷ seg_len
    # First, eliminate points that do not belong to a segment
    resize!(signal,n_seg*seg_len)
    # Reshape into 3D array by stacking segments in the third dimension
    # The first dimension (size 2) corresponds to I and Q
    A = reshape(signal,2,seg_len÷2,n_seg)
    # Trim each segment as specified by "window"
    cut_i = floor(Int,window[1]/sum(window)*seg_len/2) + 1
    cut_f = ceil(Int,(window[1]+window[2])/sum(window)*seg_len/2)
    # Average over each windowed segment
    B = mean(view(A,:,cut_i:cut_f,:),2)
    # Return complex IQ values
    return reinterpret(Complex{T},vec(B))
end
