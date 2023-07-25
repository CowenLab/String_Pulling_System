function [D,T] = Cut_out_times(data, times, timestamps)
%
% INPUT : data = matrix to cut out
%         times = the times associated with each column in the matrix
%         timestamps = a matrix of start and end times [start end;start end;...]
%
% OUTPUT: D-- A matrix reduced to the times in question
%         T-- The timestamps associated with each column in the
%         matrix.
%
%function [D,T] = Cut_out_times(data, times, timestamps)

% cowen Wed Jul 21 17:39:16 1999
[rdata, cdata] = size(data);
[rtimestamps, ctimestamps] = size(timestamps);
D = zeros(rdata,1);
T = 0;


counter = 1;
ii = 1;
done = 0;
% Go through the timestamp and Q data and copy the columns that are
% within the timestamp range.
while(ii <= rtimestamps & ~done)
  
  while times(counter) <= timestamps(ii,2) 
    if times(counter) >= timestamps(ii,1) 
      T = [T, times(counter)];
      D = [D, data(:,counter)];
    end
    counter = counter + 1; %Track the counter on the data 
    % Check to see if we are the end of the data.
    if counter > length(times)
      done = 1;
      break
    end
  end
  ii = ii + 1;
end

% Get rid of the first dummy column.

T(1) = [];
D(:,1) = [];
