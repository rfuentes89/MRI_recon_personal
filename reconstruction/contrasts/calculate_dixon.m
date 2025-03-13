function [water_image, fat_image] = calculate_dixon(in_phase_image, opp_phase_image)
%CALCULATE_DIXON Produce fat and water image from two contrasts
    in_image = abs(in_phase_image);
    opp_image = abs(opp_phase_image);
    water_image = 0.5 * (opp_image + in_image);
    fat_image = 0.5 * (opp_image - in_image);
end
