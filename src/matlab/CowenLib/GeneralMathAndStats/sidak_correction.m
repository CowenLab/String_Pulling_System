%
function [corrected_alpha]=sidak_correction(n_comparisons)
alpha = 0.05;
corrected_alpha =  1 - (1 - alpha)^(1 / n_comparisons) ;