function [bad_times,good_times,BIX,PAR] = Clean_LFP(LFP,sFreq,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cleans LFP data. Only returns the times or indices of bad or good stuff as 
% it is up to the caller to either zero or nan the bad stuff or cut it out.
% GIX (good indices) would be ~BIX so I do not bother passing that out.
% 
% INPUT: LFP = 2col - ist col time, 2nd data 
% sFreq of the LFP
% optional args - see code.
% Cowen 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
remove_high_voltage_spindles = false;
artifact_thresh = 2000;
buffer_win_pts = sFreq*1;

Extract_varargin;

BIX = abs(LFP(:,2))>artifact_thresh;

if remove_high_voltage_spindles
    [PAR.hvs_times_s, ~, PAR.no_hvs_times_s,HVS_IX] = High_voltage_spindle_detector(LFP,sFreq);
    BIX = BIX | HVS_IX;
end

BIX = conv(BIX,ones(1,buffer_win_pts),'same');
BIX = BIX>0;
% Look for snippets that are just too short...
C = Count_contiguous(~BIX);
mobad = C > 0 & C<buffer_win_pts;
% figure;plot(BIX);hold on; plot(mobad+.1); axis off
BIX = BIX | mobad(:);
[bad_times_ix, good_times_ix, bad_IX, good_IX] = find_intervals(BIX,.4);
bad_times(:,1) = LFP(bad_times_ix(:,1),1);
bad_times(:,2) = LFP(bad_times_ix(:,2),1);
good_times = [LFP(good_times_ix(:,1),1) LFP(good_times_ix(:,2),1)];

if nargout == 0
    figure
    plot(LFP(:,1),LFP(:,2));
    axis tight
    hold on
    plot_markers_simple(bad_times)
    
end
