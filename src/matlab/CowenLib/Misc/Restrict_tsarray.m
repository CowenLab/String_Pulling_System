function A = Restrict_tsarray(tsa, stime, etime)
%function A = Restrict_tsarray(tsa, stime, etime)
% 
% Restrict every element in a ts array to be between the same periods
% of time.
%
% INPUT: 
%       tsa = array of ts or tsd or ctsd objects
%     stime = start time in time stamps
%     etime = end time in time stamps
%   
%     you can also just pass in an nx2 matrix of start and end times for stime.
%
% OUTPUT:
%     A     = a cell array of objects restricted to the specified
%     times.
%
% cowen Fri Jul  2 17:05:41 1999

% make the lenght of A be equal to tsa.
A{length(tsa)} = [];

% Assume you sent in an nx2 array of start and end times.
if nargin == 2,
  X = stime;
  stime = X(:,1);
  etime = X(:,2);
end

% Go through each element and restrict it to the times passed
for ii = 1:length(tsa)
    if ~isempty(tsa{ii})
        A{ii} = Restrict(tsa{ii}, stime, etime);
     else
        A{ii} = ts;
    end
end
