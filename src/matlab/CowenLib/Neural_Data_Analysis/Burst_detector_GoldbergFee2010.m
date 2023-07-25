function [OUT] = Burst_detector_GoldbergFee2010(T_ms)
% INPUT: 
%   T =  vector of tiestamps
% for zebrafinch data for detecting HF1 vs HF2 pallidal neurons.
% Goldberg and free got the best results when they looked at the PEAK in
% teh IFR - separated the HF1 (High peak) and HF2 cells (Low peak) 
% OUTPUT:
[Q,Qs] = Instantaneous_Firing_Rat(T_ms, 5, 10,true);
