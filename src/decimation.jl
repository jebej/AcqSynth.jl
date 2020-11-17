# copied from DSP.jl & simplified

# resample_filter output for 1//n, with attenuation = 20
const DECIM_FILTER = Dict{Int,Vector{Float32}}(
    2 => Float32[0.034286804, 0.0, -0.044083036, 0.0, 0.06171625, 0.0, -0.10286041, 0.0, 0.30858126, 0.4847183, 0.30858126, 0.0, -0.10286041, 0.0, 0.06171625, 0.0, -0.044083036, 0.0, 0.034286804],
    3 => Float32[0.021267435, 0.0, -0.025134241, -0.027647667, 0.0, 0.03455958, 0.039496664, 0.0, -0.055295333, -0.06911916, 0.0, 0.13823833, 0.27647665, 0.33431545, 0.27647665, 0.13823833, 0.0, -0.06911916, -0.055295333, 0.0, 0.039496664, 0.03455958, 0.0, -0.027647667, -0.025134241, 0.0, 0.021267435],
    4 => Float32[0.013523265, 0.0, -0.015326367, -0.023222953, -0.01768427, 0.0, 0.020899592, 0.032512136, 0.025543945, 0.0, -0.032842215, -0.05418689, -0.0459791, 0.0, 0.07663184, 0.16256067, 0.2298955, 0.2553497, 0.2298955, 0.16256067, 0.07663184, 0.0, -0.0459791, -0.05418689, -0.032842215, 0.0, 0.025543945, 0.032512136, 0.020899592, 0.0, -0.01768427, -0.023222953, -0.015326367, 0.0, 0.013523265],
    5 => Float32[0.009190319, 0.0, -0.010157721, -0.017348625, -0.01836913, -0.012062294, 0.0, 0.013785479, 0.024021171, 0.026022935, 0.017545154, 0.0, -0.021444079, -0.039034404, -0.044610746, -0.032166116, 0.0, 0.048249178, 0.10409174, 0.15613762, 0.19299671, 0.20630562, 0.19299671, 0.15613762, 0.10409174, 0.048249178, 0.0, -0.032166116, -0.044610746, -0.039034404, -0.021444079, 0.0, 0.017545154, 0.026022935, 0.024021171, 0.013785479, 0.0, -0.012062294, -0.01836913, -0.017348625, -0.010157721, 0.0, 0.009190319],
)

# Decimator FIR kernel
mutable struct FIRDecimator{T}
    h::Vector{T}
    hLen::Int
    decimation::Int
    inputDeficit::Int
end

function FIRDecimator(h::Vector, decimation::Integer)
    h            = reverse(h, dims=1)
    hLen         = length(h)
    inputDeficit = 1
    return FIRDecimator(h, hLen, decimation, inputDeficit)
end

function filt(self::FIRDecimator{Th}, x::AbstractVector{Tx}) where {Th,Tx}
    buf_len = outputlength(self, length(x))
    buffer  = Vector{promote_type(Th,Tx)}(undef, buf_len)
    # decimate
    s = filt!(buffer, self, x)
    s == buf_len || resize!(buffer, s)
    return buffer
end

# Decimation
function filt!(buf::AbstractVector{Tb}, self::FIRDecimator{Th}, x::AbstractVector{Tx}) where {Tb,Th,Tx}
    buf_len = length(buf)
    x_len   = length(x)
    buf_i   = 0

    x_idx = self.inputDeficit
    nbufout = fld(x_len - x_idx, self.decimation) + 1
    buf_len >= nbufout || throw(ArgumentError("buffer length insufficient"))

    @inbounds while x_idx <= x_len
        buf_i += 1
        buf[buf_i] = dot_b(self.h, x, x_idx)
        x_idx     += self.decimation
    end

    self.inputDeficit = x_idx - x_len
    return buf_i
end

# Calculates the delay caused by the FIR filter in # of samples at the input sample rate
timedelay(kernel::FIRDecimator) = (kernel.hLen - 1)/2

# setphase! set filter kernel phase index
function setphase!(kernel::FIRDecimator, ϕ::Real)
    ϕ >= zero(ϕ) || throw(ArgumentError("ϕ must be >= 0"))
    xThrowaway = round(Int, ϕ)
    kernel.inputDeficit += xThrowaway
    return nothing
end

# Calculates the input length of a multirate filtering operation given the output length
function inputlength(kernel::FIRDecimator, outputlength::Integer)
    inLen  = inputlength(outputlength, 1//kernel.decimation, 1)
    inLen += kernel.inputDeficit - 1
end
function inputlength(outputlength::Int, ratio::Union{Integer,Rational}, initialϕ::Integer)
    interpolation = numerator(ratio)
    decimation    = denominator(ratio)
    inLen         = (outputlength * decimation + initialϕ - 1) / interpolation
    return floor(Int, inLen)
end

# Calculates the resulting length of a multirate filtering operation given an input length
function outputlength(kernel::FIRDecimator, inputlength::Integer)
    outputlength(inputlength-kernel.inputDeficit+1, 1//kernel.decimation, 1)
end
function outputlength(inputlength::Integer, ratio::Union{Integer,Rational}, initialϕ::Integer)
    interpolation = numerator(ratio)
    decimation    = denominator(ratio)
    outLen        = ((inputlength * interpolation) - initialϕ + 1) / decimation
    return ceil(Int, outLen)
end


# dot that dots up to a specified index for b
@inline function dot_b(a::Array{T}, b::Array{T}, b_last::Integer) where T<:BLAS.BlasReal
    a_len = length(a); dot_len = min(b_last, a_len)
    BLAS.dot(dot_len, pointer(a, a_len - dot_len + 1), 1, pointer(b, b_last - dot_len + 1), 1)
end
