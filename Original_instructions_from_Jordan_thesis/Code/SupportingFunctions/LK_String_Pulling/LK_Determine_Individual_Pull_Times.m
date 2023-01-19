function [PULL] = LK_Determine_Individual_Pull_Times(ROT, good_string_pull_intervals_uSec)
% Determine the start and end of the string pulling period.
% TODO: THis may require some smoothing?
% 
% 
GP = LK_Globals;
speed_threshold = 10;
if nargin == 0
    ROT = LK_Rotary_Encode_Speed();
    load(GP.fnames.string_pull_intervals_file)
end
[~,GIX] = Restrict(ROT.t_uSec,good_string_pull_intervals_uSec);
ROT.t_uSec = ROT.t_uSec(GIX);
ROT.Speed = ROT.Speed(GIX);
ROT.Acc = ROT.Acc(GIX);
[pks,locs] = findpeaks(ROT.Speed);
BIX = pks < speed_threshold;
pks(BIX) = [];
locs(BIX) = [];
PULL.Peak_uS = ROT.t_uSec(locs);
PULL.Peak_Speed = ROT.Speed(locs);

PULL.Start_uS = nan(size(PULL.Peak_uS));
PULL.End_uS = nan(size(PULL.Peak_uS));
PULL.Start_ix = nan(size(PULL.Peak_uS));
PULL.End_ix = nan(size(PULL.Peak_uS));
PULL.Start_Speed = nan(size(PULL.Peak_uS));
PULL.End_Speed = nan(size(PULL.Peak_uS));

[~,tr_locs] = findpeaks(ROT.Speed*-1);
bel_thr = find(ROT.Speed < speed_threshold);
tr_locs = unique([tr_locs(:);bel_thr(:)]); % this ensures that end times don't bleed deeply into periods when the pully is not moving.

for iPk = 1:length(pks)
    ixst = find( tr_locs < locs(iPk),1,'last');
    ixed = find( tr_locs > locs(iPk),1,'first');
    if isempty(ixst) 
        ixst = 1;
    end
    if isempty(ixed) 
        ixed = length(tr_locs);
    end
    
    PULL.Start_uS(iPk) = ROT.t_uSec(tr_locs(ixst));
    PULL.End_uS(iPk) = ROT.t_uSec(tr_locs(ixed));
    PULL.Start_ix(iPk) = tr_locs(ixst);
    PULL.End_ix(iPk) = tr_locs(ixed);
    
    PULL.Start_Speed(iPk) = ROT.Speed(tr_locs(ixst));
    PULL.End_Speed(iPk) = ROT.Speed(tr_locs(ixed));
    
end
PULL.Peak_ix = locs;
% PULL.ActivePull = ROT.t_uSec(diff(ROT.Speed) > 30)';

if nargout == 0
    figure
    plot(ROT.t_uSec, ROT.Speed)
    hold on
    plot(PULL.Start_uS,PULL.Start_Speed,'g>')
    plot(PULL.End_uS,PULL.End_Speed,'r<')
    plot(PULL.Peak_uS,PULL.Peak_Speed,'c^')
end

