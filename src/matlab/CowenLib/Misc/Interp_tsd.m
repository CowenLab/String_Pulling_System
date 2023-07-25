function out_ctsd = Interp_tsd(in_tsd,interval,startpt,endpt,method)
%
% Create a ctsd object from a tsd by interpolating the values in the
% tsd.
%
% INPUT
%                     tsa: tsd object
% interval,startpt,endpt : the start,end and interval of the output
%                          tsd.
%                          if no start and end time are specified then the first and last time
%                          in the record are used.
%                  method: interpolation method (default is linear)
%
% OUTPUT:
%         the interpolated data as a ctsd object
%    
%function out_tsd = Interp_tsd(in_tsd,interval,startpt,endpt,method)
%

% cowen Sat Jul  3 16:06:20 1999


D = Data(in_tsd);
t = Range(in_tsd,'ts');
if nargin == 2
  startpt = StartTime(in_tsd);
  endpt = EndTime(in_tsd);
end

if nargin == 4
  method = 'linear';
end

switch method 
  case 'linear'
    X = interp1(t,D,startpt:interval:endpt,'linear');
  case 'nearest'
    X = interp1(t,D,startpt:interval:endpt,'nearest');
  case 'spline'
    X = interp1(t,D,startpt:interval:endpt,'spline');
  case 'cubic'
    X = interp1(t,D,startpt:interval:endpt,'cubic');
  otherwise
    error('invalid method');
end
out_ctsd = ctsd(startpt,interval, X');
