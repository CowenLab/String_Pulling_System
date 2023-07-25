function [SP, TS] = Load_All_Spikes_File(fname, cell_quality_or_ID,make_artificial_data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [SP, TS] = Load_All_Spikes_File(fname, cell_quality_or_ID)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load the All_spikes file specified in fname.
% BUT if requested, add new info like depth and region.
% assumes a depth histor file in a root directory and a channel translation
% excel file.
%
% IF no arguments are passed in, it assumes that you are in a data
% directory and that the channel_translation_table is located in a
% directory above.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen(2009)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3
    % If this is true, then create an artificial dataset of regularly
    % spiking neurons - some with random ISIs, some with fixed, but all
    % with the same mean rate as the original cells.
    make_artificial_data = false;
end

if nargin <2
     
    cell_quality_or_ID = [];
end

if nargin ==0
    fname = 'tfiles/All_Spikes.mat';
end


if isempty(cell_quality_or_ID)
    cell_quality_or_ID = 2;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load all spikes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TS = []; SP = [];
load(fname)

% FILTER THE OUTPUT BY CELL QUALITY!

goodix = [];
if cell_quality_or_ID(1) > 100000
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Specific cells were requested.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for ii = 1:length(SP)
        if ismember(SP{ii}.CID,cell_quality_or_ID)
            goodix = [goodix; ii];
        end
    end
else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Restrict to quality of 2 or higher.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for ii = 1:length(SP)
        if SP{ii}.SubjectiveClusterQuality >= cell_quality_or_ID
            goodix = [goodix; ii];
        end
    end
end

SP = SP(goodix);
TS = TS(goodix);

if make_artificial_data
    % Output ARTIFICIAL DATA TO TEST ASSUMTIONS. These data are random but
    % with the same spiking characteristics as the original cells- just
    % with shuffled ISIs, regular spiking intervals, or random intervals.
    disp('WARNING: USING ARTIFICIAL SPIKE TRAINS!!!')
    
    random_type = 'shuffle';
    
    for ii = 1:length(SP)
        switch random_type
            case 'shuffle'
                % This preserves the ISI perfectly.
                d = diff(SP{ii}.SpikeTimes);
                d = [0; d(randperm(length(d)))];
                st = SP{ii}.SpikeTimes(1) + cumsum(d);
            case 'fixed_isi'
                % A fixed interspike interval
                mdd = mean(diff(SP{ii}.SpikeTimes));
                d = repmat(mdd, length(SP{ii}.SpikeTimes),1);
                st = SP{ii}.SpikeTimes(1) + cumsum(d);
        end
        SP{ii}.SpikeTimes = st;
        TS{ii} = st;
        
    end
end
