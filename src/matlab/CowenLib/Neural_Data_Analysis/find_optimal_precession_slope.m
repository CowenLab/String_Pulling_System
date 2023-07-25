function [precession_shift_pos_per_phase, info] = find_optimal_precession_slope(phase_position, phase_smoothing_winsize, pf_size, plot_it)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find the optimal slope of precession given the phase and position
% information passed into the function.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% INPUT: phase_position: 2 col matrix of phase and position
%        phase_smoothing_winsize: Size of the smoothing window for phase.
%          For instance, if your phase data is in degrees, a val of 15 would
%          smooth with a hamming window of size 15 degrees.
%        pf_size: size of a pf in the same units as in phase_position(:,2)
%        plot_it: optional - show a pretty movie 
% OUTPUT: precession_shift_phase_per_pos: How many cm you need to shift for
%           every degree of precession in order to reach maximal variance.
%           For instance, if you have a value of -0.03 then over 360
%           degrees, the field shifts or precesses a total of 360*.03 or 10 cm.
%
%         info: a structure with miscellaneous data assocaited with the
%           rotation.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
min_phase_position = min(phase_position);
max_phase_position = max(phase_position);

phase_bins    = 100;
position_bins = 200;

bins_per_pos   = position_bins/(max_phase_position(2) - min_phase_position(2));
bins_per_phase = phase_bins   /(max_phase_position(1) - min_phase_position(1));
pos_per_bin    = 1/bins_per_pos;   % Redundant but it makes things more readable later on.
phase_per_bin  = 1/bins_per_phase;

% Histogram in 2D
h2_occ = ndhist(phase_position',[phase_bins; position_bins], min_phase_position',max_phase_position' ); 

% Smooth
pos_hamming_window   = ceil(bins_per_pos * pf_size/2);
phase_hamming_window = ceil(bins_per_phase * phase_smoothing_winsize);
h2_occ = conv2(h2_occ,hanning(phase_hamming_window)*hanning(pos_hamming_window)','valid');

pos_xdim   = linspace(min_phase_position(2),max_phase_position(2),size(h2_occ,2));
phase_xdim = linspace(min_phase_position(1),max_phase_position(1),size(h2_occ,1));

% Plot the data.
if plot_it
    figure;
end
% Rotate in degrees.
tmp_h2_occ = h2_occ;
x_shift_range_bins = -1:0.02:1; % (1/x_shift_range_bins  = slope in phase/pos)
x_shift_range_pos_per_unit_phase = x_shift_range_bins*(pos_per_bin/phase_per_bin);

% Convert to degrees of rise over cm or pixels of run.
V = zeros(1,length(x_shift_range_bins));
for ii = 1:length(x_shift_range_bins)
    tmp_h2_occ = rotate_angular_linear_matrix(h2_occ, x_shift_range_bins(ii));
    V(ii) = var(mean(tmp_h2_occ));
    % optional - just take the central portion.
    %mn = mean(tmp_h2_occ);
       
    % Make a movie.
    if plot_it
        [m,max_ix] = max(V(1:ii));
        subplot(5,1,1:3)
        imagesc(pos_xdim, phase_xdim, tmp_h2_occ)
        title(['Ratio: ' num2str(x_shift_range_bins(ii)) ' Variance: ' num2str(V(ii))])
        ylabel('phase')
        
        %axis xy
        subplot(5,1,4)
        bar(mean(tmp_h2_occ))
        axis tight
        xlabel('position')
        ylabel('mean')
        title([])
        subplot(5,1,5)
        
        plot(x_shift_range_bins(1:ii),V(1:ii))
        xlabel('shift')
        ylabel('var')
        axis tight
        pause(.1)
    end
end
% find the point of maximal variance. The slope at that point is the slope
% of precession.
[mx,ix] = max(V);
%
precession_shift_pos_per_phase = x_shift_range_pos_per_unit_phase(ix);
%precession_shift_bins = x_shift_range_bins(ix);
if nargout ==2
    info.slope_range = x_shift_range_bins;
    info.variance = V;
    info.phase_position_matrix = h2_occ;
    info.pos_xdim = pos_xdim;
    info.phase_xdim = phase_xdim;
    info.x_shift_range_pos_per_unit_phase = x_shift_range_pos_per_unit_phase;
end
