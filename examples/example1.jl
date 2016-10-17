import AcqSynth
const acq = AcqSynth
using Plots
gr()

# Let's see if we have a board plugged in
acq.get_num_boards()
# If the number you get is bigger than 0, congrats your board works!

# Select board 0 and check its serial number
boardnum = 0
acq.get_serial(boardnum)

# OK we can start working. First, we need to calibrate/setup the board.
acq.set_setup_done_bit(boardnum)
acq.setup_board(boardnum)

# Make sure we have an ADC12D2000!
acq.is_AD12(boardnum)
# We can see have many channels the board has
acq.get_all_channels(boardnum)
# We can check if the board has a programmable microsynth
acq.has_microsynth(boardnum)

# Now, we can configure the acquisition session
# Let's start by checking what number of channels are in use right now
acq.get_num_channels(boardnum)

# Let's change to single channel mode
chan = acq.AIN0
acq.set_channel_select(boardnum,chan)

# We can verify that this worked properly
acq.get_channel_select(boardnum) == chan

# We can configure other things
# ECL trigger
acq.get_ECL_trigger_delay(boardnum)
acq.get_ECL_trigger_enable(boardnum)
acq.set_ECL_trigger_enable(boardnum,0)
acq.set_ECL_trigger_delay(boardnum,512)

# Other triggers...
acq.configure_waveform_trigger(boardnum,2^11,256)
acq.get_trigger(boardnum)
acq.set_trigger(boardnum,acq.WAVEFORM_TRIGGER,acq.RISING_EDGE,chan)

# In order to read out the data, we need to set up a 1MB buffer
buffer = acq.mem_alloc()

# At this point, without any other configuration we can start acquiring by
# sending a soft trigger and choosing how many 1MB blocks we want.
numblocks = 128 # Let's grab 2 blocks
acq.setup_acquire(boardnum,numblocks)

# Grab the data from the card
@time data = acq.get_data(boardnum,buffer,numblocks)

# Plot the stuff
plot(data[1:1:20000])

# Finally, we must deallocate the buffer and clear the variable
acq.mem_free(buffer)
buffer = 0
