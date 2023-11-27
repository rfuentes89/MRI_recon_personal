%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% HD-PROST parameters %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

This file explaines the different parameters and gives the options :-)

 Inputs:
       | input       : 2D / 3D / 2D+c / 3D+c images to denoise
       | sig         : singular value thresholding parameter
       | patch_sz    : size of 3D patches
       | max_patch   : maximum number of similar 3D patches to search
       | win         : size of search window
       | offset      : offset between patches (to accelerate the reconstruction)
       |               no visual difference was seen between offset = 1 and offset = 4 (but x4 faster)
       | debug       : display information when debug==1
       | recon_mode  : 1 (2D multi contrast), 2 (3D multi contrast), 3 (2D single contrast), 4 (3D single contrast)
 
 Outputs:
       output : denoised volume

 Recon Mode:
    (1)  2D multi contrast
    (2)  3D multi contrast
    (3)  2D single contrast
    (4)  3D single contrast
    (5)  2D multi contrast (complex)
    (6)  3D multi contrast (complex)
    (7)  3D single contrast (complex)
    (8)  2D single contrast (complex)
    (9)  2D single contrast
    (10) 2D multi contrast (complex)
    (11) 2D single contrast multiple cardiac phases (MB-PROST)
    (12) 3D single contrast multiple cardiac phases
    (13) 2D multi contrast multiple cardiac phases (complex)
 
 
Thresholding type:
    (0) simple thresholding
        threshold = sqrt(2*log(patch_length*nb_patch_LR)) * sig; // sig a simple threshold
    (1) (%) highest singular value
        threshold = fabs(gsl_vector_get(S,0)) * sig;  // sig is a percentage
        threshold = fabs(gsl_vector_get(S,0)) - fabs(gsl_vector_get(S,0)) * sig / 100;  // sig is a percentage
    (2) fixed rank (sig)
        threshold = sigma
        