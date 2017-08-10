# AcqSynth.jl
Julia interface to Ultraview PCIe Data Acquisition Boards

## Installation
Currently, this package only works on Windows due to its dependence on the Windows DLL.

First, clone the pacakge:
```julia
Pkg.clone("https://github.com/jebej/AcqSynth.jl")
```

Then, download the [Ultraview Windows software](http://ultraviewcorp.com/downloads.php) (`AD12_16-May31_17_r2_64bit.zip` or later), and copy `AcqSynth.dll`, `get_usercode.svf`, and `ultra_config.dat` to the `deps` directory of the package. These three files may be found in the `complete_daq_utilities\Command_Line_Utilities` folder in the zip file.

Note that the [2012 Visual C++ Redistributable](https://www.microsoft.com/en-ca/download/details.aspx?id=30679) is required, and you should have properly installed the board driver.

## Usage

For now, see the [examples](https://github.com/jebej/AcqSynth.jl/tree/master/examples).
