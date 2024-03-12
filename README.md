# MRI reconstruction


## Requirements

**All requirements are already installed in iHEALTH servers** (e.g. ih-condor, nyquist, fourier). Simply load them by running:
```bash
module load bart imagine nifty gsl/2.3 mapVBVD prost mri-coils
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

# Export env variables before using
export MATLABPATH=/path/to/install/bart-0.8.00/matlab:$MATLABPATH
export TOOLBOX_PATH=/path/to/install/bart-0.8.00:$TOOLBOX_PATH
```

Find other bart versions in https://github.com/mrirecon/bart/releases.


### Manual installation: [imagine](https://github.com/lab-midas/imagine)

```bash
cd /path/to/install
git clone https://github.com/lab-midas/imagine.git

# Export env variables before using
export MATLABPATH=/path/to/install/imagine:$MATLABPATH
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
    * You should NOT edit the `example.json` file, you should create your own copy
    * Set the `run_name` to something appropriate (it will be used in the output files later, see below)

2. Run the `main.m` script either from the MATLAB editor or from the terminal:
    1. Option 1, MATLAB Editor: open the `main.m` file,
       set the `config_fname` variable in the first lines to the name of your configuration file,
       then run the script (e.g. section by section, the whole file at once, or as you prefer)
    2. Option 2, run from a terminal:
       `matlab -nodisplay -batch "config_fname='/path/to/your/config.json'; main;"`.
       Note: first you'll need to run in the MATLAB Editor at least once for each twix file, [read below](#saving-motion-curves)

### Output files

After running `main.m` successfully, these files will be stored:
* A JSON file with the configuration `<OUTPUT_FOLDER>/config/<RUN_NAME>.json`
* DICOM files in the folder `<OUTPUT_FOLDER>/dcm/<RUN_NAME>/`

Other files might be saved as well, see JSON options starting with `save_`, for example save_csm`.


### Saving motion curves

To run the script from the terminal, you'll first need to save the motion curves to a file:

1. Prepare your JSON file, and set the option `load_motion_curves: false`
2. Run the `main.m` script from the MATLAB editor up to the "Step 5: Reading iNAVs"
3. You will be prompted to make a selection on the iNAV, and motion curves will be calculated
4. Motion curves will be saved to `<OUTPUT_FOLDER>/motion_curves/<TWIX_FNAME>.mat`
5. Repeat this process for each twix file you need to process

After that, you can run from the terminal using the JSON option `load_motion_curves: true`,
so the script loads the motion curves from the `.mat` file.
