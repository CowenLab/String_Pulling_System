function [O,F] = REM_sleep_detection_phase_1(LFP, sFreq, SLEEP_TIMES, MVT, F)
% function [O,F] = REM_sleep_detection_phase_1(LFP, sFreq, SLEEP_TIMES, MVT, F)
% This is phase 1 of detection where the relative power in delta, theta and
% some super theta frequency is calculated for each block.
% in phase_2, the user determines a threshold for the theta and delta ratio
% measures. This ratio is then used to categorize sleep.
% This is broken into 2 steps as this phase can take a long time. As a
% result, it may be more efficient to run this on all data first, and then
% quickly go through and determine thresholds for all datasets using phase
% 2.
%
% INPUT: 2 column matrix. Col 1 is time in SECONDS.
% INPUT 3: two column intervals for sleep periods
% INPUT 4 MVT - a measure of movement (e.g., EMG) where col 1 is time and col 2 is values%
%
% Parameters- FOR REM lets look at theta and delta
% GOAL: Detect REM and NREM: REM: sawtooth EEG activity, flat EMG, NREM:
% high amplitude low frequecny, and lower EMG (but not as low as REM).
%
% FROM PAPERS:

% Kreuzer, M., Polta, S., Gapp, J., Schuler, C., Kochs, E. F., & Fenzl, T. (2015). Sleep scoring made easy - Semi-automated sleep analysis software and manual rescoring tools for basic sleep research in mice. MethodsX, 2, 232–240. https://doi.org/10.1016/j.mex.2015.04.005
%%% NO MENTION OF ELECTRODE PLACEMENT IN Kreuzer.
% Louis, R. P., Lee, J., & Stephenson, R. (2004). Design and validation of a computer-based sleep-scoring algorithm. Journal of Neuroscience Methods, 133(1–2), 71–80. https://doi.org/10.1016/j.jneumeth.2003.09.025
%%% STATE EEG electrode over frontal gets you better alpha and delta so
%%% good for NREM (Schwierin et al., 1999). THETA is better for electrodes
%%% over PARIETAL.
% >> EMG: filter between 40-90Hz. Convert to RMS (sqrt(mean(abs(EMG)^2))
% >> EEG: 0.5-31.75 Hz butterworth 3rd order bandpass for raw signal. Local bandpasses described
% below... (not sure why this is relevant as all detection is based on
% bandpass filtered data so I think that this can be ignored)
%
% >> Block length: 4s default. non-overlapping blocks
% >> BANDPASSES:
% Osc.Theta_range=[5 9];
% Osc.Delta_range=[0.5 5];
% Osc.Alpha_range=[10 15];
% Osc.Mu_range=[16 22];
% Osc.Beta_range=[23 32];
%
% Steps 1-3 are obvious artifact rejection steps...:
% Artefacts rejection in EMG or EEG with simple threshold detection.
% COnvert to Nans.
% this function assumes that you have already detected potential sleep
% epochs.
%
% Step 4:delta and theta graphs and EMG graphs.
%
% DELTA = dRMS*aRMS/muRMS*bRMS; % NOTE: Luis uses gamma instead of Mu.
%
% THETA = tRMS/(dRMS*aRMS); EMG = exp(EMGRMS)
%
% USER sets a threshold based on a GUI.
% Decision 1) awake vs. sleep (already done). But we need a EMG threshold
% to use in later stages.
% Decision 2) NREM vs. REM detection... Delta vs. theta thresholds
%  Mannually set DELTA and THETA thresholds.
% REM if < DELTA threshold and > THETA threshold.
% NREM > DELTA threshold.
%
%
% From Louis paper (inspired this technique and is a much better paper than the Kreuzer paper).
% ELECTRODES: A left frontal electrode was implanted 2mm an- terior to bregma and 2mm lateral to the midline. A right parietal electrode was implanted 4mm posterior to bregma and 4mm lateral to the midline. All signals were referenced to a ground electrode implanted over the left parietal cortex 4mm anterior and 4mm lateral to bregma.
% DIFFERENCE FROM Kreuzer:% Osc.Gamma_range=[35 45];
%
% TODO: Might be better to get delta from more anterior electrode and theta
% from a more posterior electrode. Theta is stronger more posterior, delta
% moreso on anterior electrodes.

PLOT_IT = false;
DO_SVM = false; % slow so only if time.
if nargin < 5
    F = [];
end

O = [];
PARAM.Block_lenght_s = 4;
PARAM.THETA_THRESH = 2; % bare minium threshold that must be met. This is only one of a few criteria.
PARAM.DELTA_THRESH = nan;
PARAM.Theta_range=[5 9];
PARAM.Delta_range=[1 5]; % 1.5-6 in Louis. 0.5 5 in Kreuzer. I chose 1 as there can be some very slow DC changes that do not think are true brain delta.
PARAM.Alpha_range=[10 15]; % 10.5-15 in Louis.
PARAM.Mu_range=[16 22]; % Louis does no use this.
PARAM.Beta_range=[23 32]; %22-30 in Louis 
% PARAM.Gamma_range=[35 45]; % this is only in Louis

Wide_range=[0.5 50]; % for plotting PSDs really.

O.psd_fqs = Wide_range(1):.25:Wide_range(end);

if isempty(F)
    % If the user already has the filterd traces, then ignore this section.
    F.Theta_filt = designfilt('bandpassiir','FilterOrder',10, ...
        'HalfPowerFrequency1',PARAM.Theta_range(1),'HalfPowerFrequency2',PARAM.Theta_range(2), ...
        'SampleRate',sFreq,'DesignMethod','butter');
    F.Delta_filt = designfilt('bandpassiir','FilterOrder',10, ...
        'HalfPowerFrequency1',PARAM.Delta_range(1),'HalfPowerFrequency2',PARAM.Delta_range(2), ...
        'SampleRate',sFreq,'DesignMethod','butter');
    F.Alpha_filt = designfilt('bandpassiir','FilterOrder',10, ...
        'HalfPowerFrequency1',PARAM.Alpha_range(1),'HalfPowerFrequency2',PARAM.Alpha_range(2), ...
        'SampleRate',sFreq,'DesignMethod','butter');
    F.Mu_filt = designfilt('bandpassiir','FilterOrder',10, ...
        'HalfPowerFrequency1',PARAM.Mu_range(1),'HalfPowerFrequency2',PARAM.Mu_range(2), ...
        'SampleRate',sFreq,'DesignMethod','butter');
    F.Beta_filt = designfilt('bandpassiir','FilterOrder',10, ...
        'HalfPowerFrequency1',PARAM.Beta_range(1),'HalfPowerFrequency2',PARAM.Beta_range(2), ...
        'SampleRate',sFreq,'DesignMethod','butter');
    %     F.Gamma_filt = designfilt('bandpassiir','FilterOrder',10, ...
    %         'HalfPowerFrequency1',Beta_range(1),'HalfPowerFrequency2',Beta_range(2), ...
    %         'SampleRate',sFreq,'DesignMethod','butter');
    % filt_sig_g = filtfilt( F.Gamma_filt,double(LFP(:,2)));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GIX = ~isnan(LFP(:,2));
ALPHA = 3;
LFP(GIX,ALPHA) = filtfilt( F.Alpha_filt,double(LFP(GIX,2))); %filtered to spindle band
MU = 4;
LFP(GIX,MU) = filtfilt( F.Mu_filt,double(LFP(GIX,2)));
BETA = 5;
LFP(GIX,BETA) = filtfilt( F.Beta_filt,double(LFP(GIX,2)));
THETA = 6;
LFP(GIX,THETA) = filtfilt( F.Theta_filt,double(LFP(GIX,2)));
DELTA = 7;
LFP(GIX,DELTA) = filtfilt( F.Delta_filt,double(LFP(GIX,2)));

% Remove sleep intervals that are not sufficiently long...
GIX = (SLEEP_TIMES(:,2) - SLEEP_TIMES(:,1))  >= PARAM.Block_lenght_s;
O.n_sleep_times_removed = sum(~GIX);
SLEEP_TIMES = SLEEP_TIMES(GIX,:);
%%%%%%%%%%%%%%%%%%%%%%
n_LFP_pts = PARAM.Block_lenght_s*sFreq;
O.sleep_intervals_s = [];
block_cnt = 1;

for iBigInterval = 1:Rows(SLEEP_TIMES)
%     dur_s = diff(SLEEP_TIMES(iBigInterval,:));
    % split this interval into segments of 4 seconds - or close to it.
    %     n_blocks = ceil(dur_s/PARAM.Block_lenght_s);
    %     intervals_s = linspace(SLEEP_TIMES(iBigInterval,1),SLEEP_TIMES(iBigInterval,2),n_blocks);
    intervals_s = SLEEP_TIMES(iBigInterval,1):PARAM.Block_lenght_s:SLEEP_TIMES(iBigInterval,2);
    
    if length(intervals_s) < 2
        % Block is not long enough to count.        
        fprintf('x')
        continue
    end
    sted_s = [intervals_s(1:end-1); intervals_s(2:end)]';
    GIX = (sted_s(:,2) - sted_s(:,1))  >= PARAM.Block_lenght_s;
    sted_s = sted_s(GIX,:);
%     if isempty(sted_s)
%         % Block is not long enough to count.        
%         fprintf('y')
%         continue
%     end
    
    for isubInterval = 1:Rows(sted_s)
        L = Restrict(LFP,sted_s(isubInterval,:));
        if Rows(L) < n_LFP_pts || any(isinf(L(:))) || any(isnan(L(:))) || rms(L(:,ALPHA)) == 0 || mean(L(:,2))==0
            % Something crappy about this segment. Remove.
            continue
        end
        L = L(1:n_LFP_pts,:);
        L(:,2:end) =  L(:,2:end) - nanmean(L(:,2:end));
        
        O.sleep_intervals_s(block_cnt,:) = sted_s(isubInterval,:);

        O.Arms(block_cnt,1) = rms(L(:,ALPHA));
        O.Mrms(block_cnt,1) = rms(L(:,MU));
        O.Brms(block_cnt,1) = rms(L(:,BETA));
        O.Trms(block_cnt,1) = rms(L(:,THETA));
        O.Drms(block_cnt,1) = rms(L(:,DELTA));
        
        O.LFP(block_cnt,:) = L(:,2)';
        
        %         pxx =
        %         pwelch(L(:,2),length(L(:,2)),length(L(:,2))/4,O.psd_fqs,sFreq); %
        %         did not work well...
        pxx = pwelch(L(:,2),[],[],O.psd_fqs,sFreq); % this works well.
        %         pxx = pmtm(double(L(:,2)),[],O.psd_fqs,sFreq); % not
        %         really better and slow
        %         pxx = pburg(double(L(:,2)),82,O.psd_fqs,sFreq); % OK but
        %         a parameter that should be estimated.
        O.psd(block_cnt,:) = 10*log10(real(pxx));
        
        M = Restrict(MVT,O.sleep_intervals_s(block_cnt,:));
        O.MVT(block_cnt,1:(Cols(M)-1)) = nanmean(M(:,2:end));
        
        block_cnt = block_cnt + 1;
    end
    if mod(iBigInterval,20) ==0
        fprintf('.')
    end
end
O.LFP = O.LFP(:,1:n_LFP_pts); % this ensures consistency on the output.
% DELTA = dRMS*aRMS/muRMS*bRMS; % NOTE: Luis uses gamma instead of Mu.
%
% THETA = tRMS*tRMS/(dRMS*aRMS); EMG = exp(EMGRMS)
%
O.Dindex = (O.Drms.*O.Arms)./(O.Mrms.*O.Brms);

O.Tindex = (O.Trms.*O.Trms)./(O.Drms.*O.Arms);

% BIX = isnan(O.Tindex) | O.Tindex ==0;
% sum(BIX)
% Since manual thresholds are not being recorded, let's estimate them
% automatically.
O.theta_low_high = prctile(O.Tindex,[50 80]);
O.delta_low_high = prctile(O.Dindex,[50 75]);
O.mvt_low_high = prctile(O.MVT,[50 60]);
O.sFreq = sFreq;

REM = O.Tindex(:) > O.theta_low_high(2) & O.Dindex(:) < O.delta_low_high(1) & O.MVT(:,1) <= O.mvt_low_high(2) ;
NREM = O.Tindex(:) < O.theta_low_high(1) & O.Dindex(:) > O.delta_low_high(2);
 
O.STATE = categorical(size(REM));
O.STATE = O.STATE(:);
O.STATE(REM) = 'REM';
O.STATE(NREM) = 'NREM';
O.STATE(~(NREM | REM)) = 'UNKNOWN';

% do linear discriminant. It refines the above selection. In a way, it
% relaxes the hard threshold and works with the shape of the entire PSD.
%
IX = O.STATE =='REM' | O.STATE =='NREM';
[O.LD_value, O.LD_wt] = Linear_discriminant(O.psd(IX,:), O.STATE(IX));
O.MdlLinear = fitcdiscr([O.psd O.MVT],O.STATE); %%%% Can handle > 2 classes.
O.LD_STATE = predict(O.MdlLinear,[O.psd O.MVT]);
O.LDMV_STATE = O.LD_STATE;
O.LDMV_STATE(O.LDMV_STATE == 'REM' & (O.Tindex < PARAM.THETA_THRESH | O.MVT(:,1) > O.mvt_low_high(2))) = 'UNKNOWN';
% SVM  - why not. (because its slow af.)
if DO_SVM
    O.MdlSVM = fitcecoc([O.psd O.MVT],O.STATE); % Slow AF
    [O.SVM_STATE,~] = predict(O.MdlSVM,[O.psd O.MVT]);
    O.SVMMV_STATE = O.SVM_STATE;
    O.SVMMV_STATE(O.SVM_STATE == 'REM' & (O.Tindex < PARAM.THETA_THRESH | O.MVT(:,1) > O.mvt_low_high(2))) = 'UNKNOWN';
else
    O.SVM_STATE = [];
end
O.PARAM = PARAM;

% O.TSNE_Of_STATE = tsne([O.psd O.MVT]);

if 0
    % Maybe try an echo state or reservoir network?
    % Screwing aroudn. NOthing here to see yet.
    net = DeepESN(); %create the DeepESN
    % set the hyper-parameters: -----
    net.spectral_radius = .5;
    net.Nr = 10; %10 reservoir units
    net.Nl = 10; %10 reservoir layers
    %input scaling is set to 0.1, with scaling mode 'byrange'
    net.input_scaling = 0.1;
    net.inter_scaling = 0.1; %do the same also for the inter-layer scaling
    net.input_scaling_mode = 'byrange';
    net.washout = 1000; %1000 time steps long transient
    % --------------------------------
    
    net.initialize; %initialize the DeepESN
    %save the DeepESN for future use
    
    %train the network and compute the tr and vl performance
    [~,output_vl] = net.train_test([O.psd O.MVT],O.STATE,[O.psd O.MVT]);
end

if PLOT_IT
    confusionmat(O.STATE,O.LDMV_STATE)   % tells you how categories were reassigned
    
    figure
    subplot(1,4,1)
    histogram(O.STATE)
    subplot(1,4,2)
    histogram(O.LD_STATE)
    subplot(1,4,3)
    histogram(O.LDMV_STATE)
    subplot(1,4,4)
    histogram(O.LD_SVM)
    
    
    figure
    subplot(2,1,1)
    plot(O.Dindex)
    hold on
    plot(O.Tindex)
    legend('delta','theta')
    if ~isempty(O.MVT)
        yyaxis right
        plot(O.MVT)
        ylabel('mvt')
    end
    
    subplot(2,1,2)
    imagesc([],O.psd_fqs,O.psd')
    
    u = {'REM' 'NREM' 'UNKNOWN'};
    
    clrs = lines(10);
    
    figure
    subplot(1,2,1)
    for ii = 1:length(u)
        plot_confidence_intervals(O.psd_fqs,O.psd(O.STATE==u{ii},:),[],clrs(ii,:));
        hold on
    end
    xlabel('Hz')
    subplot(1,2,2)
    scatter(O.Tindex,O.Dindex,[],O.STATE)
    xlabel('theta');
    ylabel('delta');
    
    figure
    subplot(1,3,1)
    histogram(O.Dindex(:))
    xlabel('delta');

    subplot(1,3,2)
    histogram(O.Tindex(:))
    xlabel('theta');
    subplot(1,3,3)
    histogram(O.Tindex(:)./O.Dindex(:))
    xlabel('thetadelta ratio');
    
    
end
