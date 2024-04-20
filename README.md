# MRI reconstruction


## Requirements

1. Install MATLAB and include the following toolboxes:
    * _"Image Processing Toolbox"_ (required)
    * _"Parallel Processing Toolbox"_ (optional)
    * _"Optimization Toolbox"_ (optional)
    * _"Signal Processing Toolbox"_ (optional)
2. Load these modules before running MATLAB in iHEALTH servers (e.g. ih-condor, nyquist, fourier):
    ```bash
    module load bart imagine nifty gsl/2.3 mapVBVD prost mri-coils
    ```

<details>
  <summary>
    How to install modules locally
  </summary>

If you need to install them manually (e.g. in your computer), you can follow the instructions below (for a Linux system).

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

### Manual installation: MRI-coils

Follow instructions in [their README](https://github.com/RCiHealthGroup/Coils_Toolbox).

</details>


## Usage

### Step 0: Check the folder structure
* The structure follows the same structure used for [MRI acquisitions stored in the NAS](https://i-health.cl/ih-condor/PE5YVBozG89q5qtsEo/build/faq/mri-acq/)
* There should be 1 folder per acquisition (see details in example below)
  * Inputs:
    * (required) Raw data as twix (`.dat`) inside the `raw/` folder
    * (optional) DCM reconstructed by the scanner inside the `dcm/` folder (will be used to copy the dicom attributes in the output DCM)
  * Outputs will be stored in a subfolder per recon experiment, specifically:
    * DCMs with reconstructed images (`.dcm`)
    * Configuration parameters (`.json`)
    * MATLAB variables for debugging (`.mat`), see example below

See this example of the folder structure:
```bash
acquisitions/2024-01-01_HV1_BOOST/    # Acquisition folder
    ## Inputs:
    raw/                              # raw data
        TWIX1.dat
        TWIX2.dat
    dcm/                              # DCM from the scanner (if any)
        HB1.dcm
        HB2.dcm

    ## Outputs:
    recons/                           # Reconstruction outputs will be saved here
        RUN_1/                        # One folder for each recon experiment (named as the run_name)
            config.json               # Config given to the recon script
            dcm/                      # Final recons and bin images (if any)
                CONTRAST_1.dcm        # One image per contrast, if save_dcm = true
                CONTRAST_2.dcm

                BB.dcm                # Black blood image, if included in the sequence

                CONTRAST_1-bin1.dcm   # Bin images, if save_dcm_intrabin = true
                CONTRAST_1-bin2.dcm
                ...

            # Other MATLAB variables:
            csm.mat                   # Coil sensitivies, if save_csm = true
            displacement_fields.mat   # 3D displacement fields, if save_disp_fields = true
            images.mat                # Images before denoising, if save_images = true
            motion_corrected_data.mat # Struct storing full data, if save_data = true

        RUN_2/
        ...

    motion_curves/                    # Motion curves calculated with the selected iNAV will be saved here
        CURVE_NAME.mat
```

### Step 1: Create config file
Create a JSON configuration with the reconstruction parameters
* See an example in [`configs/example.json`](configs/example.json), it has comments on each parameter
* You should NOT edit the `example.json` file, you should create your own copy


### Step 2: Save motion curves
For each raw data to reconstruct you'll need to compute its motion curves. Follow these steps:
1. Run the `main.m` script from the MATLAB editor up to the "Step 5: Reading iNAVs"
   * Set the `config_fname` variable in the first lines to the name of your configuration file
2. You will be presented with an iNAV image, and will need to make a selection to track the movement
   * Motion curves will be calculated, plotted, and saved to the `motion_curves/` folder with the name indicated in the JSON param `"motion_curve"."name"`
   * Note: you can try selecting the iNAV differently and save it with different filenames (i.e. changing the param `"motion_curve"."name"`)
3. Repeat this process for each twix file you need to process
   * You need to run this only once per twix file, then the motion curves will be loaded from file


### Step 3: Run reconstruction
Run the `main.m` script either from the MATLAB editor or from the terminal:
* Option 1, MATLAB Editor:
   1. Open the `main.m` file
   2. Set the `config_fname` variable in the first lines to the name of your configuration file
   3. Run the script (e.g. section by section, the whole file at once, or as you prefer)
* Option 2, run from a terminal: `matlab -nodisplay -batch "config_fname='/path/to/your/config.json'; main;"`
