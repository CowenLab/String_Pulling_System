function [SP,INFO] = SPEC_spike_field_coupling(TS_uS,DATA,fq_ctrs,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: TS_uS   cell array of action potential times (uS).
%        FILTERED LFP: col 1= timestamps in uSec, col 2:end = LFP already filtered to the desired frequency
%        fq_ctrs = the center of each frequency band for labeling.
%        other parameters....
%
% METHOD: Uses the hilbert approach 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO: Allow selection of just strong oscillatory intervals.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rad_binsize = deg2rad(15); % bin size in radians
PLOT_IT = false;
shuffle_type = 'jitter_ISI';%'shift_LFP'; % Careful- Harris paper suggests shifting may not do the job. Alt jitter_ISI
n_shuffs = 200; % this can take a while but you should have a minimum of 20. 40 is good - but slow.
min_spikes = 20; % you should have at least this many spikes to even consider statistical significance.
% Limit to high-power periods.
thresh_prctile_of_power = []; % if you want to do SFC but only during intervals above a certain threshold and
 % if you set a threshold also pass in the min number of cycles you want (e.g., [80 10] = 80th percentile so only keep the upper 20% of data, and min 10 cycles) 
minimum_dur_in_samples = 200; % make the power windows long enough to gather enough cycles for SFC

Extract_varargin;

rad_edges = -pi:rad_binsize:pi;
INFO.rad_edges = rad_edges;
INFO.n_shuffs = n_shuffs;
SP = [];

minimum_dur_sec = [];
if ~isempty(fq_ctrs)
    for iC = 1:length(fq_ctrs)
       minimum_dur_sec(iC) = (1/fq_ctrs(iC))*thresh_prctile_of_power(2);
    end
end
%
% A = zeros(Rows(LFP),Cols(LFP)-1);
% replace the LFP with ang to save memory
good_pow_intervals = cell(Cols(DATA)-1,1);
for iC = 2:Cols(DATA)
    if ~isempty(thresh_prctile_of_power)
        PW = envelope_cowen(abs(DATA(:,iC)));
        th = prctile(PW(1:4:end),thresh_prctile_of_power(1));
        I = convn(PW>th,ones(1,minimum_dur_in_samples),'same')>0;
%         good_pow_intervals{iC-1} = find_intervals([DATA(:,1) I],0);
        pow_intervals = find_intervals([DATA(:,1) I],0);
        GIX = pow_intervals(:,2)-pow_intervals(:,1) >= minimum_dur_sec(iC-1)*1e6;
        good_pow_intervals{iC-1} = pow_intervals(GIX,:);
        % make sure each LFP interval is longer than some minimum duration
        % so that there is enough data to do a meaninful analysis.
        %         GIX = I(:,2)-I(:,1) >= minimum_dur_sec*1e6;
        %         good_pow_intervals{iC-1} = I(GIX);
        
    end
    DATA(:,iC) = angle(hilbert(DATA(:,iC))); % Convert to radians
    
end

% Ensure the timestamps are in the range of the LFP...
% TS_uS = Restrict(TS_uS,DATA(1,1),DATA(end,1));
% Need raw for this. and sFreq
%                     [A]  = Phase_pow_fq_detector_waveshape(LFP(:,2),L(:,ii),LFP.sFreq); % phase based on shape.

for iF = 1:Cols(DATA)-1
    Ang = DATA(:,[1 iF+1]);
    if ~isempty(good_pow_intervals{iF})
        Ang = Restrict(Ang,good_pow_intervals{iF});
        % note: Ts is not restricted.
        TS_uS_powr = [];
        for iN = 1:length(TS_uS)
            TS_uS_powr{1,iN} = Restrict(TS_uS{1,iN},good_pow_intervals{iF});
        end

        for iN = 1:length(TS_uS_powr)
            %     LFP2 = Restrict(LFP,TS{iN}(1)-.001,TS{iN}(end)+.001);
            SP(iN).fq_ctrs(iF) = fq_ctrs(iF);
            SP(iN).Ang_p(iF) = nan;
            SP(iN).Ang_z(iF) = nan;
            SP(iN).hist_rad(iF,:) = nan(1,length(rad_edges)-1);
            SP(iN).Ang_to_shuf_p(iF) = nan;
            SP(iN).Ang_to_shuf_F(iF) = nan;
            SP(iN).sh_hist_rad_mn(iF,:) = nan(1,length(rad_edges)-1);
            SP(iN).sh_hist_rad_95ci(iF,:) = nan(1,length(rad_edges)-1);
            SP(iN).n_bins_above_shuff(iF,:) = nan(1,length(rad_edges)-1);
            SP(iN).sig_ph_locking(iF,:) = nan(1,length(rad_edges)-1);
            SP(iN).good_pow_intervals{iF,1} = good_pow_intervals{iF,1};
            if length(TS_uS_powr{iN}) > min_spikes
                Ang_ts = interp1(Ang(:,1),Ang(:,2),TS_uS_powr{iN},'nearest'); % can't use linear - strange things happen
                if sum(~isnan(Ang_ts)) > 1
                    [SP(iN).Ang_p(iF), SP(iN).Ang_z(iF)] = circ_rtest(Ang_ts(~isnan(Ang_ts)));
                else
                    SP(iN).Ang_p(iF) = nan;
                    SP(iN).Ang_z(iF) = nan;
                end
                
                % Shuffle the spikes, but keep in range of LFP.
                SP(iN).hist_rad(iF,:) = histcounts(Ang_ts,rad_edges);
                shist_rad = nan(n_shuffs,length(rad_edges)-1);
                aa = [];
                for iShuf = 1:n_shuffs
                    switch shuffle_type
                        case 'ISI'
                            t = Shuffle_ISIs(TS_uS_powr{iN});
                            t = Restrict(t,TS_uS_powr{iN}(1)-.001,TS_uS_powr{iN}(end)+.001);
                            if length(t)>1
                                a = interp1(DATA(:,1),DATA(:,iF+1),t,'nearest');
                                aa = [aa;a];
                                shist_rad(iShuf,:) = histcounts(a,rad_edges);
                            end
                        case 'shift_LFP' % I think a little faster than ISI. It might distort non-stationarities more though.
                            r = randi(Rows(Ang),1) + minimum_dur_in_samples;
                            shAng = circshift(Ang(:,2),r); % Harris did not like this. Preferrs linear shift or grabbing LFP from another day. Harris KD. 2020. Nonsense correlations in neuroscience. bioRxiv:1–13.
                            a = interp1(Ang(:,1),shAng,TS_uS_powr{iN},'nearest');
                            
                            aa = [aa;a];
                            shist_rad(iShuf,:) = histcounts(a,rad_edges);
                        case 'jitter_ISI' % This likely does a better job of dealing with slow non-stationarities.
                            % This has not been thoroughly validated.
                            interval_sec = 1/fq_ctrs(iF);
                            jitter_interval_uS = (20*interval_sec)*1e6; % seems reasonable to jitter around 20 cycles around the action potential.
                            t = TS_uS_powr{iN} + (rand(length(TS_uS_powr{iN}),1)-.5)*jitter_interval_uS;
                            t = Restrict(t,TS_uS_powr{iN}(1)-.001,TS_uS_powr{iN}(end)+.001);
                            if length(t)>1
                                a = interp1(DATA(:,1),DATA(:,iF+1),t,'nearest');
                                aa = [aa;a];
                                shist_rad(iShuf,:) = histcounts(a,rad_edges);
                            end
                    end
                end
                aa = aa(~isnan(aa));
                % Compare the shuffle to the generated distribution.
                %             shAng = shAng(~isnan(shAng));
                warning off
                if sum(~isnan(Ang_ts)) > 1
                    [SP(iN).Ang_to_shuf_p(iF), SP(iN).Ang_to_shuf_F(iF)] = circ_ktest(Ang_ts(~isnan(Ang_ts)), aa);
                else
                    SP(iN).Ang_to_shuf_p(iF) = nan;
                    SP(iN).Ang_to_shuf_F(iF) = nan;
                end
                warning on
                SP(iN).sh_hist_rad_mn(iF,:) = nanmean(shist_rad);
                SP(iN).sh_hist_rad_95ci(iF,:) = nanstd(shist_rad)*1.96;
                SP(iN).n_bins_above_shuff(iF) = sum(SP(iN).hist_rad(iF,:) > SP(iN).sh_hist_rad_mn(iF,:) + SP(iN).sh_hist_rad_95ci(iF,:));
                SP(iN).sig_ph_locking(iF) = SP(iN).Ang_to_shuf_p(iF) < 0.05 & SP(iN).Ang_p(iF) < 0.05 & SP(iN).n_bins_above_shuff(iF) > 0 & SP(iN).Ang_z(iF) > 5;
            end
        end
    else
        for iN = 1:length(TS_uS)
            SP(iN).fq_ctrs(iF) = fq_ctrs(iF);
            SP(iN).Ang_p(iF) = nan;
            SP(iN).Ang_z(iF) = nan;
            SP(iN).hist_rad(iF,:) = nan(1,length(rad_edges)-1);
            SP(iN).Ang_to_shuf_p(iF) = nan;
            SP(iN).Ang_to_shuf_F(iF) = nan;
            SP(iN).sh_hist_rad_mn(iF,:) = nan(1,length(rad_edges)-1);
            SP(iN).sh_hist_rad_95ci(iF,:) = nan(1,length(rad_edges)-1);
            SP(iN).n_bins_above_shuff(iF,:) = nan(1,length(rad_edges)-1);
            SP(iN).sig_ph_locking(iF,:) = nan(1,length(rad_edges)-1);
            SP(iN).good_pow_intervals{iF,:} = nan;
        end
    end
end

if nargout == 0 || PLOT_IT
    %%
    if ~isempty(good_pow_intervals{iF})
        for iN = 1:length(TS_uS_powr)
            %         if any(SP(iN).Ang_p<0.05)
            %             figure(iN*1000)
            %             clf
            %             bar(SP(iN).Ang_z)
            %             set(gca,'XTickLabel',SP(iN).fq_ctrs)
            %             ylabel('Rayleigh z')
            %             yyaxis right
            %             stem(SP(iN).Ang_p)
            %             ylabel('p value')
            %             xlabel('Hz')
            %             title(sprintf('NEURON %g ',iN))
            %         end
            
            for iF = 1:Cols(DATA)-1
                if SP(iN).Ang_p(iF)< 0.05
                    figure(iN*100)
                    subplot(2,ceil((Cols(DATA)-1)/2),iF)
                    polarhistogram('BinEdges',rad_edges,'BinCounts',SP(iN).sh_hist_rad_mn(iF,:) ,'DisplayStyle','stairs','EdgeColor','k')
                    hold on
                    polarhistogram('BinEdges',rad_edges,'BinCounts',SP(iN).sh_hist_rad_mn(iF,:) + SP(iN).sh_hist_rad_95ci(iF,:) ,'DisplayStyle','stairs','EdgeColor',[.5 .5 .5])
                    polarhistogram('BinEdges',rad_edges,'BinCounts',SP(iN).hist_rad(iF,:),'FaceAlpha',.5)
                    title(sprintf('%g %dHz p=%1.3f z=%2.1f ps=%1.3f spl %d ',iN,SP(iN).fq_ctrs(iF),SP(iN).Ang_p(iF),SP(iN).Ang_z(iF),SP(iN).Ang_to_shuf_p(iF),SP(iN).sig_ph_locking(iF)),'FontSize',7)
                end
            end               
        end
    else
    end
    %%
end
