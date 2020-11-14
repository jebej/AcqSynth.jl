module AcqSynth
using DSP, Compat, Compat.Statistics, Compat.Libdl

# Deps dir (must contain AcqSynth library, 'get_usercode.svf', and 'ultra_config.dat')
const deps_dir = joinpath(dirname(@__DIR__),"deps")

# Library file
const libacqsynth = joinpath(deps_dir,"AcqSynth.$dlext")

if VERSION < v"0.7.0"
    const Cvoid = Void
end

# Load module functions
include("acqsynth_h.jl")
include("wrapper.jl")
include("ddc.jl")
include("helpers.jl")

const BLOCK_BUFFER = Ref{Vector{Cuchar}}()

function __init__()
    # Make sure that the required files are there
    for file in ["AcqSynth.$dlext", "get_usercode.svf", "ultra_config.dat"]
        isfile(joinpath(deps_dir,file)) || @warn("Make sure `$file` is in the `deps` directory.")
    end

    # Change to deps directory to load the AcqSynth libray
    # required since the libray loads the usercode and config files from the current directory
    libhandle = cd(deps_dir) do
        Libdl.dlopen(libacqsynth, throw_error=false)
    end

    if libhandle === nothing
        @warn "AcqSynth library could not be loaded, package will not be functional."
        return
    end

    # Register finalizer function to close AcqSynth libray when Julia exits
    atexit() do
        isclosed = false
        while !isclosed
            isclosed = Libdl.dlclose(libhandle)
        end
    end

    # Create a 1MB buffer for use with any board, and register a finalizer
    BLOCK_BUFFER[] = mem_alloc()
    atexit(() -> mem_free(BLOCK_BUFFER[]))
end
end
