function ROT = SPG_Rotary_Encode_Speed(EVT, restrict_times_uS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%e%%%%%%%%%%%%%%%
% Rotary encoded data from the string pulling system.
% INPUT - the EVT file - which has the sample number for each input.
%
%% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% output_sFreq = 60;
GP = SPG_Globals;
SES = SPG_Session_Info;
peak_threshold = 40; % you need to have a mean peak pull speeds of this to be counted
n_peak_threshold = 8; % you need to have this many in a bout
if nargin == 0
    load(fullfile(SES.Intan_rec_dir,'EVT.mat'),'EVT');
    restrict_times_uS = [];
end

if isempty(EVT.rotary_encoder_recnum) % used to be rotary_encoder_ID which I think was removed later.
    ROT = [];
    disp('No rotary encoder data')
    return
end
t_s = EVT.rotary_encoder_recnum(:,1)/SES.RHD.frequency_parameters.amplifier_sample_rate;
if ~isempty(restrict_times_uS)
    t_s = Restrict(t_s,restrict_times_uS);
end
ROT = String_pull_speed_from_event_times(t_s*1e6);
ROT.tic_times_uSec = t_s*1e6;
ROT.Speed_cm_sec = ROT.Speed * GP.cm_per_tic_of_rot_encoder;

ROT.Cumulative_distance_cm = (1:length(t_s)).*GP.cm_per_tic_of_rot_encoder;


temp_good_string_pull_intervals_uSec = find_intervals([ROT.t_uSec ROT.Speed],GP.pull_bout_threshold_speed_rot_encoder,GP.pull_bout_threshold_speed_rot_encoder_low_thresh, GP.pull_bout_minimum_duration_uS , GP.pull_bout_minimum_inter_interval_period_uS);
% clean this up a little more...
BIX = false(Rows(temp_good_string_pull_intervals_uSec),1);
for iB = 1:Rows(temp_good_string_pull_intervals_uSec)
    IX = ROT.t_uSec >= temp_good_string_pull_intervals_uSec(iB,1) & ROT.t_uSec <= temp_good_string_pull_intervals_uSec(iB,2);
    [pk, ix] = findpeaks(ROT.Speed(IX));
    if mean(pk) < peak_threshold || sum(pk > peak_threshold) < n_peak_threshold
        BIX(iB) = true;
    end
end
temp_good_string_pull_intervals_uSec(BIX,:) = [];
% the above will get cleaned up even more in the following code.
[ROT.PULL, ROT.good_string_pull_intervals_uSec ] = SPG_Determine_Individual_Pull_Times(ROT, temp_good_string_pull_intervals_uSec);

ROT.good_string_pull_intervals_uSec_wide(:,1) = ROT.good_string_pull_intervals_uSec(:,1)-.5e6;
ROT.good_string_pull_intervals_uSec_wide(:,2) = ROT.good_string_pull_intervals_uSec(:,2)+.5e6;

% Determine the length pulled for each pull interval...
ROT.bout_duration_sec = (ROT.good_string_pull_intervals_uSec(:,2)-ROT.good_string_pull_intervals_uSec(:,1))/1e6;
ROT.dist_pulled_per_bout_cm = zeros(Rows(ROT.good_string_pull_intervals_uSec_wide),1);
for iR = 1:Rows(ROT.good_string_pull_intervals_uSec)
    sted = ROT.good_string_pull_intervals_uSec(iR,:);
    IX = ROT.tic_times_uSec >= sted(1) & ROT.tic_times_uSec <= sted(2);
    ROT.dist_pulled_per_bout_cm(iR) = sum(IX)*GP.cm_per_tic_of_rot_encoder;
end

if nargout == 0
    figure
    String_pull_speed_from_event_times(t_s*1e6)
    hold on
    plot_markers_simple(ROT.good_string_pull_intervals_uSec/1e6)

    figure
    plot(t_s/60,ROT.Cumulative_distance_cm/100,'linewidth',3);ylabel('cumulative meters pulled');xlabel('minutes');axis tight;pubify_figure_axis;

end
