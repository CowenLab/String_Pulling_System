function [INFO] = LK_LFP_Info(fnames, DEPTHS)
% For a given filename, load all of the important info for this file...
% Depth, TT number, hemisphere.
%
if ~iscell(fnames)
    fnames = {fnames};
end
if nargin < 2
    [DEPTHS,T] = LK_Load_Depths;
end

if ~exist('LFP_ratings_and_info.csv','file')
    % Make one
    T = [];
    for ii = 1:length(fnames)
        T(ii).filename = fnames{ii};
        T(ii).rating_5_best = -1;
        T(ii).good_sig = 0;
        T(ii).good_ref = 0;
        T(ii).notes = [];
    end
    TBL = struct2table(T);
    writetable(TBL,'LFP_ratings_and_info.csv')
end
LR = readtable('LFP_ratings_and_info.csv');
LT = readtable('../LFP_to_Tetrode.xlsx');
TT2C = readtable('../Tetrode_2d_Cordinates.xlsx');

LR.filename = categorical(LR.filename);
INFO = [];
for iF = 1:length(fnames)
    % parse the filename
    INFO(iF).fname = fnames{iF};
    INFO(iF).Channel = str2double( fnames{iF}(7:9));
    INFO(iF).Amp = fnames{iF}(5);
    
    % Get the ratings
    IX = LR.filename == fnames{iF};
    
    INFO(iF).rating_5_best = LR.rating_5_best(IX);
    INFO(iF).good_sig = LR.good_sig(IX);
    INFO(iF).good_ref = LR.good_ref(IX);
    % get the tetrode.
    ix =  LT.LFPChannel == INFO(iF).Channel;
    INFO(iF).Tetrode = LT.Tetrode(ix);
    % get the depth
    ix =  DEPTHS(:,1) == INFO(iF).Tetrode;
    INFO(iF).Depth_uM = double(DEPTHS(ix(1),2));

    % get the hemisphere and coordinates.
    ix =  TT2C.Tetrode == INFO(iF).Tetrode;
    INFO(iF).Hemisphere = TT2C.Hemisphere{ix};
    INFO(iF).APmm = TT2C.APmm(ix);
    INFO(iF).MLmm = TT2C.MLmm(ix);

end
TBL = struct2table(INFO);
writetable(TBL,'LFP_INFO_auto_generated.csv');
% INFO.Hemisphere = categorical(INFO.Hemisphere);