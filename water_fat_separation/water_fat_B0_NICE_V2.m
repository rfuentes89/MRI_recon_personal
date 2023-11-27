function output_params = water_fat_B0_NICE_V2(image_data, CREAM_PDFF_path)

    algo_params = ReadYaml(fullfile(CREAM_PDFF_path, "algoParams/B0NICE_algoParams.yml"));
    model_params = ReadYaml(fullfile(CREAM_PDFF_path, "modelParams/CustommodelParams.yml"));

    [species, spectrum] = setupModelParams(model_params);
    algo_params.gyro = spectrum.gyro;
    algo_params.species = species;

    output_params = B0NICE_main(image_data, algo_params);

end

