function timestamps = Apply_feature_bounds(waveform_file, mn, mx, features)
%
% FB is a structure with elements of length(features) that presents the min and max of the 
% load timestamps
% OUTPUT: timestamps in the waveform file that correspond to the points within the bounds
% speficied.
if nargin < 3
    features = {'stdPC1','stdPC2','sw','wavePC1','wavePC2','wavePC3','energy'};
end
wvidx = 2;
tidx = 1;
[F, filetype] = load_waveform_file(waveform_file, [1 0 0 0 1 0 ]);
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
badidx = [];
for iF = 1:length(features)
    [FeatureData, FeatureNames] = ...
        feval(['feature_', features{iF}], tsd(F{tidx},reshape(F{wvidx},size(F{wvidx},1),1,size(F{wvidx},2))), ch_vec);
    badidx = unique([badidx; find(FeatureData > mx(iF) | FeatureData < mn(iF))]);
end

goodidx = setdiff(1:length(F{tidx}),badidx);
timestamps = F{tidx}(goodidx);
