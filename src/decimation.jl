# lifted from DSP.jl

# resample_filter output for 1//n, with attenuation = 20
const DECIM_FILTER = Dict{Int,Vector{Float32}}(
    2 => Float32[0.034286804, 0.0, -0.044083036, 0.0, 0.06171625, 0.0, -0.10286041, 0.0, 0.30858126, 0.4847183, 0.30858126, 0.0, -0.10286041, 0.0, 0.06171625, 0.0, -0.044083036, 0.0, 0.034286804],
    3 => Float32[0.021267435, 0.0, -0.025134241, -0.027647667, 0.0, 0.03455958, 0.039496664, 0.0, -0.055295333, -0.06911916, 0.0, 0.13823833, 0.27647665, 0.33431545, 0.27647665, 0.13823833, 0.0, -0.06911916, -0.055295333, 0.0, 0.039496664, 0.03455958, 0.0, -0.027647667, -0.025134241, 0.0, 0.021267435],
    4 => Float32[0.013523265, 0.0, -0.015326367, -0.023222953, -0.01768427, 0.0, 0.020899592, 0.032512136, 0.025543945, 0.0, -0.032842215, -0.05418689, -0.0459791, 0.0, 0.07663184, 0.16256067, 0.2298955, 0.2553497, 0.2298955, 0.16256067, 0.07663184, 0.0, -0.0459791, -0.05418689, -0.032842215, 0.0, 0.025543945, 0.032512136, 0.020899592, 0.0, -0.01768427, -0.023222953, -0.015326367, 0.0, 0.013523265],
    5 => Float32[0.009190319, 0.0, -0.010157721, -0.017348625, -0.01836913, -0.012062294, 0.0, 0.013785479, 0.024021171, 0.026022935, 0.017545154, 0.0, -0.021444079, -0.039034404, -0.044610746, -0.032166116, 0.0, 0.048249178, 0.10409174, 0.15613762, 0.19299671, 0.20630562, 0.19299671, 0.15613762, 0.10409174, 0.048249178, 0.0, -0.032166116, -0.044610746, -0.039034404, -0.021444079, 0.0, 0.017545154, 0.026022935, 0.024021171, 0.013785479, 0.0, -0.012062294, -0.01836913, -0.017348625, -0.010157721, 0.0, 0.009190319],
)

abstract type Filter end
abstract type FIRKernel{T} end

# FIRFilter - the kernel does the heavy lifting
mutable struct FIRFilter{Tk<:FIRKernel} <: Filter
    kernel::Tk
    history::Vector
    historyLen::Int
    h::Vector
end

function FIRFilter(h::Vector, ratio::Rational)
    interpolation = numerator(ratio)
    decimation    = denominator(ratio)
    historyLen    = 0

    @assert interpolation == 1 # decimate
    kernel     = FIRDecimator(h, decimation)
    historyLen = kernel.hLen - 1
    history    = zeros(historyLen)
    return FIRFilter(kernel, history, historyLen, h)
end

# Decimator FIR kernel
mutable struct FIRDecimator{T} <: FIRKernel{T}
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

function filt(self::FIRFilter{FIRDecimator{Th}}, x::AbstractVector{Tx}) where {Th,Tx}
    bufLen         = outputlength(self, length(x))
    buffer         = Vector{promote_type(Th,Tx)}(undef, bufLen)
    samplesWritten = filt!(buffer, self, x)

    samplesWritten == bufLen || resize!(buffer, samplesWritten)

    return buffer
end

# Decimation
function filt!(buffer::AbstractVector{Tb}, self::FIRFilter{FIRDecimator{Th}}, x::AbstractVector{Tx}) where {Tb,Th,Tx}
    kernel              = self.kernel
    bufLen              = length(buffer)
    xLen                = length(x)
    history::Vector{Tx} = self.history
    bufIdx              = 0

    if xLen < kernel.inputDeficit
        self.history = shiftin!(history, x)
        kernel.inputDeficit -= xLen
        return bufIdx
    end

    outLen              = outputlength(self, xLen)
    inputIdx            = kernel.inputDeficit

    nbufout = fld(xLen - inputIdx, kernel.decimation) + 1
    bufLen >= nbufout || throw(ArgumentError("buffer length insufficient"))

    while inputIdx <= xLen
        bufIdx += 1

        if inputIdx < kernel.hLen
            accumulator = unsafe_dot(kernel.h, history, x, inputIdx)
        else
            accumulator = unsafe_dot(kernel.h, x, inputIdx)
        end

        @inbounds buffer[bufIdx] = accumulator
        inputIdx                += kernel.decimation
    end

    kernel.inputDeficit = inputIdx - xLen
    self.history        = shiftin!(history, x)

    return bufIdx
end

# Calculates the delay caused by the FIR filter in # of samples at the input sample rate
timedelay(self::FIRFilter) = timedelay(self.kernel)
timedelay(kernel::FIRDecimator) = (kernel.hLen - 1)/2

# setphase! set filter kernel phase index
setphase!(self::FIRFilter, ϕ::Real) = setphase!(self.kernel, ϕ)
function setphase!(kernel::FIRDecimator, ϕ::Real)
    ϕ >= zero(ϕ) || throw(ArgumentError("ϕ must be >= 0"))
    xThrowaway = round(Int, ϕ)
    kernel.inputDeficit += xThrowaway
    return nothing
end

# Calculates the input length of a multirate filtering operation given the output length
inputlength(self::FIRFilter, outputlength::Integer) = inputlength(self.kernel, outputlength)
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
outputlength(self::FIRFilter, inputlength::Integer) = outputlength(self.kernel, inputlength)
function outputlength(kernel::FIRDecimator, inputlength::Integer)
    outputlength(inputlength-kernel.inputDeficit+1, 1//kernel.decimation, 1)
end
function outputlength(inputlength::Integer, ratio::Union{Integer,Rational}, initialϕ::Integer)
    interpolation = numerator(ratio)
    decimation    = denominator(ratio)
    outLen        = ((inputlength * interpolation) - initialϕ + 1) / decimation
    return ceil(Int, outLen)
end


# utils

@inline function unsafe_dot(a::Vector{T}, b::Array{T}, bLastIdx::Integer) where T<:BLAS.BlasReal
    BLAS.dot(length(a), pointer(a), 1, pointer(b, bLastIdx - length(a) + 1), 1)
end

function unsafe_dot(a::AbstractVector, b::AbstractVector{T}, c::AbstractVector{T}, cLastIdx::Integer) where T
    aLen    = length(a)
    dotprod = zero(a[1]*b[1])
    @simd for i in 1:aLen-cLastIdx
        @inbounds dotprod += a[i] * b[i+cLastIdx-1]
    end
    @simd for i in 1:cLastIdx
        @inbounds dotprod += a[aLen-cLastIdx+i] * c[i]
    end

    return dotprod
end

# Shifts b into the end a.
# shiftin!([1,2,3,4], [5, 6]) = [3,4,5,6]
function shiftin!(a::AbstractVector{T}, b::AbstractVector{T}) where T
    aLen = length(a)
    bLen = length(b)

    if bLen >= aLen
        copyto!(a, 1, b, bLen - aLen + 1, aLen)
    else

        for i in 1:aLen-bLen
            @inbounds a[i] = a[i+bLen]
        end
        bIdx = 1
        for i in aLen-bLen+1:aLen
            @inbounds a[i] = b[bIdx]
            bIdx += 1
        end
    end

    return a
end
