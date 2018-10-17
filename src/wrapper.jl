# Julia wrapper for the AcqSynth DLL

"""
    get_num_boards()

Return the number of Ultraview boards connected to the PC.

# Examples
```julia-repl
julia> get_num_boards()
1
```
"""
function get_num_boards()
    return ccall((:DllApiGetNumDevices,libacqsynth),Cint,())
end

"""
    get_serial(boardnum)

Return the serial number of the chosen board.

Note that the DLL function requires "get_usercode.svf" to be in the current directory when it is executed.

# Examples
```julia-repl
julia> boardnum = 0
julia> get_serial(boardnum)
1092
```
"""
function get_serial(boardnum::Int)
    # Make sure that the "get_usercode.svf" file exists
    isfile(joinpath(deps_dir,"get_usercode.svf")) || error("Make sure `get_usercode.svf` is in the `deps` directory.")
    # Make dll call
    serial = cd(deps_dir) do
        ccall((:DllApiGetSerialNumber,libacqsynth),Cint,(Cushort,),boardnum)
    end
    # Check if we got a valid serial
    serial==-1 && error("Make sure that the board number is valid!")
    return serial
end

"""
    clear_setupdone_bit(boardnum)

Clear the `setupDone` flag, forcing the following call to [`setup_board`](@ref) to perform a full calibration.

# Examples
```julia-repl
julia> boardnum = 2
julia> clear_setupdone_bit(boardnum)
```
"""
function clear_setupdone_bit(boardnum::Int)
    ccall((:SetSetupDoneBit,libacqsynth),Void,(Cushort,Cuint),boardnum,0)
end

"""
    setup_board(boardnum)

Read from `ultra_config.dat`, initialize and calibrate the board. Should be called to set the board to a known state at the beginning of an application.

Note: Call [`clear_setupdone_bit`](@ref) before calling [`setup_board`](@ref) to force a full calibration and setup. The first time the board is operated, the `setupDone` bit is false, and the board undergoes a complete calibration when [`setup_board`](@ref) is called. Subsequently, only mimimal configuration is performed.

Also note that the DLL function requires the `ultra_config.dat` file to be in the working directory when it is executed.
"""
function setup_board(boardnum::Int)
    # Make sure that the "ultra_config.dat" file exists
    isfile(joinpath(deps_dir,"ultra_config.dat")) || error("Make sure `ultra_config.dat` is in the `deps` directory.")
    # Make dll call
    success = cd(deps_dir) do
        ccall((:SetupBoard,libacqsynth),Bool,(Cushort,),boardnum)
    end
    # Check if the setup worked
    success || error("The board for this board number is not properly installed!")
    return nothing
end

"""
    is_AD12(boardnum)

Return true if the board is a model AD12, false otherwise.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> is_AD12(boardnum)
true
```
"""
function is_AD12(boardnum::Int)
    return ccall((:is_adc12d2000,libacqsynth),Bool,(Cushort,),boardnum)
end

"""
    is_AD14(boardnum)

Return true if the board is a model AD14, false otherwise.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> is_AD14(boardnum)
false
```
"""
function is_AD14(boardnum::Int)
    return ccall((:Is_ISLA214P,libacqsynth),Bool,(Cushort,),boardnum)
end

"""
    is_AD16(boardnum)

Return true if the board is a model AD16, false otherwise.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> is_AD16(boardnum)
false
```
"""
function is_AD16(boardnum::Int)
    return ccall((:is_ISLA216P,libacqsynth),Bool,(Cushort,),boardnum)
end

"""
    get_all_channels(boardnum)

Returns the number of available channels on the ADC.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> println(get_all_channels(boardnum))
2
```
"""
function get_all_channels(boardnum::Int)
    return ccall((:getAllChannels,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    get_frequency(boardnum)

Return the effective sampling frequency in MHz. This is a rough measurement based on the PCIe reference clock.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> println(get_frequency(boardnum)) # in MHz
1998
```
"""
function get_frequency(boardnum::Int)
    return ccall((:AdcClockGetFreq,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    get_adcresolution(boardnum)

Return the bit resolution of the ADC on the board.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> println(get_adcresolution(boardnum)) # in bits
12
```
"""
function get_adcresolution(boardnum::Int)
    return ccall((:GetAdcResolution,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    get_memsize(boardnum)

Return the size of the digitizer's on-board memory in MiB.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> println(get_memsize(boardnum)) # in MiB
8192
```
"""
function get_memsize(boardnum::Int)
    return ccall((:GetOnBoardMemorySize,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    has_microsynth(boardnum)

Return true if the board has a microsynth, false otherwise. If the board does have a microsynth, it can be used to program the frequency of the ADC.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> has_microsynth(boardnum)
false
```
"""
function has_microsynth(boardnum::Int)
    return ccall((:has_microsynth,libacqsynth),Bool,(Cushort,),boardnum)
end

"""
    get_num_channels(boardnum)

Returns the number of channels configured for acquisition. Used to help decode buffer data. See get_sample<nn> helper functions.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> println(get_num_channels(boardnum))
1
```
"""
function get_num_channels(boardnum::Int)
    return ccall((:getNumChannels,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    set_clock(boardnum,chan_select)

Configure whether to use the `CLOCK_INTERNAL`, or `CLOCK_EXTERNAL`.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> set_clock(boardnum,CLOCK_INTERNAL)
```
"""
function set_clock(boardnum::Int, clock::Int)
    ccall((:SetInternalClockEnable,libacqsynth),Void,(Cushort,Cuint),boardnum,clock)
end

"""
    get_clock(boardnum)

Return the clock being used, 1 for the internal clock, and 0 for the external.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> println(get_clock(boardnum))
1
```
"""
function get_clock(boardnum::Int)
    return ccall((:GetInternalClockValue,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    set_channels(boardnum, chan_select)

Configure which channels to use for acquisition.

For AD14 or AD16 boards, `chan_select` should be the bitwise OR of the desired channels `IN0`, `IN1`, `IN2`, and `IN3`.

For AD12 boards, select either the bitwise OR of the desired channels `AIN0` and `AIN1`, or `DESCLKIQ` for DESCLKIQ mode, or `DESIQ` for DESIQ mode.

In DESCLKIQ mode, the I- and Q- inputs remain electrically separate, increasing input bandwidth. In DESIQ, the I- and Q- inputs are shorted together. In either of these modes, both inputs must be externally driven.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> chan_select = IN0|IN1
julia> set_channels(boardnum,chan_select)
```
"""
function set_channels(boardnum::Int, chan_select::Int)
    ccall((:SelectAdcChannels,libacqsynth),Void,(Cushort,Cuint),boardnum,chan_select)
end

"""
    get_channels(boardnum)

Return the current channel setup. See the [`set_channels`](@ref) function for details.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> get_channels(boardnum) # channels previously set to IN0|IN1
3
```
"""
function get_channels(boardnum::Int)
    return ccall((:GetChannelSelectValue,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    set_ECL_trigger(boardnum, state)

Enable (or disable) ECL trigger mode. Setting `state` to 1 enables the ECL trigger, 0 disables it. The board will be forced into reset, awaiting an external trigger.

Function valid only for AD12 and AD8 boards.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> set_ECL_trigger(boardnum,1)
```
"""
function set_ECL_trigger(boardnum::Int, state::Int)
    ccall((:ECLTriggerEnable,libacqsynth),Void,(Cushort,Cuint),boardnum,state)
end

"""
    get_ECL_trigger(boardnum)

Get ECL trigger delay state. Returns 1 if the ECL trigger mode is enabled
and 0 otherwise.

Function valid only for AD12 and AD8 boards.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> println(get_ECL_trigger(boardnum,4))
0
```
"""
function get_ECL_trigger(boardnum::Int)
    return ccall((:GetECLTriggerEnableValue,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    set_ECL_trigger_delay(boardnum, delay)

Sets a delay after the ECL trigger goes from zero to one before data begins acquiring. `delay` should be the delay in DCLK cycles (ADC outputs data in four 12-bit words/DCLK cycle). In single channel mode there are 4 samples per DCLK. In two channel mode, there are 2 samples per DCLK.

Function valid only for AD12 and AD8 boards.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> set_ECL_trigger_delay(boardnum,4)
```
"""
function set_ECL_trigger_delay(boardnum::Int, delay::Int)
    ccall((:SET_ECL_TRIGGER_DELAY,libacqsynth),Void,(Cushort,Cuint),boardnum,delay)
end

"""
    get_ECL_trigger_delay(boardnum)

Get ECL trigger delay value.

Function valid only for AD12 and AD8 boards.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> println(get_ECL_trigger_delay(boardnum,4))
512
```
"""
function get_ECL_trigger_delay(boardnum::Int)
    return ccall((:GetEclTriggerDelayValue,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    set_waveform_trigger_params(boardnum, threshold, hysteresis=256)

Configure waveform triggering parameters. Do not forget to enable triggering with the [`set_trigger`](@ref) function.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Arguments
* `boardnum::Integer`: index of installed board
* `threshold::Integer`: trigger treshold, choose a value between 0 and your ADC
    maximum value (eg, 2^16-1 for a 16-bit board).
* `hysteresis::Integer`: this value should typically be a few times the noise
    amplitude of your signal, choose a value between 0 and your ADC maximum value
    (eg, 2^16-1 for a 16-bit board).

# Examples
```julia-repl
julia> boardnum = 2
julia> threshold = 2^11 # middle value for a 12-bit board
julia> hysteresis = 512 # estimated noise level * 3
julia> set_waveform_trigger_params(boardnum,threshold,hysteresis)
julia> ttype = 1 # waveform trigger
julia> slope = 1 # rising edge
julia> channel = IN0 # channel IN0
julia> set_trigger(boardnum,ttype,slope,channel)
```
"""
function set_waveform_trigger_params(boardnum::Int, threshold::Int, hysteresis::Int=256)
    ccall((:ConfigureWaveformTrigger,libacqsynth),Void,(Cushort,Cuint,Cuint),boardnum,threshold,hysteresis)
end

"""
    get_waveform_trigger_params(boardnum)

Return the current waveform trigger threshold and hysteresis values.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> (threshold, hysteresis) = get_waveform_trigger_params(boardnum)
julia> println("treshold: \$threshold, hysteresis: \$hysteresis")
treshold: 2048, hysteresis: 512
```
"""
function get_waveform_trigger_params(boardnum::Int)
    threshold  = ccall((:GetWaveformThresholdValue,libacqsynth),Cuint,(Cushort,),boardnum)
    hysteresis = ccall((:GetWaveformHysteresisValue,libacqsynth),Cuint,(Cushort,),boardnum)
    return (threshold, hysteresis)
end

"""
    set_trigger(boardnum, ttype, slope, channel)

Set the trigger type. If a waveform trigger is desired, it must be configured prealably with the `[configure_waveform_trigger]`(@ref) function.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Arguments
* `boardnum::Integer`: index of installed board
* `ttype::Integer`: trigger type, choose between `NO_TRIGGER` (0),
    `WAVEFORM_TRIGGER` (1), `SYNC_SELECTIVE_RECORDING` (2), `HETERODYNE` (3) or
    `TTL_TRIGGER_EDGE` (4).
* `slope::Integer`: select whether to trigger on a `FALLING_EDGE` (0) or a
    `RISING_EDGE` (1).
* 'channel::Int': channel to trigger on

# Examples
```julia-repl
julia> boardnum = 2
julia> ttype = 4 # TTL trigger
julia> slope = 1 # rising edge
julia> channel = 4 # channel IN2
julia> set_trigger(boardnum,ttype,slope,channel)
```
"""
function set_trigger(boardnum::Int, ttype::Int=0, slope::Int=0, channel=0)
    ccall((:SelectTrigger,libacqsynth),Void,(Cushort,Cuint,Cuint,Cuint),boardnum,ttype,slope,channel)
end

"""
    get_trigger(boardnum)

Return the trigger type. Returns 0 for `NO_TRIGGER`, 1 for `WAVEFORM_TRIGGER`, 2 for `SYNC_SELECTIVE_RECORDING`, 3 for `HETERODYNE` or 4 for `TTL_TRIGGER_EDGE`.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> println(get_trigger(boardnum))
1
```
"""
function get_trigger(boardnum::Int)
    return ccall((:IsTriggerEnabled,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    set_pretrigger_mem(boardnum, samples)

Set the number of samples to be recorded prior to the trigger. Can be between 0 and 4095.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> set_pretrigger_mem(boardnum,500)
```
"""
function set_pretrigger_mem(boardnum::Int, samples::Int)
    ccall((:SetPreTriggerMemory,libacqsynth),Void,(Cushort,Cuint),boardnum,samples)
end

"""
    get_pretrigger_mem(boardnum)

Return the number of samples to be recorded prior to the trigger.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> println(get_pretrigger_mem(boardnum))
128
```
"""
function get_pretrigger_mem(boardnum::Int)
    ccall((:GetPretriggerValue,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    set_decimation(boardnum, deci_value)

Set ADC decimation (return a sample every `deci_value` samples only). `deci_value` should be 1, 2, 4 or 8. A value of 1 disables decimation.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> set_decimation(boardnum,8)
```
"""
function set_decimation(boardnum::Int, deci_value::Int)
    ccall((:SetAdcDecimation,libacqsynth),Void,(Cushort,Cuint),boardnum,deci_value)
end

"""
    get_decimation(boardnum)

Return the decimation value.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> println(get_decimation(boardnum))
8
```
"""
function get_decimation(boardnum::Int)
    return ccall((:GetDecimationValue,libacqsynth),Cuint,(Cushort,),boardnum)
end

"""
    set_segmented_capture(boardnum, count, depth)

Configure the board for segmented capture operation. Note that averaging will be disabled. Set `count` to 0 to disable segmented capture.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Arguments
* `boardnum::Integer`: index of installed board
* `count::Integer`: number (0 to 2^32-1) of segments to acquire. Each segment's
    starting amplitude is determined by the currently configured trigger. Set
    `count` to 0 to disable segmented capture.
* `depth::Integer`: number (0 to 2^32-1) of samples to acquire in each segment.
    Note that the last segment will have as many samples as can fit in the rest of
    the buffer.

# Examples
```julia-repl
julia> boardnum = 2
julia> count = 2 # number of segments to acquire
julia> depth = 1100 # number of samples per segment
julia> set_segmented_capture(boardnum,count,depth)
```
"""
function set_segmented_capture(boardnum::Int, count::Int, depth::Int)
    ccall((:ConfigureSegmentedCapture,libacqsynth),Void,(Cushort,Cuint,Cuint,Cuint),boardnum,count,depth,1)
end

"""
    get_segmented_capture(boardnum)

Return the segmented capture parameters. See [`set_segmented_capture`](@ref) for details.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> (count, depth) = get_segmented_capture(boardnum)
```
"""
function get_segmented_capture(boardnum::Int)
    count = ccall((:GetCaptureCountValue,libacqsynth),Cuint,(Cushort,),boardnum)
    depth = ccall((:GetCaptureDepthValue,libacqsynth),Cuint,(Cushort,),boardnum)
    return (count, depth)
end


"""
    set_averager(boardnum, count, depth)

Configure the board for averaging operation. Note that segmented capture will be disabled. Set `count` to 0 to disable averaging. Enabling the averager changes the output data format to 32-bit samples.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Arguments
* `boardnum::Integer`: index of installed board
* `count::Integer`: number (0 to 2^16-1) of segments to average over. Each
    segment's starting amplitude is determined by the currently configured
    trigger. Set `count` to 0 to disable averaging or to 1 for flow through.
* `depth::Integer`: number (2^n, n from 3 to 17) of samples to acquire in each
    segment.

# Examples
```julia-repl
julia> boardnum = 2
julia> count = 2 # number of segments to average over
julia> depth = 1100 # number of samples per segment
julia> set_averager(boardnum,count,depth)
```
"""
function set_averager(boardnum::Int, count::Int, depth::Int)
	if count > 64 && is_AD12(boardnum)
		count = 64
		warn("Average count reduced to maximum of 64 for AD12 board!")
	end
	if depth > 2^14 && is_AD12(boardnum)
		depth = 2^14
		warn("Average depth reduced to maximum of 2^14 for AD12 board!")
	end
    ccall((:ConfigureAverager,libacqsynth),Void,(Cushort,Cuint,Cuint,Cuint),boardnum,count,depth,1)
end

"""
    get_averager(boardnum)

Return the averager capture parameters. See [`set_averager`](@ref) for details.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> (count, depth) = get_averager(boardnum)
```
"""
function get_averager(boardnum::Int)
    count = ccall((:GetNumAveragesValue,libacqsynth),Cuint,(Cushort,),boardnum)
    depth = ccall((:GetAveragerLengthValue,libacqsynth),Cuint,(Cushort,),boardnum)
    return (count, depth)
end

"""
    setup_acquire(boardnum, numblocks=1)

Set up the board to acquire numblocks and wait for trigger. If no trigger was set up, the board will start acquiring immediately.

Note that this function requires the board to have been set up with the [`setup_board`](@ref) function.

# Examples
```julia-repl
julia> boardnum = 2
julia> numblocks = 32 # acquire 32 1MB blocks
julia> setup_acquire(boardnum,numblocks)
```
"""
function setup_acquire(boardnum::Int, numblocks::Int=1)
    ccall((:setupAcquire,libacqsynth),Void,(Cushort,Cuint),boardnum,numblocks)
end

"""
    mem_alloc()

Allocate a 1 MiB (2^20 bytes) block of DMA page aligned memory.

# Examples
```julia-repl
julia> block = mem_alloc()
```
"""
function mem_alloc()
    addr = Ref{Ptr{Cuchar}}()
    if ccall((:x_MemAlloc,libacqsynth),Cint,(Ptr{Ptr{Cuchar}},Csize_t),addr,DIG_BLOCK_SIZE)==1
        error("Failed to allocate block buffer!")
    end
    buffer = unsafe_wrap(Array,addr[],DIG_BLOCK_SIZE)
end

"""
    mem_read(boardnum, block)

Read 1 block of data into a buffer previously allocated by the [`mem_alloc`](@ref) function and clears it from the board memory. Call [`mem_read`](@ref) repeatedly to transfer all the blocks that were acquired.

# Examples
```julia-repl
julia> boardnum = 2
julia> block = mem_alloc()
julia> mem_read(boardnum,block)
```
"""
function mem_read(boardnum::Int, buffer::Array{Cuchar,1})
    ccall((:x_Read,libacqsynth),Void,(Cushort,Ptr{Cuchar},Csize_t),boardnum,buffer,DIG_BLOCK_SIZE)
end

"""
    mem_free(block)

Free the memory block allocated by [`mem_alloc`](@ref). Note that the variable used to reference to the block should be assigned to something else for safety.

# Examples
```julia-repl
julia> mem_free(block)
julia> block = 0
0
```
"""
function mem_free(buffer::Array{Cuchar,1})
    ccall((:x_FreeMem,libacqsynth),Void,(Ptr{Cuchar},),buffer)
end
