function INTAN_find_best_LFP_channel(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract events, LFP, inertial data by default.
% INPUT:
%   Run without parameters to run on dat files in the pwd.
%   or specify intan_data_dir and it will run on the .dat files in this
%   directory. 
%
%   will default to taking a 5 min period in the middle of the session for
%   analysis unless otherwise specified.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
intan_data_dir = pwd;

sFreq_ana = 300;
sFreq_save = 1000; 
save_best_LFP = true;
rms_bad_thresh = 11000; % mark as bad LFP with this RMS or higher.
prop_bad_thresh = 0.4; % mark as bad LFP channels with this portion of bad data.
intervals_sec = []; % time intervals to examine. If not, it pickes a point in the center of the dataset to analyze.
fqs = 1:.2:70; % freq for the plotted PSDs
win = sFreq_ana*2;
sec_to_get = 5*60; % only grab this many seconds from the middle of the recording (by default)
% create_a_CAR_file = false; % takes the better channels and creates a CAR file from these channels.
create_a_reref_file = false; % takes the better channels and creates a CAR file from these channels.
files_to_ignore = {}; % cell arrya of files to ignore from consideration.
force_theta_channel = [];

Extract_varargin(); % This will override the above defaults if the user passes in name-value pairs into the function.

theta_IX = fqs>6 & fqs < 11;
delta_IX = fqs > 3 & fqs < 5; % a little higher than delta to get a better estimate of theta power.
noise_IX = fqs>57 & fqs < 63;

% intan_data_dir = 'E:\Data\String_Pull_Rm312a\Rat_349\6\Rec_220511_131948';
out_dir = fullfile(intan_data_dir,'lfp_quality');
files = dir(fullfile(intan_data_dir,'amp*.dat'));
IF = read_Intan_RHD2000_file_cowen(intan_data_dir,'info.rhd');
fs_initial = IF.frequency_parameters.amplifier_sample_rate;
dfact = fs_initial/sFreq_ana;
dfact_save = fs_initial/sFreq_save;
[status, msg, msgID] =mkdir(out_dir);
INFO.fqs = fqs;
% remove any 'forbidden' files from consideration.
if ~isempty(files_to_ignore)
    gix = [];
    cnt = 1;
    for iF = 1:length(files)
%         files(iF).name
        if any(strcmpi(files_to_ignore, files(iF).name))
%              files(iF).name
%              disp('baddie')
        else
            gix(cnt) = iF;
            cnt = cnt + 1;
        end
    end
    files = files(gix);
end

%%
for iF = 1:length(files)
    disp(['Loading ' files(iF).name])
    INFO.fname{iF} = files(iF).name;

    D = INTAN_Read_DAT_file(fullfile(intan_data_dir,files(iF).name),dfact);
    D = D - movmedian(D,sFreq_ana*4);
    if iF == 1
        t_s = (0:(length(D)-1))/sFreq_ana;
    end
    if isempty(intervals_sec)
        intervals_sec = [t_s(end)/2-sec_to_get/2  t_s(end)/2+sec_to_get/2];
    end
    Dr = Restrict([t_s(:) D(:)],intervals_sec);
    BIX = conv(abs(Dr(:,2))>15000,ones(sFreq_ana,1))>0;
    INFO.prop_bad_data(iF) = sum(BIX)/length(BIX);
    Dr(BIX,2) = 15000;
    [INFO.PW(iF,:),f] = pwelch(Dr(:,2),win,win/2,fqs,sFreq_ana);
    INFO.rms(iF) = rms(Dr(:,2));
    INFO.th_pow(iF) = max(INFO.PW(iF,theta_IX));
    INFO.delta_pow(iF) = mean(INFO.PW(iF,delta_IX));
    INFO.wall_noise_pow(iF) = mean(INFO.PW(iF,noise_IX));
    INFO.th_delta_ratio(iF) = INFO.th_pow(iF)/INFO.delta_pow(iF);
    [xc,lags] = xcorr(Dr(:,2),Dr(:,2),sFreq_ana/2,"normalized");

    figure(1)
    clf
    subplot(3,2,1:2)
    plot(Dr(:,1),Dr(:,2)) 
    axis tight
    set(gca,'YLim',[-8000 8000])
    xlabel('s')
    title(files(iF).name)

    subplot(3,2,3)
    plot(fqs,log10(abs(INFO.PW(iF,:))))
    xlabel('Hz');ylabel('dB'); axis tight; grid on
    title(sprintf('rms %1.2f tdr %1.2f prop_bad %1.2f', rms(Dr(:,2)),INFO.th_delta_ratio(iF),INFO.prop_bad_data(iF)))

    subplot(3,2,4)
    IX = fqs>1 & fqs < 21;
    plot(fqs(IX),log10(abs(INFO.PW(iF,IX))))
    xlabel('Hz');ylabel('dB'); axis tight; grid on

    subplot(3,2,5)
    XIX = lags>0;
    plot(lags(XIX)/sFreq_ana,xc(XIX))
    xlabel('Lag (s)')
    title('Autocorr')

    subplot(3,2,6)
    plot(Dr(1:sFreq_ana,1),Dr(1:sFreq_ana,2)) 
    axis tight
    xlabel('s')
    [~,n] = fileparts(files(iF).name);
    set(gcf,'Position',[  113   92.2 1169.6  760 ]);



    saveas(gcf,fullfile(out_dir,[n '_quality.png']))
    %     pause
end
tmp = INFO.rms;
tmp(tmp < 2) = inf; % to ensure weirdly low RMS channels are not considered.
tmp(tmp > rms_bad_thresh) = inf; % to ensure weirdly high RMS channels are not considered.
tmp( INFO.prop_bad_data > prop_bad_thresh) = inf; % if this proportion of data is bad, fogettaboutit.

valid_ch_IX = tmp < inf;

[~,ix] = min(tmp);
INFO.lowest_rms_channel_fname = INFO.fname{ix(1)};
INFO.lowest_rms_channel_ix = ix(1);

% Of say the best 50% rms channels, which has the strongest theta.
low_rms = prctile(INFO.rms,50);
gix = find(INFO.rms < low_rms & valid_ch_IX);
[~,ix] = max(INFO.th_delta_ratio(gix));
INFO.best_theta_channel_with_low_snr_fname = INFO.fname{gix(ix)};
INFO.best_theta_channel_with_low_snr_ix = gix(ix);

[~,ix] = max(INFO.th_delta_ratio .* double(valid_ch_IX));

if isempty(force_theta_channel)
    INFO.best_theta_channel_fname = INFO.fname{ix};
    INFO.best_theta_channel_ix = ix;
else
    INFO.best_theta_channel_fname = force_theta_channel;
    for ii = 1:length(files)
        if strcmpi(force_theta_channel,files(ii).name)
            INFO.best_theta_channel_ix = ii;
        end
    end
end

% Find a decent reference channel (if your goal is good theta). A channel
% with low SNR and low TD ratio.
valid_ch_IX(INFO.rms>median(INFO.rms,"omitnan")) = false;
v = INFO.th_delta_ratio;
v(~valid_ch_IX) = inf;
[~,ix] = min(v);
INFO.best_ref_channel_fname = INFO.fname{ix};
INFO.best_ref_channel_ix = ix;

figure
subplot(1,3,1)
barh(INFO.rms)
set(gca,'YTick', 1:length(INFO.fname))
set(gca,'YTickLabel', INFO.fname,'FontSize',8); xlabel('rms')

subplot(1,3,2)
barh(INFO.th_delta_ratio)
set(gca,'YTick', 1:length(INFO.fname))
set(gca,'YTickLabel', INFO.fname,'FontSize',8); xlabel('theta delta ratio')
hold on
plot(0,INFO.best_theta_channel_ix,'r*')
plot(0,INFO.best_theta_channel_with_low_snr_ix,'g>')

subplot(1,3,3)
barh(INFO.prop_bad_data)
set(gca,'YTick', 1:length(INFO.fname))
set(gca,'YTickLabel', INFO.fname,'FontSize',8); xlabel('prop BAD data')
hold on
plot(0,INFO.best_theta_channel_ix,'r*')
plot(0,INFO.best_theta_channel_with_low_snr_ix,'g>')
if isempty(force_theta_channel)
    title(['Forced to ' INFO.best_theta_channel_fname]);
end

sgtitle(intan_data_dir)
set(gcf,'Position',[ 285 331 1150  526]);


saveas(gcf,fullfile(out_dir,'channel_quality.png'))
save(fullfile(out_dir,'channel_quality.mat'),"INFO")

if save_best_LFP
    LFP = [];
    LFP.data = single(INTAN_Read_DAT_file(fullfile(intan_data_dir,files(INFO.lowest_rms_channel_ix ).name),dfact_save));
    LFP.sFreq = sFreq_save;
    LFP.fname = INFO.lowest_rms_channel_fname;
    LFP.how_to_get_time = '1/LFP.sFreq/2 + (0:(length(LFP.data)-1))/LFP.sFreq';
    LFP.intan_data_dir = intan_data_dir;
    save(fullfile(out_dir,'lowest_rms_lfp.mat'),"LFP")

    LFP = [];

    LFP.data = single(INTAN_Read_DAT_file(fullfile(intan_data_dir,INFO.best_theta_channel_fname),dfact_save));
    LFP.sFreq = sFreq_save;
    LFP.fname = INFO.best_theta_channel_fname;
    LFP.how_to_get_time = '1/LFP.sFreq/2 + (0:(length(LFP.data)-1))/LFP.sFreq';
    LFP.intan_data_dir = intan_data_dir;
    save(fullfile(out_dir,'best_theta_lfp.mat'),"LFP")

    if create_a_reref_file
        % this does not seem to help in the one example I tried.
        REF = single(INTAN_Read_DAT_file(fullfile(intan_data_dir,INFO.best_ref_channel_fname),dfact_save));
        LFP.data = LFP.data - REF;
        LFP.reref_fname = INFO.best_ref_channel_fname;
        save(fullfile(out_dir,'reref_theta_lfp.mat'),"LFP")
    end

    LFP = [];
    LFP.data = single(INTAN_Read_DAT_file(fullfile( ... 
        intan_data_dir,files(INFO.best_theta_channel_with_low_snr_ix ).name),...
        dfact_save));
    LFP.sFreq = sFreq_save;
    LFP.fname = INFO.best_theta_channel_with_low_snr_fname;
    LFP.how_to_get_time = '1/LFP.sFreq/2 + (0:(length(LFP.data)-1))/LFP.sFreq';
    LFP.intan_data_dir = intan_data_dir;
    save(fullfile(out_dir,'low_rms_and_theta_lfp.mat'),"LFP")

end
% 
% if create_a_CAR_file
%     % TO DO... will go throuhg the better channels and create a CAR for
%     % re-referencing later.
% end

