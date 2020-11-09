# AcqSynth.jl Documentation

Julia interface to Ultraview PCIe Data Acquisition Boards

[![Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://jebej.github.io/AcqSynth.jl/dev)

## Installation

First, `dev` the package:

```julia
using Pkg; Pkg.develop("https://github.com/jebej/AcqSynth.jl")
```

Then, download the [Ultraview software](http://ultraviewcorp.com/downloads.php) (e.g. `AD12_16-May31_17_r2_64bit.zip`, or slightly different name for Linux), and copy `AcqSynth.[dll|so]`, `get_usercode.svf`, and `ultra_config.dat` to the `deps` directory of the package (which should now be located at `~\.julia\dev\AcqSynth\`). These three files may be found in the `complete_daq_utilities\Command_Line_Utilities` folder in the zip file.

Note that, for Windows, the [2012 Visual C++ Redistributable](https://www.microsoft.com/en-ca/download/details.aspx?id=30679) is required, and you should have properly installed the board driver.

## Usage

Documentation [is available](https://jebej.github.io/AcqSynth.jl/dev) for the low-level API. There are also examples in the [examples](https://github.com/jebej/AcqSynth.jl/tree/master/examples) directory of the package.

## Contributing

Contributions are highly welcomed! Please see the repository [on Github](https://github.com/jebej/AcqSynth.jl) and feel free to open issues if you find a bug or if you feel a feature is missing.

## Author

This package was written by Jérémy Béjanin. If you find it useful, drop me a line!
