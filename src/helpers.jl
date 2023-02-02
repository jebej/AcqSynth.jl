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

function init_board(boardnum::Int)
    # Force initialization and setup of the board
    clear_setupdone_bit(boardnum)
    setup_board(boardnum)
end

function setup_acquire_async(boardnum::Int, numblocks::Int)
    # asynchronous version of "setup_acquire", done with a Task
    ASYNC_TASK[] = @async setup_acquire(boardnum, numblocks)
    ASYNC_ACQN[] = true
    return nothing
end

function get_volts_12(boardnum::Int, numblocks::Int, v_offset::T=0f0, v_conv::T=0.350f0) where T<:AbstractFloat
    # optimized method to get 12-bit voltage samples without allocating memory for the UInt16 data
    block_buffer = BLOCK_BUFFER[]
    block_samples = reinterpret(UInt16, block_buffer)
    len_samples = length(block_samples)
    volts = Vector{T}(undef, numblocks*len_samples)
    @inbounds for b in 1:numblocks
        # Transfer 1 block from the board into the buffer
        mem_read(boardnum, block_buffer)
        # Save that block as voltage samples
        @simd for i in 1:len_samples
            volts[(b-1)*len_samples+i] = T(block_samples[i]&0x0fff) * (v_conv/2^12) - (v_conv/2 + v_offset)
        end
    end
    return volts
end

function get_volts_16(boardnum::Int, numblocks::Int, v_offset::T=0f0, v_conv::T=0.350f0) where T<:AbstractFloat
    # optimized method to get 16-bit voltage samples without allocating memory for the UInt16 data
    block_buffer = BLOCK_BUFFER[]
    block_samples = reinterpret(UInt16, block_buffer)
    len_samples = length(block_samples)
    volts = Vector{T}(undef, numblocks*len_samples)
    @inbounds for b in 1:numblocks
        # Transfer 1 block from the board into the buffer
        mem_read(boardnum, block_buffer)
        # Save that block as voltage samples
        @simd for i in 1:len_samples
            volts[(b-1)*len_samples+i] = T(block_samples[i]) * (v_conv/2^16) - (v_conv/2 + v_offset)
        end
    end
    return volts
end

function get_blocks(boardnum::Int, numblocks::Int)
    blocks = Vector{UInt8}(undef, numblocks*DIG_BLOCK_SIZE)
    return get_blocks!(blocks, boardnum, numblocks)
end

function get_blocks!(blocks::AbstractVector{UInt8}, boardnum::Int, numblocks::Int)
    checkbounds(blocks,numblocks*DIG_BLOCK_SIZE)
    block_buffer = BLOCK_BUFFER[]
    @inbounds for b = 1:numblocks
        # Transfer 1 block from the board into the buffer
        mem_read(boardnum,block_buffer)
        # Save that block
        blocks[(b-1)*DIG_BLOCK_SIZE+1:b*DIG_BLOCK_SIZE] = block_buffer
    end
    return blocks
end

function get_samples_12(boardnum::Int, numblocks::Int)
    # To get the 12-bit samples we use get_samples_16 and keep only the 12 least significant bits
    samples = get_samples_16(boardnum, numblocks)
    samples .= samples .& 0x0fff
    return samples
end

function get_samples_16(boardnum::Int, numblocks::Int)
    samples = Vector{UInt16}(undef, numblocks*DIG_BLOCK_SIZE÷2)
    get_blocks!(reinterpret(UInt8, samples), boardnum, numblocks)
    return samples
end

function get_samples_32(boardnum::Int, numblocks::Int)
    samples = Vector{UInt32}(undef, numblocks*DIG_BLOCK_SIZE÷4)
    get_blocks!(reinterpret(UInt8, samples), boardnum, numblocks)
    return samples
end
