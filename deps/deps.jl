# Store the location of the "deps" folder
const deps_dir = dirname(@__FILE__)

# Make sure that the required files are there
for file in ["AcqSynth.dll", "get_usercode.svf", "ultra_config.dat"]
    isfile(joinpath(deps_dir,file)) || error("Make sure `$file` is in the `deps` directory.")
end

# The DLL file exists
const libacqsynth = joinpath(deps_dir,"AcqSynth.dll")

# Change to deps directory to load the AcqSynth DLL
# This is required since the DLL loads the usercode and config files from the current directory
const libhandle = cd(deps_dir) do
    Libdl.dlopen(libacqsynth)
end

# Register finalizer function to close AcqSynth DLL when julia exits
function closeacqsynth()
    isclosed = false
    while !isclosed
        isclosed = Libdl.dlclose(libhandle)
    end
end
atexit(closeacqsynth)
