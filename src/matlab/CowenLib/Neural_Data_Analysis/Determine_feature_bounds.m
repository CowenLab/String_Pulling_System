function FB = Determine_feature_bounds(waveform_file, t_file, features)
%
% FB is a structure with elements of length(features) that presents the min and max of the 
% load timestamps

% Load in the timestamp file.
FB = [];
if nargin < 3
    features = {'stdPC1','stdPC2','sw','wavePC1','wavePC2','wavePC3','energy'};
end

tfp = fopen(t_file, 'rb','b');
if (tfp == -1)
    warning([ 'Could not open tfile ' t_file]);
    return
end
ReadHeader(tfp);    
t = fread(tfp,inf,'uint32');	%read as 32 bit ints
fclose(tfp);

wvidx = 2;
tidx = 1;
[F, filetype] = load_waveform_file(waveform_file, [1 0 0 0 1 0 ], t);
switch filetype
case 'SE'
    ch_vec = [1 0 0 0];
case 'ST'
    ch_vec = [1 1 0 0];
case 'TT'
    ch_vec = [1 1 1 1];
otherwise
    error('Unknown filetype.')
end

F{wvidx} = permute(F{wvidx},[3,1,2]);
for iF = 1:length(features)
    [FeatureData, FeatureNames] = ...
        feval(['feature_', features{iF}], tsd(t,reshape(F{wvidx},size(F{wvidx},1),1,size(F{wvidx},2))), ch_vec);
    FB.mx(iF)   = max(FeatureData);
    FB.mn(iF)   = min(FeatureData);
    FB.mean(iF) = nanmean(FeatureData);
end
