# Example showing the use of waveform triggering and segmented capture
using AcqSynth
const acq = AcqSynth
using PyPlot

# As in the first example, we setup the board
boardnum = 0
acq.init_board(boardnum)

# Let's change to single channel mode
chan = acq.AIN0
acq.set_channels(boardnum,chan)
# We can verify that this worked properly
acq.get_channels(boardnum) == chan

# Check the frequency, in single channel mode, this will be twice the normal
acq.get_frequency(boardnum)

# Configure the board for waveform triggering
hysteresis = 32
threshold = 2^11-220 # middle value for a 12-bit board
ttype = acq.WAVEFORM_TRIGGER
# This function configures the waveform parameters
acq.set_waveform_trigger_params(boardnum,threshold,hysteresis)
# This function sets the trigger type
acq.set_trigger(boardnum,ttype,acq.RISING_EDGE,chan)

# Configure segmented capture
count = 16 # number of segments to acquire
depth = 2^8 # number of samples per segment
acq.set_segmented_capture(boardnum,count,depth)
acq.get_segmented_capture(boardnum) == (count,depth)

acq.set_pretrigger_mem(boardnum,0)

# Setup acquisition, the card will wait until a trigger is detected
numblocks = 100 # let's grab 2 blocks
acq.setup_acquire(boardnum,numblocks)

# Grab the data from the card
blocks = acq.get_blocks(boardnum,numblocks) # transfer blocks
data = acq.get_samples12(blocks) # interpret blocks as 12-bit samples

# Plot the stuff
t = (0:length(data))/4E9 # time vector, we are sampling at 4GSPS
plot(t[1:1000],data[1:1000]); legend(["AIN0"]); grid(true)

# # We can configure other things
# # ECL trigger
# acq.get_ECL_trigger_delay(boardnum)
# acq.get_ECL_trigger(boardnum)
# acq.set_ECL_trigger(boardnum,0)
# acq.set_ECL_trigger_delay(boardnum,512)
# # Configure averager
# count = 2^6 # number of segments to acquire
# depth = 2^12 # number of samples per segment
# acq.set_averager(boardnum,count,depth)
# acq.get_averager(boardnum) == (count,depth)
