
import time
import pydicom
from hd_prost import denoising_hd_prost
import numpy as np
import matplotlib.pyplot as plt

## Load images T2prep= 60ms
fpathBrB_Cor_60 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Cor_60slices_30seg_0.8mm_60ms_NoMOCO_BrightBlood_6_MR/1.dcm";
fpathBB_Cor_60 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Cor_60slices_30seg_0.8mm_60ms_NoMOCO_BlackBlood_8_MR/1.dcm";
fpathBrB_Ax_60 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Ax_60slices_30seg_0.8mm_60ms_NoMOCO_BrightBlood_12_MR/1.dcm";
fpathBB_Ax_60 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Ax_60slices_30seg_0.8mm_60ms_NoMOCO_BlackBlood_14_MR/1.dcm";
fpathRef_Ax_60 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Ax_60slices_30seg_0.8mm_60ms_NoMOCO_LongTI_13_MR/1.dcm";
fpathRef_Cor_60 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Cor_60slices_30seg_0.8mm_60ms_NoMOCO_LongTI_7_MR/1.dcm";

#Loading images T2prep= 50ms

fpathBrB_Cor_50 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Cor_60slices_30seg_0.8mm_NoMOCO_BrightBlood_3_MR/1.dcm";
fpathBB_Cor_50 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Cor_60slices_30seg_0.8mm_NoMOCO_BlackBlood_5_MR/1.dcm";
fpathBrB_Ax_50 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Ax_60slices_30seg_0.8mm_NoMOCO_BrightBlood_9_MR/1.dcm";
fpathBB_Ax_50 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Ax_60slices_30seg_0.8mm_NoMOCO_BlackBlood_11_MR/1.dcm";
fpathRef_Ax_50 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Ax_60slices_30seg_0.8mm_NoMOCO_LongTI_10_MR/1.dcm";
fpathRef_Cor_50 = "/mnt/workspace/rfuentes/recon/2025-09-05/dcm/BOOST_MLEV4_Cor_60slices_30seg_0.8mm_NoMOCO_LongTI_4_MR/1.dcm";

'''fpath = [fpathBrB_Cor_50, fpathBB_Cor_50, fpathBrB_Ax_50, fpathBB_Ax_50, fpathRef_Ax_50, fpathRef_Cor_50,
         fpathBrB_Cor_60, fpathBB_Cor_60, fpathBrB_Ax_60, fpathBB_Ax_60, fpathRef_Ax_60, fpathRef_Cor_60]
'''

# Loading volumes
BrB_Cor_60 = pydicom.dcmread(fpathBrB_Cor_60).pixel_array
BrB_Ax_60 = pydicom.dcmread(fpathBrB_Ax_60).pixel_array
Ref_Ax_60 = pydicom.dcmread(fpathRef_Ax_60).pixel_array
Ref_Cor_60 = pydicom.dcmread(fpathRef_Cor_60).pixel_array
BrB_Cor_50 = pydicom.dcmread(fpathBrB_Cor_50).pixel_array
BrB_Ax_50 = pydicom.dcmread(fpathBrB_Ax_50).pixel_array
Ref_Ax_50 = pydicom.dcmread(fpathRef_Ax_50).pixel_array
Ref_Cor_50 = pydicom.dcmread(fpathRef_Cor_50).pixel_array
BB_Cor_50 = pydicom.dcmread(fpathBB_Cor_50).pixel_array
BB_Ax_50 = pydicom.dcmread(fpathBB_Ax_50).pixel_array
BB_Cor_60 = pydicom.dcmread(fpathBB_Cor_60).pixel_array
BB_Ax_60 = pydicom.dcmread(fpathBB_Ax_60).pixel_array

#Reorder dimensions to (height, width, depth)
BrB_Cor_60 = np.moveaxis(BrB_Cor_60, 0, -1)
BrB_Ax_60 = np.moveaxis(BrB_Ax_60, 0, -1)
Ref_Ax_60 = np.moveaxis(Ref_Ax_60, 0, -1)
Ref_Cor_60 = np.moveaxis(Ref_Cor_60, 0, -1)
BrB_Cor_50 = np.moveaxis(BrB_Cor_50, 0, -1)
BrB_Ax_50 = np.moveaxis(BrB_Ax_50, 0, -1)
Ref_Ax_50 = np.moveaxis(Ref_Ax_50, 0, -1)
Ref_Cor_50 = np.moveaxis(Ref_Cor_50, 0, -1)
BB_Cor_50 = np.moveaxis(BB_Cor_50, 0, -1)
BB_Ax_50 = np.moveaxis(BB_Ax_50, 0, -1)
BB_Cor_60 = np.moveaxis(BB_Cor_60, 0, -1)
BB_Ax_60 = np.moveaxis(BB_Ax_60, 0, -1)

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
#Apply HD-PROST Denoising
denoised_image_BrB_Ax_60 = denoising_hd_prost(BrB_Ax_60, **params)
denoised_image_BrB_Ax_50 = denoising_hd_prost(BrB_Ax_50, **params)
denoised_image_BrB_Cor_60 = denoising_hd_prost(BrB_Cor_60, **params)
denoised_image_BrB_Cor_50 = denoising_hd_prost(BrB_Cor_50, **params)
denoised_image_Ref_Ax_60 = denoising_hd_prost(Ref_Ax_60, **params)
denoised_image_Ref_Ax_50 = denoising_hd_prost(Ref_Ax_50, **params)
denoised_image_Ref_Cor_60 = denoising_hd_prost(Ref_Cor_60, **params)
denoised_image_Ref_Cor_50 = denoising_hd_prost(Ref_Cor_50, **params)
denoised_image_BB_Ax_50 = denoising_hd_prost(BB_Ax_50, **params)
denoised_image_BB_Ax_60 = denoising_hd_prost(BB_Ax_60, **params)
denoised_image_BB_Cor_50 = denoising_hd_prost(BB_Cor_50, **params)
denoised_image_BB_Cor_60 = denoising_hd_prost(BB_Cor_60, **params)

end_time = time.time()
print(f"Denoising completed in {end_time - start_time:.2f} seconds")

#Removing singleton dimensions
denoised_image_BrB_Ax_60 = np.squeeze(denoised_image_BrB_Ax_60)
denoised_image_BrB_Ax_50 = np.squeeze(denoised_image_BrB_Ax_50)
denoised_image_BrB_Cor_60 = np.squeeze(denoised_image_BrB_Cor_60)
denoised_image_BrB_Cor_50 = np.squeeze(denoised_image_BrB_Cor_50)
denoised_image_Ref_Ax_60 = np.squeeze(denoised_image_Ref_Ax_60)
denoised_image_Ref_Ax_50 = np.squeeze(denoised_image_Ref_Ax_50)
denoised_image_Ref_Cor_60 = np.squeeze(denoised_image_Ref_Cor_60)
denoised_image_Ref_Cor_50 = np.squeeze(denoised_image_Ref_Cor_50)
denoised_image_BB_Ax_50 = np.squeeze(denoised_image_BB_Ax_50)
denoised_image_BB_Ax_60 = np.squeeze(denoised_image_BB_Ax_60)
denoised_image_BB_Cor_50 = np.squeeze(denoised_image_BB_Cor_50)
denoised_image_BB_Cor_60 = np.squeeze(denoised_image_BB_Cor_60)

### Difference Images
my_BB_Ax_60 = np.abs(denoised_image_Ref_Ax_60) - np.abs(denoised_image_BrB_Ax_60);
my_BB_Cor_50 = np.abs(denoised_image_Ref_Cor_50) - np.abs(denoised_image_BrB_Cor_50);
my_BB_Cor_60 = np.abs(denoised_image_Ref_Cor_60) - np.abs(denoised_image_BrB_Cor_60);
my_BB_Ax_50 = np.abs(denoised_image_Ref_Ax_50) - np.abs(denoised_image_BrB_Ax_50);

# Set negative values to zero
my_BB_Ax_50[my_BB_Ax_50 < 0] = 0;
my_BB_Cor_50[my_BB_Cor_50 < 0] = 0;
my_BB_Cor_60[my_BB_Cor_60 < 0] = 0;
my_BB_Ax_60[my_BB_Ax_60 < 0] = 0;
denoised_image_BB_Cor_60[denoised_image_BB_Cor_60 < 0] = 0;
denoised_image_BB_Ax_60[denoised_image_BB_Ax_60 < 0] = 0;
denoised_image_BB_Cor_50[denoised_image_BB_Cor_50 < 0] = 0;
denoised_image_BB_Ax_50[denoised_image_BB_Ax_50 < 0] = 0;

## Plot results

fig, axes = plt.subplots(2, 2, figsize=(10, 6))

axes[0, 0].imshow(np.abs(denoised_image_BB_Ax_60[:, :, 39]), cmap="gray")
axes[0, 0].set_title("BB Ax Image 60ms")
axes[0, 0].axis("off")

axes[0, 1].imshow((my_BB_Ax_60[:, :, 39]), cmap="gray")
axes[0, 1].set_title("My BB Ax Image 60ms")
axes[0, 1].axis("off")

axes[1, 0].imshow(np.abs(denoised_image_BB_Cor_60[:, :, 39]), cmap="gray")
axes[1, 0].set_title("BB Cor Image 60ms")
axes[1, 0].axis("off")

axes[1, 1].imshow((my_BB_Cor_60[:, :, 39]), cmap="gray")
axes[1, 1].set_title("My BB Cor Image 60ms")
axes[1, 1].axis("off")

plt.tight_layout()
plt.show()
plt.savefig('my_denoising_60ms_2.png')
#plt.tight_layout()
#plt.show()

""" plt.figure(1)
plt.savefig('my_BB_Ax_60ms.png', bbox_inches='tight')
plt.figure(2)
plt.savefig('my_BrB_Ax_60ms.png', bbox_inches='tight')
plt.figure(3)
plt.savefig('my_BB_Cor_60ms.png', bbox_inches='tight')
plt.figure(4)
plt.savefig('my_BrB_Cor_60ms.png', bbox_inches='tight') """

#plt.close(fig)