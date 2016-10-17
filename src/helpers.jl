# Helper functions

function get_data(boardnum::Int,buffer::Array{UInt8,1},numblocks::Int)
    # Initialize array to store the transferred blocks
    blocks = Array{UInt8}(numblocks*DIG_BLOCK_SIZE)
    for b=1:numblocks
        # Transfer 1 block from the board into the buffer
        mem_read(boardnum,buffer)
        # Save that block
        blocks[(b-1)*DIG_BLOCK_SIZE+1:b*DIG_BLOCK_SIZE] = buffer
    end
    # We now have all the blocks in the blocks array, we need to extract the
    # 12-bit samples from that array. The data in the blocks is organized in 4
    # bytes / 32-bit words, and each word contains two 12-bit samples.
    # Calculate the number of 32-bit words in the blocks array
    numwords = div(numblocks*DIG_BLOCK_SIZE,4)
    # Initialize array to store the samples
    data = Array{Int32}(2*numwords)
    for n=1:numwords
        # The 12 bits of the first sample can be extracted from the first 2
        # bytes of the 32-bit word by concatenating the 4 least significant bits
        # in the second byte with the entire first byte. We do this by ANDind
        # the second byte with 0x000f (keep only the 4 lsb and cast to 16-bit),
        # shifting that 8 bits (putting those bits in the msbyte position) and
        # ORing with the second byte.
        data[(n-1)*2+1] = blocks[(n-1)*4+2]&0x000f<<8|blocks[(n-1)*4+1]
        # We do the same thing for the second sample with the next two bytes
        data[(n-1)*2+2] = blocks[(n-1)*4+4]&0x000f<<8|blocks[(n-1)*4+3]
    end
    return data
end
