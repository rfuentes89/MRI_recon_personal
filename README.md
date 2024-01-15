# MRI reconstruction


## Requirements

**All requirements are already installed in iHEALTH servers** (e.g. ih-condor, nyquist, fourier). Simply load them by running:
```bash
module load bart imagine nifty gsl/2.3 mapVBVD prost
```

You must run them before running MATLAB.

<details>
  <summary>
    If you need to install them manually, you can follow the instructions below (for a Linux system).
  </summary>


### Manual installation: [bart](https://github.com/mrirecon/bart)

For example, to install bart v0.8.00:
```bash
cd /path/to/install
wget https://github.com/mrirecon/bart/archive/refs/tags/v0.8.00.tar.gz
tar xzf bart-0.8.00
cd bart-0.8.00
make
chmod a+x bart

echo "export MATLABPATH=/path/to/install/bart-0.8.00/matlab:$MATLABPATH" >> ~/.bash_aliases
echo "export TOOLBOX_PATH=/path/to/install/bart-0.8.00:$TOOLBOX_PATH" >> ~/.bash_aliases

# Logout and log back in for changes to take effect
```

Find other bart versions in https://github.com/mrirecon/bart/releases.


### Manual installation: [imagine](https://github.com/lab-midas/imagine)

```bash
cd /path/to/install
git clone https://github.com/lab-midas/imagine.git

echo "export MATLABPATH=/path/to/install/imagine:$MATLABPATH" >> ~/.bash_aliases

# Logout and log back in for changes to take effect
```

### Manual installation: [NIFTY](https://github.com/RCiHealthGroup/NIFTY_REG)

Follow instructions in [their README](https://github.com/RCiHealthGroup/NIFTY_REG/tree/main#readme).

### Manual installation: [mapVBVD](https://github.com/RCiHealthGroup/mapVBVD)

Follow instructions in [their README](https://github.com/RCiHealthGroup/mapVBVD).


### Manual installation: PROST

Follow instructions in [their README](https://github.com/RCiHealthGroup/HD_PROST_MATLAB)

  
</details>


## Usage

1. Create a JSON configuration file to specify the parameters for the reconstruction.
   See an example in [`configs/example.json`](configs/example.json), it has comments on each parameter.

2. Run the `main.m` script either from the MATLAB editor or from the terminal:
    1. Option 1, MATLAB Editor: open the script, set the `config_fname` variable to the name of your configuration file,
       then run the script.
    2. Option 2, from the terminal: run in a terminal
       `matlab -nodisplay -batch "config_fname='/path/to/your/config.json'; main;`
