# copied from DSP.jl & simplified + multithreaded

# resample_filter output for 1//n, with attenuation = 20
const DECIM_FILTER = Dict{Int,Vector{Float32}}(
    2 => Float32[0.034286804, 0.0, -0.044083036, 0.0, 0.06171625, 0.0, -0.10286041, 0.0, 0.30858126, 0.4847183, 0.30858126, 0.0, -0.10286041, 0.0, 0.06171625, 0.0, -0.044083036, 0.0, 0.034286804],
    3 => Float32[0.021267435, 0.0, -0.025134241, -0.027647667, 0.0, 0.03455958, 0.039496664, 0.0, -0.055295333, -0.06911916, 0.0, 0.13823833, 0.27647665, 0.33431545, 0.27647665, 0.13823833, 0.0, -0.06911916, -0.055295333, 0.0, 0.039496664, 0.03455958, 0.0, -0.027647667, -0.025134241, 0.0, 0.021267435],
    4 => Float32[0.013523265, 0.0, -0.015326367, -0.023222953, -0.01768427, 0.0, 0.020899592, 0.032512136, 0.025543945, 0.0, -0.032842215, -0.05418689, -0.0459791, 0.0, 0.07663184, 0.16256067, 0.2298955, 0.2553497, 0.2298955, 0.16256067, 0.07663184, 0.0, -0.0459791, -0.05418689, -0.032842215, 0.0, 0.025543945, 0.032512136, 0.020899592, 0.0, -0.01768427, -0.023222953, -0.015326367, 0.0, 0.013523265],
    5 => Float32[0.009190319, 0.0, -0.010157721, -0.017348625, -0.01836913, -0.012062294, 0.0, 0.013785479, 0.024021171, 0.026022935, 0.017545154, 0.0, -0.021444079, -0.039034404, -0.044610746, -0.032166116, 0.0, 0.048249178, 0.10409174, 0.15613762, 0.19299671, 0.20630562, 0.19299671, 0.15613762, 0.10409174, 0.048249178, 0.0, -0.032166116, -0.044610746, -0.039034404, -0.021444079, 0.0, 0.017545154, 0.026022935, 0.024021171, 0.013785479, 0.0, -0.012062294, -0.01836913, -0.017348625, -0.010157721, 0.0, 0.009190319],
)

# Decimator FIR kernel
struct FIRDecimator{T}
    h::Vector{T}
    decimation::Int
    input_delay::Int
end

function FIRDecimator(h::Vector, decimation::Integer)
    # Calculate the delay caused by the FIR filter in # of samples at the input sample rate
    input_delay = round(Int, (length(h) - 1)/2) + 1
    return FIRDecimator(h, decimation, input_delay)
end

function decimate(kernel::FIRDecimator{Th}, x::AbstractVector{Tx}) where {Th,Tx}
    buf_len = outputlength(kernel, length(x))
    buf = Vector{promote_type(Th,Tx)}(undef, buf_len)
    return decimate!(buf, kernel, x)
end

function decimate!(buf::AbstractVector, kernel::FIRDecimator, x::AbstractVector)
    buf_len = length(buf)
    x_idx = kernel.input_delay
    decim = kernel.decimation
    checkbounds(x, buf_len*decim+x_idx)
    Threads.@threads for i in 1:buf_len
        @inbounds buf[i] = dot_b(kernel.h, x, (i-1)*decim+x_idx)
    end
    return buf
end

# Calculate the input length of a multirate filtering operation given the output length
inputlength(kernel::FIRDecimator, outlen::Integer) = outlen * kernel.decimation + kernel.input_delay

# Calculate the resulting length of a multirate filtering operation given an input length
outputlength(kernel::FIRDecimator, inlen::Integer) = cld(inlen - kernel.input_delay, kernel.decimation)

# dot up to a specified index for b
function dot_b(a::AbstractArray{T}, b::AbstractArray{T}, b_last::Integer) where T<:Real
    a_len = length(a)
    dot_len = min(b_last, a_len)
    r = zero(T)*zero(T)
    @simd for i in 1:dot_len
        @inbounds r += a[a_len - dot_len + i] * b[b_last - dot_len + i]
    end
    return r
end
