function TRD = LK_Treadmill_Speed(EVT, META)
% function TRD = LK_Treadmill_Speed(EVT, META)
%
% Extracts the treadmill speed and direction from the EVT structure.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%e%%%%%%%%%%%%%%%
% Cowen 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Cols(EVT.treadmill_ID) == 1
    error('Old treadmill data - one column only. Update the EVT.mat file.')
end
if nargin == 0
    GP = LK_Globals;
    load('EVT.mat');
    load('Meta_data.mat');
end
if isempty(EVT.treadmill_ID)
    TRD = [];
    disp('No treadmill data')
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dividing_dur_s = 0.0084571; % duration separating clock and countercloc. Determined epirically.
min_speed = 8; % duration separating clock and countercloc. Determined epirically.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T_s = EVT.treadmill_ID/META.sFreq_amp;
speed = [nan ; 1./diff(T_s(:,1))];
GIX = speed > min_speed;
T_s = T_s(GIX,:);
speed = speed(GIX);

pulse_dur_s = T_s(:,2)-T_s(:,1);
tread_direction = nan(size(pulse_dur_s));
tread_direction(pulse_dur_s<dividing_dur_s) = 1;
tread_direction(pulse_dur_s>dividing_dur_s) = -1;
% compute the start and end time of each treadmill bout.
d = diff(T_s(:,1));
ix = find(d > 100);
if isempty(ix)
    tread_intervals_s = [ T_s(1)  T_s(end)];
else
    % TODO: this only works for 2 intervals. Should be generalized to >2
    tread_intervals_s(1,:) = [T_s(1) T_s(ix(1),1)];
    tread_intervals_s(2,:) = [T_s(ix(1)+1,1) T_s(end)];
    if length(ix)> 1
        error('this does not generalize to > 2 intervals yet. Fix this')
    end
    
end
dur_s = tread_intervals_s(:,2) - tread_intervals_s(:,1);
tread_intervals_s = tread_intervals_s(dur_s > 10,:); % assume intervals < 10s are crap.

% store in a structure for output.

TRD.t_uS = T_s(:,1)*1e6;
TRD.tread_intervals_uS = tread_intervals_s*1e6;
TRD.tread_direction = tread_direction;
TRD.speed = speed; % we should figure out what the units are in terms of rotations per minute. Not sure how many pulses are in a full circult. Need to look at arduino.
TRD.notes = '1 = clockwise, -1 = counter clockwise';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargout == 0
    figure
    histogram(pulse_dur_s,200)
    xlabel('pulse width s')
    
    figure
    IX1 = tread_direction == 1;
    IX2 = tread_direction == -1;
    plot(T_s(IX1,1), speed(IX1),'.')
    hold on
    plot(T_s(IX2,1), speed(IX2),'.')
    legend('clock','counterclock')
    ylabel('speed')
end
