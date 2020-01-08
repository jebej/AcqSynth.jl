# Helper functions

function list_boards()
    numboards = get_num_boards()
    numboards == 0 && error("No boards found!")
    for n = 0:numboards-1
        setup_board(n)
        println("=> Board $n")
        model = is_AD12(n) ? "AD12" : is_AD14(n) ? "AD14" : is_AD16(n) ? "AD16" : "unknown"
        println("  model:      $model")
        println("  serial:     $(get_serial(n))")
        println("  frequency:  $(get_frequency(n)) MHz")
        println("  resolution: $(get_adcresolution(n))-bit")
        println("  memory:     $(get_memsize(n)) MiB")
        println("  channels:   $(get_all_channels(n))")
        println("  microsynth: $(has_microsynth(n) ? "yes" : "no")")
    end
end

function configure_for_ttl_triggering(boardnum,clock=1,channels=3;num_seg=0,seg_len=8192)
    setup_board(boardnum)
	set_clock(boardnum,clock)
	set_channels(boardnum,3) # needed to make sure clock is updated properly when moving to single channel mode
	set_channels(boardnum,channels)
	set_trigger(boardnum,4,1)
	# if num_seg == 0, segmented capture is disabled
	set_segmented_capture(boardnum,num_seg,seg_len)
end

function configure_for_waveform_triggering(boardnum,clock=1,channels=3,trig_ch=1,thresh=2^11,hyst=128;num_avg=0,avg_len=8192)
    setup_board(boardnum)
	set_clock(boardnum,clock)
	set_channels(boardnum,3) # needed to make sure clock is updated properly when moving to single channel mode
	set_channels(boardnum,channels)
	set_trigger(boardnum,1,1,trig_ch)
	set_waveform_trigger_params(boardnum,thresh,hyst)
	# if num_avg == 0, averaging is disabled
	set_averager(boardnum,num_avg,avg_len)
end

function read_seg_samples_ddc(boardnum,numblocks,n::Integer,seg_len,window,v_offset=0f0,v_conv=0.350f0)
    # reads from the card and downconvert + average segments, and return as an
    # array of complex IQ points
    # n is the ratio of the sampling frequency to the IF, it must be an integer
    setup_acquire(boardnum,numblocks)
    signal = (get_samples_12(boardnum,numblocks) .* v_conv/2^12) .- v_conv/2 .- v_offset

    if n > 4 # if needed, use decimating filter
        signal_len = (length(signal)÷seg_len)*seg_len
        rate = 1//(n÷4) # decimation rate
        # create LPF FIR decimator object
        h = convert(Vector{Float32},resample_filter(rate,1,20))
        lpf = FIRFilter(h,rate)::FIRFilter{Filters.FIRDecimator{Float32}}
        setphase!(lpf,timedelay(lpf))
        req_zeros = inputlength(lpf, ceil(Int, signal_len*rate)) - signal_len
        # resize signal vector to right length and decimate
        resize_signal!(signal,seg_len,req_zeros)
        signal = filt(lpf,signal)
        seg_len = seg_len * rate
    elseif n == 4
        # resize signal vector to right length
        resize_signal!(signal,seg_len)
    else
        throw(ArgumentError("Fs/IF ratio must be ≥ 4"))
    end
    # downmix with efficient method
    baseband = ddc4!(signal)

    # return segment averages
    return average_IQ_seg(baseband,seg_len÷2,window)
end

function init_board(boardnum::Int)
    # Force initialization and setup of the board
    clear_setupdone_bit(boardnum)
    setup_board(boardnum)
end

function get_blocks(boardnum::Int,numblocks::Int)
    blocks = Vector{UInt8}(numblocks*DIG_BLOCK_SIZE)
    return get_blocks!(blocks,boardnum,numblocks)
end

function get_blocks!(blocks::Vector{UInt8},boardnum::Int,numblocks::Int)
    checkbounds(blocks,numblocks*DIG_BLOCK_SIZE)
    @inbounds for b = 1:numblocks
        # Transfer 1 block from the board into the buffer
        mem_read(boardnum,BLOCK_BUFFER)
        # Save that block
        blocks[(b-1)*DIG_BLOCK_SIZE+1:b*DIG_BLOCK_SIZE] = BLOCK_BUFFER
    end
    return blocks
end

function get_samples_12(boardnum::Int,numblocks::Int)
    blocks = get_blocks(boardnum,numblocks)
    return reinterpret_samples_12!(blocks)
end

function get_samples_16(boardnum::Int,numblocks::Int)
    blocks = get_blocks(boardnum,numblocks)
    return reinterpret_samples_16!(blocks)
end

function get_samples_32(boardnum::Int,numblocks::Int)
    blocks = get_blocks(boardnum,numblocks)
    return reinterpret_samples_32!(blocks)
end

function reinterpret_samples_12!(blocks::Vector{UInt8})
    # To get the 12-bit samples, we recast to an array of UInt16 and keep only
    # the 12 least significant bits.
    samples = reinterpret(UInt16,blocks)
    @inbounds for n = 1:length(samples)
        samples[n] = samples[n]&0x0fff
    end
    return samples
end

function reinterpret_samples_16!(blocks::Vector{UInt8})
    # To get the 16-bit samples, we simply recast to UInt16.
    return reinterpret(UInt16,blocks)
end

function reinterpret_samples_32!(blocks::Vector{UInt8})
    # To get the 32-bit samples, we simply recast to UInt32.
    return reinterpret(UInt32,blocks)
end
