# Julia wrapper for the AcqSynth DLL

"""
    get_num_boards()

Return the number of Ultraview boards connected to the PC.

# Examples
```julia
julia> get_num_boards()
```
"""
function get_num_boards()
    return ccall((:DllApiGetNumDevices,libacqsynth),Cshort,())
end

"""
    get_serial(boardnum)

Return the serial number of the chosen board.

Note that the DLL function requires "get_usercode.svf" to be in the current
directory when it is executed.

# Examples
```julia
julia> boardnum = 2
julia> get_serial(boardnum)
```
"""
function get_serial(boardnum::Int)
    # Make sure that the "get_usercode.svf" file exists
    if !isfile(joinpath(usr_dir,"get_usercode.svf"))
        error("Make sure that the `get_usercode.svf` file is located in the deps/usr folder of the AcqSynth module!")
    end
    # Change to usr directory
    current_dir = pwd()
    cd(usr_dir)
    # Make dll call
    serial = ccall((:DllApiGetSerialNumber,libacqsynth),Cshort,(Cshort,),boardnum)
    # Change back to previous directory
    cd(current_dir)
    # Check if we got a valid serial
    if serial==-1
        error("Make sure that the board number is valid!")
    end
    return serial
end

"""
    set_setup_done_bit(boardnum)

Clears the setupDone flag, forcing subsequent calls to setup_board() to perform
a full calibration.

# Examples
```julia
julia> boardnum = 2
julia> set_setup_done_bit(boardnum)
```
"""
function set_setup_done_bit(boardnum::Int)
    ccall((:SetSetupDoneBit,libacqsynth),Void,(Cshort,Cshort),boardnum,0)
end

"""
    setup_board(boardnum)

Read from `ultra_config.dat`, initialize and calibrate the board. Should be
called to set the board to a known state at the beginning of an application.

Note: Call set_setup_done_bit() before calling setup_board() to force a full
calibration and setup. The first time the board is operated, the setupDone bit
is false, and the board undergoes a complete calibration when setup_board() is
called. Subsequently, only mimimal configuration is performed.

Also note that the DLL function requires the `ultra_config.dat` file to be in
the working directory when it is executed.
"""
function setup_board(boardnum::Int)
    # Make sure that the "ultra_config.dat" file exists
    if !isfile(joinpath(usr_dir,"ultra_config.dat"))
        error("Make sure that the `ultra_config.dat` file is located in the deps/usr folder of the AcqSynth module!")
    end
    # Change to usr directory
    current_dir = pwd()
    cd(usr_dir)
    # Make dll call
    success = ccall((:SetupBoard,libacqsynth),Bool,(Cshort,),boardnum)
    # Change back to previous directory
    cd(current_dir)
    # Check if the setup worked
    if !success
        error("The board for this board number is not properlly installed!")
    end
end

"""
    is_AD12(boardnum)

Return true if the board is a model AD12, false otherwise.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> is_AD12(boardnum)
```
"""
function is_AD12(boardnum::Int)
    return ccall((:is_adc12d2000,libacqsynth),Bool,(Cshort,),boardnum)
end

"""
    is_AD14(boardnum)

Return true if the board is a model AD14, false otherwise.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> is_AD14(boardnum)
```
"""
function is_AD14(boardnum::Int)
    return ccall((:Is_ISLA214P,libacqsynth),Bool,(Cshort,),boardnum)
end

"""
    is_AD16(boardnum)

Return true if the board is a model AD16, false otherwise.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> is_AD16(boardnum)
```
"""
function is_AD16(boardnum::Int)
    return ccall((:is_ISLA216P,libacqsynth),Bool,(Cshort,),boardnum)
end

"""
    has_microsynth(boardnum)

Return true if the board has a microsynth, fasle otherwise.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> has_microsynth(boardnum)
```
"""
function has_microsynth(boardnum::Int)
    return ccall((:has_microsynth,libacqsynth),Bool,(Cshort,),boardnum)
end

"""
    get_num_channels(boardnum)

Returns the number of channels configured for acquisition. Used to help decode
buffer data. See get_sample<nn> helper functions.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> nchan = get_num_channels(boardnum)
```
"""
function get_num_channels(boardnum::Int)
    return ccall((:getNumChannels,libacqsynth),Cint,(Cshort,),boardnum)
end

"""
    get_all_channels(boardnum)

Returns the number of available channels on the ADC.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> nchan = get_all_channels(boardnum)
```
"""
function get_all_channels(boardnum::Int)
    return ccall((:getAllChannels,libacqsynth),Cint,(Cshort,),boardnum)
end

"""
    set_channel_select(boardnum,chan_select)

Configure which channels to use for acquisition.

For AD14 or AD16 boards, chan_select should be the bitwise OR of the desired
channels IN0, IN1, IN2, and IN3.

For AD12 boards, select either the bitwise OR of the desired channels AIN0 and
AIN1, or DESCLKIQ for DESCLKIQ mode, or DESIQ for DESIQ mode.

In DESCLKIQ mode, the I- and Q- inputs remain electrically separate, increasing
input bandwidth. In DESIQ, the I- and Q- inputs are shorted together. In either
of these modes, both inputs must be externally driven.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> chan_select = IN0|IN1
julia> set_channel_select(boardnum,chan_select)
```
"""
function set_channel_select(boardnum::Int,chan_select)
    ccall((:SelectAdcChannels,libacqsynth),Void,(Cshort,Cint),boardnum,chan_select)
end

"""
    get_channel_select(boardnum)

get_channel_select

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> chan_select = get_channel_select(boardnum,chan_mode,chan_select)
```
"""
function get_channel_select(boardnum::Int)
    ccall((:GetChannelSelectValue,libacqsynth),Int,(Cshort,),boardnum)
end

"""
    set_ECL_trigger_delay(boardnum, delay)

Sets a delay after the ECL trigger goes from zero to one before data begins
acquiring. "delay" should be the delay in DCLK cycles (ADC outputs
data in four 12-bit words/DCLK cycle). In single channel mode there are 4
samples per DCLK. In two channel mode, there are 2 samples per DCLK.

Function valid only for AD12 and AD8 boards.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> set_ECL_trigger_delay(boardnum,4)
```
"""
function set_ECL_trigger_delay(boardnum::Int, delay::Int)
    ccall((:SET_ECL_TRIGGER_DELAY,libacqsynth),Void,(Cshort,Cint),boardnum,delay)
end

"""
    get_ECL_trigger_delay(boardnum)

Get ECL trigger delay value.

Function valid only for AD12 and AD8 boards.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> delay = get_ECL_trigger_delay(boardnum,4)
```
"""
function get_ECL_trigger_delay(boardnum::Int)
    return ccall((:GetEclTriggerDelayValue,libacqsynth),Cint,(Cshort,),boardnum)
end

"""
    set_ECL_trigger_enable(boardnum, enable)

Enables (or disables) ECL trigger mode. Setting "enable" to 1 enables
the ECL trigger, 0 disables it. The board will be forced into reset, awaiting
an external trigger.

Function valid only for AD12 and AD8 boards.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> set_ECL_trigger_enable(boardnum,1)
```
"""
function set_ECL_trigger_enable(boardnum::Int, enable::Int)
    ccall((:ECLTriggerEnable,libacqsynth),Void,(Cshort,Cint),boardnum,enable)
end

"""
    get_ECL_trigger_enable(boardnum)

Get ECL trigger delay enable value. Refturns true if the ECL trigger is enabled
and false otherwise.

Function valid only for AD12 and AD8 boards.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> enabled = get_ECL_trigger_enable(boardnum,4)
```
"""
function get_ECL_trigger_enable(boardnum::Int)
    return ccall((:GetECLTriggerEnableValue,libacqsynth),Int,(Cshort,),boardnum)
end

"""
    configure_waveform_trigger(boardnum, threshold, hysteresis=256)

Configure waveform triggering. Do not forget to enable triggering with the
set_trigger() function.

Function valid only for AD14 and AD16 boards.

Note that this function requires the board to have been set up with the
setup_board() function.

# Arguments
* `boardnum::Integer`: index of installed board
* `threshold::Integer`: trigger treshold, choose a value between 0 and your ADC
  maximum value (eg, 2^16-1 for a 16-bit board).
* `hysteresis::Integer`: this value should typically be a few times the noise
  amplitude of your signal, choose a value between 0 and your ADC maximum value
  (eg, 2^16-1 for a 16-bit board).

# Examples
```julia
julia> boardnum = 2
julia> threshold = 2^11 # middle value for a 12-bit board
julia> hysteresis = 512 # estimated noise level * 3
julia> configure_waveform_trigger(boardnum,threshold,hysteresis)
julia> ttype = 1 # waveform trigger
julia> slope = 1 # rising edge
julia> channel = 0 # channel IN0
julia> set_trigger(boardnum,ttype,slope,channel)
```
"""
function configure_waveform_trigger(boardnum::Int, threshold::Int, hysteresis::Int=256)
    ccall((:ConfigureWaveformTrigger,libacqsynth),Void,(Cshort,Cint,Cint),boardnum,threshold,hysteresis)
end

"""
    set_trigger(boardnum, ttype, slope, channel)

Set the trigger type. If a waveform trigger is desired, it must be configured
prealably with the configure_waveform_trigger() function.

Function valid only for AD14 and AD16 boards.

Note that this function requires the board to have been set up with the
setup_board() function.

# Arguments
* `boardnum::Integer`: index of installed board
* `ttype::Integer`: trigger type, choose between NO_TRIGGER (0),
  WAVEFORM_TRIGGER (1), SYNC_SELECTIVE_RECORDING (2), HETERODYNE (3) or
  TTL_TRIGGER_EDGE (4).
* `slope::Integer`: select whether to trigger on a FALLING_EDGE (0) or a
  RISING_EDGE (1).
* 'channel::Int': channel to trigger on

# Examples
```julia
julia> boardnum = 2
julia> ttype = 4 # TTL trigger
julia> slope = 1 # rising edge
julia> channel = 4 # channel IN2
julia> set_trigger(boardnum,ttype,slope,channel)
```
"""
function set_trigger(boardnum::Int, ttype::Int=0, slope::Int=0, channel=0)
    ccall((:SelectTrigger,libacqsynth),Void,(Cshort,Cint,Cint,Cint),boardnum,ttype,slope,channel)
end

"""
    get_trigger(boardnum)

Return the trigger type. Returns 0 for NO_TRIGGER, 1 for WAVEFORM_TRIGGER, 2
for SYNC_SELECTIVE_RECORDING, 3 for HETERODYNE or 4 for TTL_TRIGGER_EDGE.

Function valid only for AD14 and AD16 boards.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> trig_type = get_trigger(boardnum)
```
"""
function get_trigger(boardnum::Int)
    return ccall((:IsTriggerEnabled,libacqsynth),Cint,(Cshort,),boardnum)
end


"""
    set_decimation(boardnum, deci_value)

Sets ADC decimation (return a sample every "deci_value" samples only).
"deci_value" should be 1, 2, 4 or 8.

Function valid only for AD12 and AD8 boards.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> set_decimation(boardnum,8)
```
"""
function set_decimation(boardnum::Int, deci_value::Int)
    ccall((:SetAdcDecimation,libacqsynth),Void,(Cshort,Cint),boardnum,deci_value)
end

"""
    get_decimation(boardnum)

Return the decimation value.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> deci_value = get_decimation(boardnum)
```
"""
function get_decimation(boardnum::Int)
    return ccall((:GetDecimationValue,libacqsynth),Cint,(Cshort,),boardnum)
end

"""
    get_frequency(boardnum)

Return the effective sampling frequency. This is a rough measurement based on
the PCIe reference clock.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> freq = get_frequency(boardnum)
```
"""
function get_frequency(boardnum::Int)
    return ccall((:AdcClockGetFreq,libacqsynth),Cint,(Cshort,),boardnum)
end

"""
    setup_acquire(boardnum,numblocks=1)

Set up the board to acquire numblocks and wait for trigger. If no trigger was
set up, the board will start acquiring immediately.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> numblocks = 32 # acquire 32 1MB blocks
julia> setup_acquire(boardnum,numblocks)
```
"""
function setup_acquire(boardnum::Int,numblocks::Int=1)
    ccall((:setupAcquire,libacqsynth),Void,(Cshort,Cint),boardnum,numblocks)
end

"""
    mem_alloc()

Allocate a 1Mbyte block of DMA page aligned memory.

# Examples
```julia
julia> block = mem_alloc()
```
"""
function mem_alloc()
    out = Ref{Ptr{Cuchar}}()
    if ccall((:x_MemAlloc,libacqsynth),Cint,(Ptr{Ptr{Cuchar}},Csize_t),out,DIG_BLOCK_SIZE)==1
        error("Failed to allocate block buffer!")
    end
    block = unsafe_wrap(Array,out[],DIG_BLOCK_SIZE)
end

"""
    mem_read()

Read 1 block of data into a previously allocated array and clears it from the
board memory. Call mem_read() repeatedly to transfer all the blocks that were
acquired.

# Examples
```julia
julia> boardnum = 2
julia> block = mem_alloc()
julia> mem_read(boardnum,block)
```
"""
function mem_read(boardnum,block)
    ccall((:x_Read,libacqsynth),Void,(Cshort,Ptr{UInt8},Csize_t),boardnum,block,DIG_BLOCK_SIZE)
end

"""
    mem_free()

Free the memory block allocated by mem_alloc(). Note that the variable used to
reference to the block should be assigned to something else for safety.

# Examples
```julia
julia> mem_free(block)
julia> block = 0
```
"""
function mem_free(block)
    ccall((:x_FreeMem,libacqsynth),Void,(Ptr{Void},),block)
end
