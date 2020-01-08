module AcqSynth
using DSP, Compat

# Load the DLL
const depsfile = joinpath(dirname(@__DIR__),"deps","deps.jl")
include(depsfile)

if VERSION < v"0.7.0"
    const Cvoid = Void
else
    const mean = Compat.Statistics._mean
end

# Load module functions
include("acqsynth_h.jl")
include("wrapper.jl")
include("ddc.jl")
include("helpers.jl")

# Create a 1MB buffer for use with any board, and set a finalizer
const BLOCK_BUFFER = mem_alloc()
function free_buffer()
    mem_free(BLOCK_BUFFER)
end
atexit(free_buffer)

end
