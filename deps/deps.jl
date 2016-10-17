# Define macro
macro checked_lib(libname, path)
    ( Base.Libdl.dlopen_e(path) == C_NULL) && error("Unable to load $libname ($path).")
    quote const $(esc(libname)) = $path end
end

# Change to usr directory
current_dir = pwd()
cd(usr_dir)

# Load DLL
@checked_lib libacqsynth "AcqSynth.dll"

# Change back to previous directory
cd(current_dir)
