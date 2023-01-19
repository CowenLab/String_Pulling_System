function OUT = LK_Determine_good_pull_bouts()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function loads a ton of things that are typically used
% for any analysis. It simplifies things.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,~,EVT,~,~,META] = LK_Load_Important_Things;
OUT = [];
if exist('good_string_pull_intervals_uSec.mat','file')
    disp('Data already in this directory')
    load('good_string_pull_intervals_uSec.mat')
    good_string_pull_intervals_uSec
else

    %%%Plot from LK_Rotary_Encode_Speed()
    LK_Rotary_Encode_Speed(EVT,META)
    title('PRESS SPACE TO BEGIN: (zoom) No file: Use good_string_pull_intervals_uSec = Ginput_pairs')
    pause()
    intervals_Sec = Ginput_pairs();
    %good_string_pull_intervals_uSec = [0 inf];
    good_string_pull_intervals_uSec=intervals_Sec*1000000;
    save('good_string_pull_intervals_uSec.mat','good_string_pull_intervals_uSec')
end