function fdata = wavefilter(data, maxlevel)
% fdata = wavefilter(data, maxlevel)
% data	- an N x M array of continuously-recorded raw data
%		where N is the number of channels, each containing M samples
% maxlevel - the level of decomposition to perform on the data. This integer
%		implicitly defines the cutoff frequency of the filter.
% 		Specifically, cutoff frequency = samplingrate/(2^(maxlevel+1))
%
% From http://www.berkelab.org/Software_files/wavefilter.m
% see Wiltschko et al. 2008
% 

[numwires, numpoints] = size(data);
fdata = zeros(numwires, numpoints);

% We will be using the Daubechies(4) wavelet.
% Other available wavelets can be found by typing 'wavenames'
% into the Matlab console.
wname = 'db4'; 

for i=1:numwires % For each wire
    % Decompose the data
    [c,l] = wavedec(data(i,:), maxlevel, wname);
    % Zero out the approximation coefficients
    c = wthcoef('a', c, l);
    % then reconstruct the signal, which now lacks low-frequency components
    fdata(i,:) = waverec(c, l, wname);
end