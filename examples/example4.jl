# Example showing the use of waveform triggering and segmented capture
using AcqSynth, PlotlyJS, Statistics
const acq = AcqSynth

# As in the first example, we setup the board
boardnum = 0
acq.init_board(boardnum)

clock_ratio = 20
num_seg=50000
seg_len=32000
numblocks = cld(2*num_seg*seg_len, 1024^2)
num_seg = numblocks*1024^2÷(2*seg_len)

# Use a helper function to configure for ttl triggering, with EXT clock and CHAN 1
acq.configure_for_ttl_triggering(boardnum,0,1;num_seg=num_seg,seg_len=seg_len)

# Check the frequency, in single channel mode, this will be twice the EXT clock
acq.get_frequency(boardnum) |> Int

# Trigger measurement and download the data from the card
@time data = acq.read_seg_waveforms_ddc(boardnum,numblocks,clock_ratio,seg_len)

# Plot the stuff
t = (1:size(data,1))./2E8 # time vector, we are sampling at 2GSPS and decimate by 10x
layout = Layout(yaxis_range=[0, 0.02])
plot(scatter(x=t,y=abs.(vec(mean(data,dims=2)))),layout)


# Taking many segments and downconverting is slow, especially if we are just going to average them
# instead, average in hardware (up to 64x)!
acq.set_segmented_capture(boardnum,0,seg_len)
acq.set_averager(boardnum,64,seg_len)
@time data = acq.read_seg_waveforms_ddc(boardnum,cld(numblocks,64),clock_ratio,seg_len)

# Plot the stuff
t = (1:size(data,1))./2E8 # time vector, we are sampling at 2GSPS and decimate by 10x
layout = Layout(yaxis_range=[0, 0.02])
plot(scatter(x=t,y=abs.(vec(mean(data,dims=2)))),layout)
