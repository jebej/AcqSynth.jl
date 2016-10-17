# Size of buffer
const DIG_BLOCK_SIZE = 1024 * 1024

# Channel selection for AD14 and AD16
const IN0 = 1
const IN1 = 2
const IN2 = 4
const IN3 = 8

# Channel selection for AD12
const AIN0     = 1 # Also called DESQ
const AIN1     = 2 # Also called DESI
const DESCLKIQ = 4 # Needs both inputs connected
const DESIQ    = 8 # Needs both inputs connected

# Triggering options
const NO_TRIGGER               = 0
const WAVEFORM_TRIGGER         = 1
const SYNC_SELECTIVE_RECORDING = 2
const HETERODYNE               = 3
const TTL_TRIGGER_EDGE         = 4

const FALLING_EDGE = 0
const RISING_EDGE  = 1
