function [S, TetID_ClustID] = Load_spikes_from_hyper5_tfl_files(tfl_file_names,isBigEndian)
% Loads the legacy tfl data.
% INPUT: a cell array list of the .tfl file names.
%        isBigEndian - default is 1 - for PCs and macs typically. Unix may
%        differ.
% OUTPUT: cell array of spikes.
%
% cowen 2013
if nargin < 2
    isBigEndian = 1;
end

S = cell(length(tfl_file_names),1);
TetID_ClustID = zeros(length(tfl_file_names{1}),2);
TetID_ClustID_first = zeros(length(tfl_file_names{1}),2);

for iTFlist= 1:length(tfl_file_names)
    fp = fopen(tfl_file_names{iTFlist},'r');
    tfiles = textscan(fp,'%s\n');
    tfiles = tfiles{1};
    fclose(fp);
    
    % Clean these up
    for ii = 1:length(tfiles)
        % find the bad string.
        ix = strfind(tfiles{ii},'tfiles');
        tfiles{ii}(1:(ix-1)) = [];
        tfiles{ii} = strrep(tfiles{ii}, 'tfiles','.');
        % Extract the tetrode ID and the cell ID.
        ix = strfind(tfiles{ii},'/');
        %
        TetID_ClustID(ii,1) = str2double(tfiles{ii}(ix(1)+5:(ix(2)-1)));
        ix = strfind(tfiles{ii},'.');
        TetID_ClustID(ii,2) = str2double(tfiles{ii}(ix(2)+1:(ix(3)-1)));
        
    end
    if iTFlist > 1
        % Double check alignment of all records...
        if any(TetID_ClustID ~= TetID_ClustID_first)
            error('tfile lists are not in alignment!')
        end
    else
        TetID_ClustID_first = TetID_ClustID;
    end
    
    % Load the spikies.
    S{iTFlist} = Load_tfiles(tfiles,isBigEndian);
end


