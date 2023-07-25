function [SP,INFO] = SPEC_spike_field_coherence_chronux(TS,DATA,sFreq,fq_range,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: TS   cell array of action potential times.
%        LFP  col 1= timestamps in uSec, col 2:end = LFP already filtered to the desired frequency
%        fq_ctrs = the center of each frequency band for labeling.
%        other parameters....
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO: Allow selection of just strong oscillatory intervals.
% Requires chronux toolbox - tested with v2.12
% [C,phi,S12,S1,S2,f,zerosp,confC,phistd,Cerr]=
% coherencycpt(data1,data2,params,fscorr,t)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rad_binsize = deg2rad(15); % bin size in radians
PLOT_IT = false;
min_spikes = 20; % you should have at least this many spikes to even consider statistical significance.
% Limit to high-power periods.
thresh_prctile_of_power = []; % if you want to do SFC but only during intervals above a certain threshold, then pass the threshold here (e.g., 80 = 80th percentile so only keep the upper 20% of data)
minimum_dur_in_samples = 200; % make the power windows long enough to gather enough cycles for SFC
Extract_varargin;

params.Fs = sFreq;
params.tapers= [3 5];
% params.pad = 1; % default is 0
% params.fpass = fq_range;
Ktapers=8; NW=(Ktapers+1)/2
params.tapers=[NW Ktapers]


%       data1        (continuous data in time x trials form) -- required
%       data2        (structure array of spike times with dimension trials; 
%                     also accepts 1d array of spike times) -- required
% [C,phi,S12,S1,S2,f,zerosp,confC,phistd,Cerr]=coherencycpt(DATA,data2,params,fscorr,t)
% map the timestmaps onto the rows in DATA... 
t = interp1(DATA(:,1),[0:Rows(DATA)-1]'/sFreq,TS{4});
% data2(1).times = t; % expectes structure array with index being channel (which is irrelevant here).

[C,phi,S12,S1,S2,f]=coherencycpt(DATA(:,2),t,params);
Cs = sgolayfilt(C,3,19001);
hold on
plot(f,Cs)

SP = [];
good_pow_intervals = cell(Cols(DATA)-1,1);
if ~isempty(thresh_prctile_of_power)
    PW = envelope_cowen(abs(DATA(:,iC)));
    th = prctile(PW(1:4:end),thresh_prctile_of_power);
    I = convn(PW>th,ones(1,minimum_dur_in_samples),'same')>0;
    good_pow_intervals = find_intervals([DATA(:,1) I],0);
    DATA = Restrict(DATA,good_pow_intervals);
end
% Ensure the timestamps are in the range of the LFP...
TS = Restrict(TS,DATA(1,1),DATA(end,1));

for iN = 1:length(TS)
    %     LFP2 = Restrict(LFP,TS{iN}(1)-.001,TS{iN}(end)+.001);
    SP(iN).fq_ctrs(iF) = fq_ctrs(iF);
    SP(iN).Ang_p(iF) = nan;
    SP(iN).Ang_z(iF) = nan;
    SP(iN).hist_rad(iF,:) = nan(1,length(rad_edges)-1);
    
    if length(TS{iN}) > min_spikes
        
        SP(iN).sig_ph_locking(iF) = SP(iN).Ang_to_shuf_p(iF) < 0.05 & SP(iN).Ang_p(iF) < 0.05 & SP(iN).n_bins_above_shuff(iF) > 0 & SP(iN).Ang_z(iF) > 5;
    end
end


if nargout == 0 || PLOT_IT
    %%
    for iN = 1:length(TS)
        if any(SP(iN).Ang_p<0.05)
            figure(iN*1000)
            clf
            bar(SP(iN).Ang_z)
            set(gca,'XTickLabel',SP(iN).fq_ctrs)
            ylabel('Rayleigh z')
            yyaxis right
            stem(SP(iN).Ang_p)
            ylabel('p value')
            xlabel('Hz')
            title(sprintf('NEURON %g ',iN))
        end
        
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
    %%
end