# MRI reconstruction


## Requirements

**All requirements are already installed in iHEALTH servers** (e.g. ih-condor, nyquist, fourier). Simply load them by running:
```bash
module load bart imagine nifty
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

  
</details>


## Usage

TODO(maparegal)
