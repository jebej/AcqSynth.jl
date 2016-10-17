module AcqSynth

# Store the location of the "usr" folder
const usr_dir = joinpath(dirname(dirname(@__FILE__)),"deps","usr")

# Make sure that the required files are there
if !(isfile(joinpath(usr_dir,"AcqSynth.dll"))&isfile(joinpath(usr_dir,"get_usercode.svf"))&isfile(joinpath(usr_dir,"ultra_config.dat")))
    error("Missing required files, make sure that AcqSynth.dll, get_usercode.svf and ultra_config.dat are in the /deps/usr folder.")
end

# Load the DLL
const depsfile = joinpath(dirname(dirname(@__FILE__)),"deps","deps.jl")
include(depsfile)

# Load module functions
include("acqsynth_h.jl")
include("wrapper.jl")
include("helpers.jl")

end
