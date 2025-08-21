function bb_image = calculate_black_blood(hb1_image, hb2_image)
%CALCULATE_BLACK_BLOOD Produce black blood image from BOOST's HB1/HB2 imgs
    bb_image = abs(hb2_image) - abs(hb1_image);
    bb_image(bb_image < 0) = 0;
end

