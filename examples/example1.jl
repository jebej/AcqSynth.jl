# Basic acquisition example
using AcqSynth, PlotlyJS, Statistics
const acq = AcqSynth

# Let's see if we have a board plugged in
acq.get_num_boards()
# If the number you get is bigger than 0, congrats your board works!

# Select board 0 and check its serial number
boardnum = 0
acq.get_serial(boardnum)

# OK we can start working. First, we need to calibrate/setup the board.
acq.init_board(boardnum)

# Make sure we have an ADC12D2000!
acq.is_AD12(boardnum)

# We can see have many channels the board has
acq.get_all_channels(boardnum)

# Now, we can configure the default acquisition session and digitize data
# Let's start by checking what number of channels are in use right now
acq.get_num_channels(boardnum)

# Check the frequency
acq.get_frequency(boardnum)

# At this point, without any other configuration we can start acquiring by
# choosing how many 1MiB blocks we want and sending a soft trigger.
# This is done with the setup_acquire() function.
numblocks = 4 # let's grab a bunch of blocks
acq.setup_acquire(boardnum,numblocks) # acquisition starts here!

# Grab the data from the card with get_samples_12 utility function
samples = acq.get_samples_12(boardnum,numblocks) # transfer data as 12-bit samples
data = permutedims(reshape(samples,2,:))

# Plot the stuff
t = (1:size(data,1))./2E9 # time vector, we are sampling at 2GSPS
plot([scatter(x=t[1:2000],y=data[1:2000,1],name="AIN0"),
      scatter(x=t[1:2000],y=data[1:2000,2],name="AIN1")])

println(" AIN0: $(mean(data[:,1])) ± $(std(data[:,1]))")
println(" AIN1: $(mean(data[:,2])) ± $(std(data[:,2]))")
