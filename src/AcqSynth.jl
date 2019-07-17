module AcqSynth

# Load the DLL
const depsfile = joinpath(dirname(dirname(@__FILE__)),"deps","deps.jl")
include(depsfile)

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
