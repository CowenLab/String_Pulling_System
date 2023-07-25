function TSD_out = Cut_out_tsd(in_tsd, timestamps)
%function TSD_out = Cut_out_tsd(tsd, timestamps)
% 
% Input:
%       A tsd or a ts and a list of start and end
%       timestamps.
%
% Output:
%       Return a tsd of just those times. If you passed a ts, then the
%       function will return a ts. If you pass a tsd, it will return a tsd.
%

% NOTE Slow as hell. This is an option for mex coding.

switch(class(in_tsd))
  case 'ts'
    is_a_ts = 1;
    times = Data(in_tsd);
    data = zeros(size(times));
  case 'tsd'
    is_a_ts = 0;
    data = Data(in_tsd);
    times = Range(in_tsd, 'ts');
  otherwise
    error('incorrect input class');
end

% Make sure the timestamps are in the range of the input data.
%if min(times) < min(timestamps) | max(times) > max(timestamps)
%  error(' The input timestamps are out of range of the input ts/tsd');
%Wed Jan 20 17:28:53 1999end

% Initialize for main loop
[rtimestamps, ctimestamps] = size(timestamps);
OUT.data = [];
OUT.times = [];


counter = 1;
ii = 1;
% Go through the timestamp and Q data and copy the columns that are
% within the timestamp range.
while(ii <= rtimestamps )
  
  while times(counter) <= timestamps(ii,2) 
    if times(counter) >= timestamps(ii,1) 
      OUT.times = [OUT.times; times(counter)];
      OUT.data = [OUT.data; data(counter)];

    end
    counter = counter + 1; %Track the counter on the data 
    % Check to see if we are the end of the data.
    if counter > length(times)
      break
    end
  end
  ii = ii + 1;

end

if is_a_ts
  TSD_out = ts(OUT.times);
else
  TSD_out = tsd(OUT.times, OUT.data);
end
