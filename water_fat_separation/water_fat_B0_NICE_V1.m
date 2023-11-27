function output_params = water_fat_B0_NICE_V1(image_data)

    algoParams.complex_image = image_data.images;

    algoParams.TE_seq = image_data.TE;    
    algoParams.B0_strength = image_data.FieldStrength;

    algoParams.delta_TE4B0 = 2 * (algoParams.TE_seq(2) - algoParams.TE_seq(1));
    
    algoParams.Acq = 1; % 1 for bipolar, 0 for unipolar
    
    algoParams.th4fat = 1.5; % 0.1
    algoParams.FILTsize = 8; % 11
    
    algoParams.flag_debug = 0;

    [algoParams] = determineInOutPhase(algoParams);
    [algoParams] = LinearPhaseErrorCorrection(algoParams);
    [algoParams] = B0NICEbd_buildingCOMPLEX(algoParams);

    algoParams.th4unwrap = 0;   % 0  %prctile slice by slice
    algoParams.th4supp = 20;    % 20 %prctile slice by slice
    algoParams.th4STAS = 40;    % 40 %prctile slice by slice
    algoParams.unwrap_mode = 3; % 2 for 2D PUROR; 3 for 3D PUROR
    [algoParams] = B0NICEbd_b0MAPPING(algoParams);

    [algoParams] = MagFatWaterMask(algoParams);

    algoParams.th4RegionDivision = -pi; 
    algoParams.minAreaUsingPhaseGradient = 20; % 20
    algoParams.minAreaUsingFlip = 100; % 100

    [algoParams] = B0NICEbd_GlobalCheckB0(algoParams);
    [algoParams] = B0NICEbd_inplane_RegionCheckB0(algoParams);
    [algoParams] = B0NICEbd_throughplane_RegionCheckB0(algoParams);
    [algoParams] = B0NICEbd_b0SaltPepperRemoval(algoParams);

    [fat_image, water_image] = B0NICEbd_FatWaterSepa(algoParams);

    output_params.W = water_image;
    output_params.F = fat_image;
    output_params.FF = 100 * fat_image ./ (water_image + fat_image);
    output_params.B0 = []; % TODO: can probably get this from algoParams
    output_params.R2 = []; % don't think this is modelled
