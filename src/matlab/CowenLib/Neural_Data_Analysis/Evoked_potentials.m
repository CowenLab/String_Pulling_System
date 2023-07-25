function [EP] = Evoked_potentials(eeg_file,event_timestamps, window_size_msec)
% Create evoked potentials for the events passed in.
%  This script loads in the times and creates n trial by window_size matrix of all of the evoked potentials
%  for a specific event.
window_size_msec = 500; % Size of window around evoked potential.
% Load the entire EEG file.

% Choose the times of the events to categorize.

