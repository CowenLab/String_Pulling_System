function [bn id]= binned(start_and_end_times, dt,shift_dt);
%function [bn id]= binned(start_and_end_times, dt,shift_dt);
% 
% Bin within passed in intervals. 
%
% INPUT: n,2 matrix of start and end times
%        a bin size.
%        *optional* shift_dt - if it's a sliding window, this specifies the 
%          shift of the slide.
% OUTPUT:
%        start and end times of each bin where the intervals in
%        start_and_end_times are divided into bins of size dt. Any
%        bins that go beyond the end times are eliminated.
%        end times have a slight amount subtracted so that they are 
%        not equivalent to the start time.
%
%        id = the interval id of each bin.
% NOTE: ONCE IN AN WHILE THIS PRODUCES A NUMBER OF BINS THAT IS NOT EQUAL
% TO A PREVIOUS CALL WITH THE SAME PARAMETERS _ MUST BE A ROUNDING ERRROR>
%function bn = binned(start_and_end_times, dt);
% cowen
if nargin == 2
    shift_dt = [];
end
S = cell(size(start_and_end_times,1),1);
E = cell(size(start_and_end_times,1),1);
ID = cell(size(start_and_end_times,1),1);
for ii = 1:size(start_and_end_times,1)
    if isempty(shift_dt)
        s = start_and_end_times(ii,1):dt:start_and_end_times(ii,2);
    else
        s = start_and_end_times(ii,1):shift_dt:start_and_end_times(ii,2);
    end
    e = s + dt ;
    idx = find(e > start_and_end_times(ii,2));
    %e = e - 0.0000001; % Presume that some other program deals with the
    %edges with a >< - the problem with this 0.000001 is that it causes
    %some C code to crash as matlab produces some wierd roundoff errors.
    if ~isempty(idx)
        e(idx) = [];
        s(idx) = [];
    end
   % if e(end) > start_and_end_times(ii,2)
   %     e(end) = [];
   %     s(end) = [];
   % end
   S{ii} = s(:);
   E{ii} = e(:);
   ID{ii} = ones(length(s),1)*ii;

%    bn = [bn; s(:) e(:)];
%    id = [id; ones(length(s),1)*ii];
end
bn = [cell2mat(S) cell2mat(E)];
id = cell2mat(ID);
% Resort to make sure it is ascending. 
[bn idx]= sortrows(bn);
id = id(idx);