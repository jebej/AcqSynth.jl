# Functions in this file are duplicated by other functions in the standard
# wrapper. For examples, the channel_mode_select function is an AD12 specific
# functions, but the regular set_channel_select works for AD12, hence this one
# is unnecessary...

"""
    channel_mode_select(boardnum, chan_mode=2, chan_select=0, cal=0)

Configure board for either single or dual channel operation. Also calibrate ADC
if the mode changed since last call, or if the "cal" argument is set to 1.

Note that this function seems to have a bug whereas if it is called to select
single-channel mode immediately after setup_board(), the mode will not be
changed properly. When that happens, there are two options: either call this
function to first select the dual-channel mode and then call it a second time
to select the single-channel mode, or call set_setup_done_bit() followed by
setup_board() before selecting the single-channel mode. Yes, this is fucked.

Function valid only for AD12 boards.

Note that this function requires the board to have been set up with the
setup_board() function.

# Arguments
* `boardnum::Integer`: index of installed board
* `chan_mode::Integer`: 1 for single channel mode, 2 for dual channel mode
* `chan_select::Integer`: only in single channel mode, 1 for DESCLKIQ mode. Both
  inputs must be externally driven. In DESCLKIQ, the I- and Q- inputs remain
  electrically separate, increasing input bandwidth. 2 for DESIQ mode. Both
  inputs must be externally driven. In DESIQ, the I- and Q- inputs are shorted
  together. 3 for DESQ / IN0, ie channel 1 only, leave ch 2 open. 4 for DESI /
  IN1, ie channel 2 only, leave ch 1 open
* `cal::Integer`: 1 forces calibration even if the mode did not change. 0
  calibrates only if the mode changed.

# Examples
```julia
julia> boardnum = 2
julia> chan_mode = 1 # single channel
julia> chan_select = 3 # read from chan 1
julia> channel_mode_select(boardnum,chan_mode,chan_select)
```
"""
function channel_mode_select(boardnum::Int, chan_mode::Int=2, chan_select::Int=0, cal::Int=0)
    # Make sure that chan_select is 0 in dual channel mode
    (chan_mode==2)&&(chan_select=0)
    ccall((:ADC12D2000_Channel_Mode_Select,libacqsynth),Void,(Cshort,Cint,Cint,Cint),boardnum,chan_mode,chan_select,cal)
    # Make sure that worked
    if get_num_channels(boardnum)!=chan_mode
        error("Channel mode not configured properly!")
    end
    if chan_mode==1&&get_single_channel_mode(boardnum)!=chan_select
        error("Single channel selection not configured properly!")
    end
end

"""
    get_single_channel_mode(boardnum)

Returns the single channel mode. See channel_mode_select() for values.

Interestingly, the dll function does not use the same values as the
channel_mode_select() function. It returns 0 when channel 2 is selected, 1 when
channel 1 is selected, 2 when DESIQ mode is selected, and 3 when DESCLKIQ mode
is selected. The output of the dll function is therefore interpreted to use the
same values as channel_mode_select().

Function valid only for AD12 boards.

Note that this function requires the board to have been set up with the
setup_board() function.

# Examples
```julia
julia> boardnum = 2
julia> mode = get_single_channel_mode(boardnum)
```
"""
function get_single_channel_mode(boardnum::Int)
    # First check that we are in single-channel mode
    if get_num_channels(boardnum)!=1
        error("This function is valid only in single-channel mode!")
    end
    # Do the dll call
    weird_value = ccall((:ADC12D2000_GetOneChanModeValue,libacqsynth),Cint,(Cshort,),boardnum)
    # Return proper values
    return 4-weird_value
end

function get_samples12_old(blocks)
    # We now have all the blocks in the blocks array, we need to extract the
    # 12-bit samples from that array. The data in the blocks is organized in 4
    # bytes / 32-bit words, and each word contains two 12-bit samples.
    # Calculate the number of 32-bit words in the blocks array
    numwords = div(length(blocks),4)
    # Initialize array to store the samples
    data = Vector{UInt32}(2*numwords)
    for n=1:numwords
        # The 12 bits of the first sample can be extracted from the first 2
        # bytes of the 32-bit word by concatenating the 4 least significant bits
        # in the second byte with the entire first byte. We do this by ANDind
        # the second byte with 0x000f (keep only the 4 lsb and cast to 16-bit),
        # shifting that 8 bits (putting those bits in the msbyte position) and
        # ORing with the second byte.
        data[(n-1)*2+1] = blocks[(n-1)*4+2]&0x0000000f<<8|blocks[(n-1)*4+1]
        # We do the same thing for the second sample with the next two bytes
        data[(n-1)*2+2] = blocks[(n-1)*4+4]&0x0000000f<<8|blocks[(n-1)*4+3]
    end
    return data
end

function get_samples32_old(blocks)
    # We now have all the blocks in the blocks array, we need to extract the
    # 32-bit samples from that array.
    numwords = div(length(blocks),4)
    # Initialize array to store the samples
    data = Vector{UInt32}(numwords)
    for n=1:numwords
        # We combine the first 4 bytes in a 32-bit Int
        data[n] = blocks[(n-1)*4+4]&0x000000ff<<24|
                  blocks[(n-1)*4+3]&0x000000ff<<16|
                  blocks[(n-1)*4+2]&0x000000ff<<8|
                  blocks[(n-1)*4+1]
    end
    return data
end
