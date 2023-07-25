function ROT = String_pull_speed_from_event_times(pulse_uS, output_sFreq)
if nargin == 1
    output_sFreq = 60;
end
if isempty(pulse_uS)
    ROT = [];
    return
end

t_s = pulse_uS/1e6;
rot_diff = [nan; diff(t_s(:))]; % time between each pulse.
Sec = 0:1/output_sFreq:(t_s(end)+.5);
Sec = Sec(:);
ROT.t_uSec = Sec*1e6;
ROT.sFreq = 1e6/median(diff(ROT.t_uSec));

GIX = ~isnan(rot_diff);
ROT.Speed = single(interp1(t_s(GIX),rot_diff(GIX),Sec));
ROT.Speed = 1./ROT.Speed;
ROT.Speed  = ROT.Speed(:);
ROT.Acc  = diff([0;ROT.Speed(:)]);

if nargout == 0
    %     figure('units','normalized','outerposition',[0 0 1 1])
    figure
    plot(Sec,ROT.Speed,'.-')
    ylabel('Speed')
    yyaxis right
    plot(Sec,ROT.Acc,'.-')
    xlabel('Sec')
    ylabel('Acc')
    title('Rotary Encoder Output')
end