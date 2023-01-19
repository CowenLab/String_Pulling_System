%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This demo scipt will show how to investigate and depict potential relationships between
% the LFP signal and the string.
%
% It assumes that you are in a session direction (assumes data collected in
% room 312A - but may also work for data in 334.
%
% It assumes that the data has been processed (e.g., that there is an
% EVT.mat file and LFP files and IMU files in their appropirate
% directories.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parameters
data_dir = 'Z:\Data\String_Pull_312a\Rat333\01\Rec_210423_142327'; % the directory where the session data is stored.
lfp_file_to_analyze = 'amp-B-000_LFP.mat'; % File in the ./LFP subfolder.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For determining the individual pull bouts.
pull_bout_threshold_speed_rot_encoder = 5;
lower_thresh = pull_bout_threshold_speed_rot_encoder*.2;
minimum_duration = 2e6;
minimum_inter_interval_period = 3e6;
% for lfp
spec_fqs = 3:.25:110;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load(fullfile(data_dir,'EVT.mat'),'EVT')
load(fullfile(data_dir,'Meta_data.mat'),'META')
load(fullfile(data_dir,'LFP',lfp_file_to_analyze),'LFP');
tmp = load(fullfile(data_dir,'LFP','LFP_times.mat'),'t_uS');
LFP.t_uS = tmp.t_uS(:);
LFP.data = double(LFP.data)*LFP.to_uV_conversion; % some functions only work if data are in doubles.
IMU = LK_Load_and_Process_IMU(fullfile(data_dir,'Inertial_data.mat'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find the pull bouts.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ROT = LK_Rotary_Encode_Speed(EVT, META);
good_string_pull_intervals_uSec = find_intervals([ROT.t_uSec ROT.Speed],pull_bout_threshold_speed_rot_encoder,lower_thresh, minimum_duration, minimum_inter_interval_period);
% Add a little buffer so that the filtering does not get messed up on the
% edges.
good_string_pull_intervals_uSec_wide = good_string_pull_intervals_uSec;
good_string_pull_intervals_uSec_wide(:,1) = good_string_pull_intervals_uSec_wide(:,1)-.5e6;
good_string_pull_intervals_uSec_wide(:,2) = good_string_pull_intervals_uSec_wide(:,2)+.5e6;
% Restrict the data.
RT = Restrict([ROT.t_uSec(:) ROT.Speed(:) ROT.Acc(:)],good_string_pull_intervals_uSec);
RT_sec = linspace(0,Rows(RT)/ROT.sFreq,Rows(RT));
IM = Restrict([IMU.t_uS(:) IMU.speed(:)],good_string_pull_intervals_uSec);
IM_sec = linspace(0,Rows(IM)/IMU.IMU_sFreq,Rows(IM));
L = Restrict([LFP.t_uS(:) LFP.data(:)],good_string_pull_intervals_uSec);
L_sec = linspace(0,Rows(L)/LFP.LFP_sFreqj,Rows(L));
dur_sec = L_sec(end)-L_sec(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Visualize the raw data. Always a good idea before doing any summary stats
% or anything fancy.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1)
subplot(3,1,1)
plot(RT(:,1)/1e6,RT(:,2))
subplot(3,1,2)
plot(IM(:,1)/1e6,IM(:,2))
subplot(3,1,3)
plot(L(:,1)/1e6,L(:,2))
xlabel('Sec')
ylabel('uV')

figure(2)
plot(RT(:,1)/1e6,Z_scores(RT(:,2)))
hold on
plot(IM(:,1)/1e6,Z_scores(IM(:,2)))
plot(L(:,1)/1e6,Z_scores(L(:,2)))
xlabel('Sec')
legend('Rot','IM','LFP')

figure(3)
subplot(1,3,1)
histogram(RT(:,2))
title('Rot')
subplot(1,3,2)
histogram(IM(:,2))
title('IMU')
subplot(1,3,3)
histogram(L(:,2))
title('LFP')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% My main hypothesis is that theta frequency (and power) will scale with
% speed. Let's analyze this. We'll want speed on the x axis and the PSD
% powers on the Y.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SPEC = SPEC_cwt_cowen(L(:,2),LFP.LFP_sFreqj,spec_fqs);
SPEC = 10*log10(abs(SPEC));
% also compute the instantaneous theta freq
ifq(:,1) = instfreq(L(:,2),LFP.LFP_sFreqj,'FrequencyLimits',[5 12]);
ifq(:,2)  = instfreq(L(:,2),LFP.LFP_sFreqj,'FrequencyLimits',[35 90]);

ifq_sFreq = length(ifq)/dur_sec;
ifq_sec = linspace(0,Rows(ifq)/ifq_sFreq,Rows(ifq));

fIX = spec_fqs >= 5 & spec_fqs <= 12;
S = SPEC(fIX,:)';
S = S - mean(S,1);
S = S - mean(S,2);
S_fqs = spec_fqs(fIX);
ifq_cowen(:,1) = instfrq_cowen(S,S_fqs);

fIX = spec_fqs >= 35 & spec_fqs <= 110;
S = SPEC(fIX,:)';
S = S - mean(S,1);
S = S - mean(S,2);
S_fqs = spec_fqs(fIX);
ifq_cowen(:,2) = instfrq_cowen(S,S_fqs);


figure
imagesc(L_sec,spec_fqs,SPEC)
axis xy;
hold on
plot(L_sec,ifq_cowen(:,1),'c')
plot(L_sec,ifq_cowen(:,2),'c')
yyaxis right
plot(RT_sec,RT(:,2))
hold on
plot(RT_sec,RT(:,3),'b-')

%% correlate theta fq and string pulling

X = interp1(ifq_sec(:),ifq(:,1),RT_sec(:)); tit = 'th fq and speed';
 X = interp1(ifq_sec(:),ifq(:,2),RT_sec(:)); tit = 'gamma fq and speed';
GIX = ~isnan(X);
figure
subplot(1,2,1)
scatter(X(GIX),RT(GIX,2),1)
xlabel('inst fq')
ylabel('rot spd')
lsline
subplot(1,2,2)
scatter(X(GIX),RT(GIX,3),1)
xlabel('inst fq')
ylabel('rot acc')
lsline

mod = fitlm(X(GIX),RT(GIX,2));
a = anova(mod,'summary')

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Try my approach... (NOTE: it yields a very different distribution of frequencies than the instfrq does.
% makes me suspicious of my approach perhaps.
%%%%%%%%%%%%%%%%%%%%%%%%%%

X = interp1(L_sec(:),ifq_cowen(:,1),RT_sec(:)); tit = 'th fq and speed';
% X = interp1(L_sec(:),ifq_cowen(:,2),RT_sec(:)); tit = 'gam fq and speed';
GIX = ~isnan(X);

figure
subplot(1,2,1)
scatter(X(GIX),RT(GIX,2),1)
xlabel('inst fq')
ylabel('rot spd')
lsline
subplot(1,2,2)
scatter(X(GIX),abs(RT(GIX,3)),1)
xlabel('inst fq')
ylabel('rot acc')
lsline

% do the stats
mod = fitlm(X(GIX),RT(GIX,2));
a = anova(mod,'summary')
mod = fitlm([RT(GIX,2:3) abs(RT(GIX,3))],X(GIX));



%%


% For kicks, let's determine the R^2 value of the model where ALL
% frequencies are uesed to predict the speed. This is not very hypothesis
% driven and ignores changes in frequency (only looks at power), but it's
% potentially useful.
%
% Simplest (but maybe not the best): compute the regression between speed
% and the spectrogram and look at the betas...
Y = interp1(RT(:,1),RT(:,2),L(:,1)); tit = 'Spd';
% Y = interp1(RT(:,1),RT(:,3),L(:,1)); tit = 'Acc';
mod = fitlm(Z_scores(SPEC'),Y);
a = anova(mod,'summary')

betas = mod.Coefficients.Estimate(2:end);
p = mod.Coefficients.pValue(2:end);
betas(betas > 0.05) = nan;

figure
plot(spec_fqs,betas)
title(sprintf('%s R^2 = %1.3f, p = %d',tit, mod.Rsquared.Adjusted, a.pValue))
