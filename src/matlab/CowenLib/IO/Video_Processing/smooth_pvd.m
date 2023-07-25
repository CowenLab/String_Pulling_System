function [smooth_pvd] = smooth_pvd(pos_data);

% smooth position data by using running average.  
% pos_data has the format [ts posx posy vel dir]
% vel and dir are not currently interpolated, just zeros are returned
% EUSTON
% cowen modifications.

% WINDOW samples both pre and post will be considered
% for each samples being smoothed.

WINDOW = 10;
%b = ones(1,WINDOW)/(WINDOW);  % this is a simple running average
gauss_i = -WINDOW/2:WINDOW/2;
b = gaussian(gauss_i, 0, WINDOW/4)/sum(gaussian(gauss_i, 0, WINDOW/4));

% Now, use samples from the past and future to smooth the present (acausal filtering).
% Filtering uses Matlab's "filtfilt" routine which sets the order of filtering
% by the 'b' coefficient, which roughly states how many samples are used in each fit.
% "filtfilt" returns all NaN's if any data point is a NaN.  This will cause problems
% at the start of the file where VT.interp contains a few startup NaN's.

pos_data(:,2) = filtfilt( b, 1, pos_data(:,2) );           % x position
pos_data(:,3) = filtfilt( b, 1, pos_data(:,3) );           % y position
%vv = filtfilt( b, 1, V(:) );                % velocity
%dd = filtfilt( b, 1, exp( cmplx * D(:) ) ); % head direction
%dd = atan2( imag(dd), real(dd) );

smooth_pvd = pos_data;  % note the zeros for velocity and direction

return;