function M = GDF_creator(events, codes, file_name)
% INPUT:
%   timestamps for events: a ts object, a vector, or a cell array of ts objects.
%   A code to associate with these events. 
%   a filename for the gdf file.
%
% OUTPUT
%   a text file that contains the timestamps and event codes as one matrix.
%   event_code   timestamp
%      22           1010010
%      .....


M = Event_merge(events, codes);

fid = fopen(file_name,'w');
fprintf(fid, '%d \t %d \n', M(:,[2,1])');
fclose(fid);