# Example showing the use of waveform triggering
using AcqSynth, PlotlyJS
const acq = AcqSynth

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

# Setup acquisition, the card will wait until a trigger is detected
numblocks = 2 # let's grab 2 blocks
acq.setup_acquire(boardnum,numblocks)

# Grab the data from the card
data = acq.get_samples_12(boardnum,numblocks) # transfer data as 12-bit samples

# Plot the stuff
t = (1:length(data))./4E9 # time vector, we are sampling at 4GSPS
plot(scatter(x=t[1:2000],y=data[1:2000],name="AIN0"))
