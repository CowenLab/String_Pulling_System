function [TC,Occ] = TuningCurves_CircularTrack( S, track_radius_cm, linearized_position_data_cm, desired_bin_size_cm)
%function [TC,Occ] = TuningCurves_CircularTrack( S, track_radius_cm, linearized_position_data_cm, desired_bin_size_cm)
%
% Return the place fields and occupancy for a circular track - a simple extension of
% TuningCurves.
%
% INPUT:
%   S - cell array of ts objects.
%   track_radius_cm = the radius of the track in question - used to
%     calculate the number of bins.
%   linearized_position_data_cm - the position data in centimeters -
%     converted to linear position and normalized to centimeters (e.g. =
%     (pos_data_theta/(2*pi))*track_circumference (not length - the
%     circumference (2*pi*radius)).
%  OUTPUT:
%   TC - cell array of tuning curves for each neuron.
%   Occ - Occupancy matrix.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2006
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
track_length_cm   = 2*pi*track_radius_cm;
nBins             = ceil(track_length_cm/desired_bin_size_cm); % the number of bins to create.
[TC,Occ]          = TuningCurves(S, linearized_position_data_cm, nBins);
