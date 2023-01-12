function ROT = LK_Rotary_Encode_Speed(EVT, META)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%e%%%%%%%%%%%%%%%
% Rotary encoded data from the string pulling system.
% INPUT - the EVT file - which has the sample number for each input.
%
%% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
output_sFreq = 60;

if nargin == 0
    GP = LK_Globals;
    load(GP.fnames.event_file);
    load(GP.fnames.meta_file);
end
if isempty(EVT.rotary_encoder_ID)
    ROT = [];
    disp('No rotary encoder data')
    return
end
t_s = EVT.rotary_encoder_ID(1,:)'/META.sFreq_amp;
rot_diff = [nan; diff(t_s(:))]; % time between each pulse.
Sec = 0:1/output_sFreq:META.sec_of_recording;
Sec = Sec(:);
ROT.t_uSec = Sec*1e6;
ROT.sFreq = 1e6/median(diff(ROT.t_uSec));

GIX = ~isnan(rot_diff);
ROT.Speed = single(interp1(t_s(GIX),rot_diff(GIX),Sec));
ROT.Speed = 1./ROT.Speed;
ROT.Speed  = ROT.Speed(:);
ROT.Acc  = diff([0;ROT.Speed(:)]);

if nargout == 0
    figure('units','normalized','outerposition',[0 0 1 1])
    plot(Sec,ROT.Speed,'.-')
    ylabel('Speed')
    yyaxis right
    plot(Sec,ROT.Acc,'.-')
    xlabel('Sec')
    ylabel('Acc')
    title('Rotary Encoder Output')
end
