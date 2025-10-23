# Denoising code for CMRA sequences using HD-PROST

import numpy as np
import time
import matplotlib.pyplot as plt 
import pydicom
from hd_prost import denoising_hd_prost

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

end_time = time.time()
print(f"Denoising completed in {end_time - start_time:.2f} seconds.")

#Remove singleton dimensions if any
denoised_image_CMRA_Ax = np.squeeze(denoised_image_CMRA_Ax)

#If it is axial, make MPR to coronal and sagittal views if needed
CMRA_Cor = np.moveaxis(CMRA_Ax, 1, -1)
CMRA_Sag = np.moveaxis(CMRA_Ax, 0, -1)
denoised_image_CMRA_Cor = denoising_hd_prost(CMRA_Cor, **params)
denoised_image_CMRA_Sag = denoising_hd_prost(CMRA_Sag, **params)
denoised_image_CMRA_Cor = np.squeeze(denoised_image_CMRA_Cor)
denoised_image_CMRA_Sag = np.squeeze(denoised_image_CMRA_Sag)

#Make MIP if needed
MIP_CMRA_Ax = np.max(denoised_image_CMRA_Ax, axis=2)
MIP_CMRA_Cor = np.max(denoised_image_CMRA_Cor, axis=1)
MIP_CMRA_Sag = np.max(denoised_image_CMRA_Sag, axis=0)



#Plot or save denoised_image_CMRA_Ax
print("Starting to plot and save images...")
fig, ax = plt.subplots(2, 3, figsize=(10, 5))

ax[0, 0].imshow(np.abs(denoised_image_CMRA_Ax[:, :, 32]), cmap='gray')
ax[0, 0].set_title('Denoised CMRA Axial View')
ax[0, 0].axis('off')
ax[0, 1].imshow(np.abs(denoised_image_CMRA_Cor[:, :, 32]), cmap='gray')
ax[0, 1].set_title('Denoised CMRA Coronal View')
ax[0, 1].axis('off')
ax[0, 2].imshow(np.abs(MIP_CMRA_Cor), cmap='gray')
ax[0, 2].set_title('MIP CMRA Coronal View')
ax[0, 2].axis('off')
ax[1, 0].imshow(np.abs(denoised_image_CMRA_Ax[:, :, 32]), cmap='gray')
ax[1, 0].set_title('Denoised CMRA Axial View')
ax[1, 0].axis('off')
ax[1, 1].imshow(np.abs(denoised_image_CMRA_Sag[:, :, 32]), cmap='gray')
ax[1, 1].set_title('Denoised CMRA Sagittal View')
ax[1, 1].axis('off')
ax[1, 2].imshow(np.abs(MIP_CMRA_Sag), cmap='gray')
ax[1, 2].set_title('MIP CMRA Sagittal View')
ax[1, 2].axis('off')

plt.savefig('Carotid Visualization with MIPs.png', bbox_inches='tight')
plt.show()

""" # Save the entire denoised volume as DICOM
print("Saving denoised volume as DICOM...")
# Create a new DICOM dataset based on the original
ds = pydicom.dcmread(fpath)
# Update pixel data with denoised image
# Note: Need to reorder back to original dimensions if necessary
denoised_for_dicom = np.moveaxis(np.abs(denoised_image_CMRA_Ax), -1, 0).astype(np.uint16)
ds.PixelData = denoised_for_dicom.tobytes()
ds.save_as('denoised_CMRA_Ax.dcm')
print("Denoised volume saved as 'denoised_CMRA_Ax.dcm'") """

""" # Also keep the PNG saves for reference
num_slices = denoised_image_CMRA_Ax.shape[2]
print(f"Saving additional slices as PNG (total: {num_slices})...")
for slice_idx in range(0, num_slices, 10):  # Save every 10th slice
    plt.figure()
    plt.imshow(np.abs(denoised_image_CMRA_Ax[:, :, slice_idx]), cmap='gray')
    plt.title(f'Denoised CMRA Axial Slice {slice_idx}')
    plt.axis('off')
    plt.savefig(f'denoised_CMRA_Ax_slice_{slice_idx}.png', bbox_inches='tight')
    plt.close()
    print(f"Saved slice {slice_idx} as 'denoised_CMRA_Ax_slice_{slice_idx}.png'")
print("Additional slices saved.") """

