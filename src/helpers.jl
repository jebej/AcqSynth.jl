# Helper functions

function list_boards()
    numboards = get_num_boards()
    numboards == 0 && error("No boards found!")
    for n = 0:numboards-1
        setup_board(n)
        println("Board $n")
        model = is_AD12(n) ? "AD12" : is_AD14(n) ? "AD14" : is_AD16(n) ? "AD16" : "unknown"
        println("  model:      $model")
        println("  serial:     $(get_serial(n))")
        println("  frequency:  $(get_frequency(n)) MHz")
        println("  channels:   $(get_all_channels(n))")
        println("  microsynth: $(has_microsynth(n) ? "yes" : "no")")
    end
end

function init_board(boardnum::Int)
    # Force initialization and setup of the board
    set_setup_done_bit(boardnum)
    setup_board(boardnum)
end

function get_blocks(boardnum::Int,numblocks::Int)
    blocks = Vector{UInt8}(numblocks*DIG_BLOCK_SIZE)
    return get_blocks!(blocks,boardnum,numblocks)
end

function get_blocks!(blocks::Vector{UInt8},boardnum::Int,numblocks::Int)
    for b = 1:numblocks
        # Transfer 1 block from the board into the buffer
        mem_read(boardnum,BLOCK_BUFFER)
        # Save that block
        @inbounds blocks[(b-1)*DIG_BLOCK_SIZE+1:b*DIG_BLOCK_SIZE] = BLOCK_BUFFER
    end
    return blocks
end

function get_samples12(blocks::Vector{UInt8})
    # To get the 12-bit samples, we recast to an array of UInt16 and keep only
    # the 12 least significant bits.
    samples = reinterpret(UInt16,blocks)
    for n = 1:length(samples)
        samples[n] = samples[n]&0x0fff
    end
    return samples
end

function get_samples32(blocks::Vector{UInt8})
    # To get the 32-bit samples, we simply recast to UInt32.
    return reinterpret(UInt32,blocks)
end
