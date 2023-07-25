function S = standardize_range(X,range_scale)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function S = standardize_range(X,range_scale)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% standardize or squash the range to be within the scale passed in.
% Columns in X will be standardized to be within the specified range around
% zero. The extent of the range is specified by range_scale. default is
% between -1 and 1.
%
% cowen (2006)
% 2010 - in some cases it seems to reduce the dynamic range considerably -
% OH!! It's because we were working with int16s!!! the change in range
% screwed up the precision!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isa(X,'double')
    X = double(X);
    disp('WARNING: not double precision. Cnverting to double!!!')
end

if nargin < 2
    range_scale = 2;
end
min_max = [];
midrange = ( nanmax( X )  +  nanmin( X ) ) / 2;
range = nanmax( X )  -  nanmin( X );
if length(range_scale) == 2
    min_max = range_scale;
    range_scale = 1;
end
S = (X - repmat( midrange, size(X,1), 1 )); % zero the values to be the midrange.
%S = S./(eps + repmat( range, size(X,1), 1) ./ range_scale);
S = S./(eps + repmat( range, size(X,1), 1)); % Divide by full range so that the range goes between -1 and 1)
S = S * range_scale;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% There are times when S is slightly (say .0000002) less or more than the range.
%  this is due to rounding error. The following hack corrects this.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S(S<(-range_scale/2)) = -range_scale/2;
S(S>(range_scale/2)) = range_scale/2;

if ~isempty(min_max)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Convert to the range passed in.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    S = S + 0.5;
    S = S*diff(min_max);
    S = S + min_max(1);
end