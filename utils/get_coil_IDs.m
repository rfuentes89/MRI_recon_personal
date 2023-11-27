function sorted_IDs = get_coil_IDs(twix)

    coil_info = twix{end}.hdr.MeasYaps.sCoilSelectMeas.aRxCoilSelectData{1}.asList;
    
    coil_IDs = convertCharsToStrings(cellfun(@(s) s.sCoilElementID.tElement{1}, coil_info, "UniformOutput", false));
    ADC_channels = cellfun(@(s) s.lADCChannelConnected, coil_info);

    [~, coil_ordering] = sort(ADC_channels);

    sorted_IDs = coil_IDs(coil_ordering);

end

