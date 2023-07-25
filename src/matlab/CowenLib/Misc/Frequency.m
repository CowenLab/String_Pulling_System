function F = Frequency(IN,interval);
%function F = Frequency(IN,interval);
%
% Return the firing rate of cells in a ts object or the sampling
% frequency of a tsd or cell array or Q matrix(which requires a dt).
%
% INPUT:
%     IN:  a ts tsd ctsa or a sparse or full matrix
%
%     interval:  an interval length in seconds (i.e. 400 sec) 
%        from which to calculate the frequency(because the
%        interval may not really begin with the StartTime of the cell
%        spiking.) If no interval is provided, it will be computed by
%        using (EndTime - StartTime)/10000. If an array of ts objects
%        is passed, then the time of the first spike in the entire
%        array is the start time and the last spike of the entire
%        array is the end time.
%
% OUTPUT:
%       F = the frequency in Hz. If it is a cell array then a vector
%       will be returned. 
%

% cowen Sun Mar 28 11:12:10 1999
%
%
if nargin == 1
  interval = 0;
end

switch class(IN)
  case 'ts'
    if interval == 0
      interval = (EndTime(IN)-StartTime(IN))/10000;
    end
    F = length(Data(IN))/interval;
  case 'tsd'
    display('Returning sampling frequency of the tsd');
    F = 10000/DT(IN);
  case 'cell'
    if interval == 0
      interval = (Find_end(IN)-Find_start(IN))/10000;% convert to seconds
    end
    F = zeros(1,length(IN));
    for ii = 1:length(IN)
      F(ii) = Frequency(IN{ii}(:), interval);
    end
  case {'double'  'sparse'}
    if interval == 0
      error('Must specify interval for class double');
    end
    F = length(IN)./interval;
  otherwise
    error('Unrecognized class');
end
