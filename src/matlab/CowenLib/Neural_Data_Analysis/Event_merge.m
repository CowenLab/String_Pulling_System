function M = Event_merge(events, codes)
% INPUT:
%   timestamps for events: a ts object, or a cell array of ts objects or a cell array of vectors.
%   A code to associate with these events (each cell in the cell array). 
% 
% OUTPUT:
%   A matrix where the first column is the event time and the second
%   spike time     event id
%       100101         1
%       203020         1
%       403000         2 ...
%
% This is very useful for some programs that require events to be ordered and saved this way.
% I believe neural explorer and the JPSTH programs require this. This program was 
% written for the JPSTH program pcjpsth from the Gernstein lab.
%

% cowen
if ~iscell(events)
    a = events;
    clear events;
    events{1} = a;
end
    
M = [];
for ii = 1:length(events)
    if isa(events{ii},'ts')
        events{ii} = Data(events{ii});
    end
    M = [M; events{ii}(:) repmat(codes(ii),length(events{ii}(:)),1)];
end
M = sortrows(M);