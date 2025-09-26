
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

fpath = [fpathBrB_Cor_50, fpathBB_Cor_50, fpathBrB_Ax_50, fpathBB_Ax_50, fpathRef_Ax_50, fpathRef_Cor_50,
         fpathBrB_Cor_60, fpathBB_Cor_60, fpathBrB_Ax_60, fpathBB_Ax_60, fpathRef_Ax_60, fpathRef_Cor_60]

image = pydicom.dcmread(fpath).pixel_array
image = np.moveaxis(image, 0, -1) # reorder to (height, width, depth)

# Denoising Parameters
class Params:
    pass

params = Params()
params.sig = 0.50
params.debug = 3
params.recon_mode = 4
params.patch_sz = 7
params.type = 0
params.win = 20
params.sharpness = 0.0

#Apply HD-PROST Denoising
denoised_image_BrB_Ax_60 = denoising_hd_prost(image, sigma=0.65, verbose=3, recon_mode=4)
denoised_image_BrB_Ax_50 = denoising_hd_prost(image, sigma=0.65, verbose=3, recon_mode=4)
denoised_image_BrB_Cor_60 = denoising_hd_prost(image, sigma=0.65, verbose=3, recon_mode=4)
denoised_image_BrB_Cor_50 = denoising_hd_prost(image, sigma=0.65, verbose=3, recon_mode=4)
denoised_image_Ref_Ax_60 = denoising_hd_prost(image, sigma=0.65, verbose=3, recon_mode=4)
denoised_image_Ref_Ax_50 = denoising_hd_prost(image, sigma=0.65, verbose=3, recon_mode=4)
denoised_image_Ref_Cor_60 = denoising_hd_prost(image, sigma=0.65, verbose=3, recon_mode=4)
denoised_image_Ref_Cor_50 = denoising_hd_prost(image, sigma=0.65, verbose=3, recon_mode=4)

denoised_image_BrB_Ax_60 = np.squeeze(denoised_image_BrB_Ax_60)
denoised_image_BrB_Ax_50 = np.squeeze(denoised_image_BrB_Ax_50);
denoised_image_BrB_Cor_60 = np.squeeze(denoised_image_BrB_Cor_60);
denoised_image_BrB_Cor_50 = np.squeeze(denoised_image_BrB_Cor_50);
denoised_image_Ref_Ax_60 = np.squeeze(denoised_image_Ref_Ax_60);
denoised_image_Ref_Ax_50 = np.squeeze(denoised_image_Ref_Ax_50);
denoised_image_Ref_Cor_60 = np.squeeze(denoised_image_Ref_Cor_60);
denoised_image_Ref_Cor_50 = np.squeeze(denoised_image_Ref_Cor_50);

### Difference Images
my_BB_Ax_60 = abs(denoised_image_Ref_Ax_60) - abs(denoised_image_BrB_Ax_60);
my_BB_Cor_50 = abs(denoised_image_Ref_Cor_50) - abs(denoised_image_BrB_Cor_50);
my_BB_Cor_60 = abs(denoised_image_Ref_Cor_60) - abs(denoised_image_BrB_Cor_60);
my_BB_Ax_50 = abs(denoised_image_Ref_Ax_50) - abs(denoised_image_BrB_Ax_50);

## Plot results
#slice_idx = denoised_image.shape[2] // 2

fig, axes = plt.subplots(1, 2, figsize=(12, 6))

axes[0].imshow(np.abs(my_BB_Ax_60[:, :, 42]), cmap="gray")
axes[0].set_title("BB Image 60ms")
axes[0].axis("off")

axes[1].imshow(np.abs(denoised_image_BrB_Ax_60[:, :, 42]), cmap="gray")
axes[1].set_title("BrB Image 60ms")
axes[1].axis("off")

plt.tight_layout()
plt.show()