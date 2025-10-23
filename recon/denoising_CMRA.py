# Denoising code for CMRA sequences using HD-PROST

import numpy as np
import time
import matplotlib.pyplot as plt 
import pydicom
from hd_prost import denoising_hd_prosts

#Load your CMRA .dcm data here
fpath = '/mnt/workspace/rfuentes/recon/2025-10-21/dcm/Research_Raul_Fuentes_20251021_161155.300000/CMRA_Adiab_Ax_NoMOCO_2_MR/1.dcm'

# Loading volumes
CMRA_Ax = pydicom.dcmread(fpath).pixel_array

# Reorder dimensions to (height, width, depth)
CMRA_Ax = np.moveaxis(CMRA_Ax, 0, -1)

# Denoising Parameters
params = {
    "sigma": 0.7,
    #"debug": 3,
    "recon_mode": 4,
    "patch_size": 6,
    "threshold_type": 0,
    "window": 20,
    "sharpness": 0.0,
    "stride": 4,
}
start_time = time.time()

# Apply HD-PROST Denoising
denoised_image_CMRA_Ax = denoising_hd_prost(CMRA_Ax, **params)

#Remove singleton dimensions if any
denoised_image_CMRA_Ax = np.squeeze(denoised_image_CMRA_Ax)

end_time = time.time()
print(f"Denoising completed in {end_time - start_time:.2f} seconds.")

#Plot or save denoised_image_CMRA_Ax
fig, ax = plt.subplots(1, 2, figsize=(10, 5))
ax[0].imshow(CMRA_Ax[:, :, 28], cmap='gray')
ax[0].set_title('Original CMRA Axial Slice')
ax[0].axis('off')
ax[1].imshow(np.abs(denoised_image_CMRA_Ax[:, :, 28]), cmap='gray')
ax[1].set_title('Denoised CMRA Axial Slice')
ax[1].axis('off')
plt.show()

