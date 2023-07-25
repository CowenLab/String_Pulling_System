function [P,fq,Pshuff,PminusShuffZ] = Spike_psd(t_mS,t_bin_size_mS,fqs,smooth_win_mS )
% PSD of discrete action potential times.
% Method defaults to pburg. pmtm is another one that could be used. Much
% slower though
%
% test data... tested with CA1 neurons from the Schimanski dataset.
%
% INPUT:
% timestamps in milliseconds for spikes.
% bin size for the binning of spike times. 5ms is OK - depends on the
% frequency you are interested in.
% fqs = the desired fqs of the psd.
% smooth_win_mS = optional and will introduce 1/f psd  - will smooth spike
% trains after binning them. 20 ms is reasonable but again depends on the
% frequencies you are interested in. Will distort the psd.
%
% OUTPUT
% P is the psd.
% fq = frequencies of psd
%
% NOTE: Choosing Pshuff will SLOW THIS DOWN as it repeats nboot
% times. The ISIs for each spike train are shuffled, some jitter is added (40 ms std)
% and the PSD is recomputed nboot times and the std of this dist is determined.
%
% Pshuff = PSD after shuffling ISIs - should get rid of frequencies that go
% beyond ?? - will get rid of repeatnign cyclical adjacent 'oscillations'.
% However, this will not randomize true bursts (doublets) as they will
% still be in the data (so I added jitter as well). 
%
% Cowen 2020
PLOT_IT = false;
if nargout == 0
    PLOT_IT = true;
end
% For testing only...
if 0
    % Loaded cells for testing. Can this detect theta in neurons.
    A = load('C:\Users\Stephen Cowen\Dropbox\Foldershare\Src\matlab\Working\Neural_Data_Analysis\Artifical_Spikes\RealHippocampalSpikes_8700_Day01.mat')
    t_mS = [];
    cnt = 1;
    for ii = 1:length(A.S)
        tmp = Restrict(A.S(ii).t*100,A.TR.TI.Maze1.TRL.TrlStartEnd);
        if length(tmp) > 100
            t_mS{cnt} = tmp/1000;
            cnt = cnt + 1;
        end
    end
    t_bin_size_mS = 5;
    fqs = 1:.5:70;
    smooth_win_mS = 25;
    %     [PSD] = Spike_psd(t_mS,t_bin_size_mS,fqs,smooth_win_mS );
    [PSD,~,~,PSDz] = Spike_psd(t_mS,t_bin_size_mS,fqs,smooth_win_mS );
    figure
    subplot(3,1,1:2)
    imagesc(fqs,[],Z_scores(PSD')')
    subplot(3,1,3)
    plot_confidence_intervals(fqs,Z_scores(PSD')')
    
    figure
    subplot(3,1,1:2)
    imagesc(fqs,[],PSDz)
    subplot(3,1,3)
    plot_confidence_intervals(fqs,Z_scores(PSDz')')
    
    return
end

if nargin < 4
    smooth_win_mS = [];
end

P = nan(1,length(fqs));
fq = fqs;
Pshuff = [];
PminusShuffZ = nan(1,length(fqs));
if length(t_mS) < 30
    % if too few spikes, this is really just pointless and misleading. A
    % better cutoff is at least 70.
    disp(['Too few spikes ' mfilename])
    return
end

if iscell(t_mS)
    P = [];
    for ii = 1:length(t_mS)
        if nargout < 3
            [P(ii,:),fq] = Spike_psd(t_mS{ii},t_bin_size_mS,fqs,smooth_win_mS);
        else
            [P(ii,:),fq,Pshuff,PminusShuffZ] = Spike_psd(t_mS{ii},t_bin_size_mS,fqs,smooth_win_mS);
        end
        fprintf('>')
    end
    return
end
sFreq = 1/(t_bin_size_mS/1000);
tc = histcounts(t_mS,t_mS(1):t_bin_size_mS:t_mS(end));
if ~isempty(smooth_win_mS)
    % NOTE: doing this will impose a 1/f like PSD onto the data.
    % without it, spike train data looks pretty flate in the psds.
    npts = round(smooth_win_mS/t_bin_size_mS);
    tc = conv(tc(:),hanning(npts)./sum(hanning(npts)))';
end
if isempty(fqs)
    %     [P,fq] = pmtm(tc,[],[],sFreq);
    [P,fq] = pburg(tc,91,[],sFreq); %pburg(x,order,f,fs)
    
else
    [P,fq] = pburg(tc,91,fqs,sFreq); %pburg(x,order,f,fs)
    %     [P,fq] = pmtm(tc,[],fqs,sFreq);
end
if nargout > 2 || nargout ==0
    nboot = 30;
    Pshuff = zeros(nboot,length(P));
    for ii = 1:nboot
        jitter_sd = 40;
        t_mS_sh = Shuffle_ISIs(t_mS,'no_replacement',jitter_sd);
        Pshuff(ii,:) = Spike_psd(t_mS_sh,t_bin_size_mS,fqs,smooth_win_mS);
    end
    if nargout > 3
        PminusShuffZ = (P - mean(Pshuff))./std(Pshuff);
    end
    if PLOT_IT || nargout ==0
        figure
        subplot(3,1,1)
        imagesc(fqs,[],Pshuff);
        yyaxis right
        plot(fqs,mean(Pshuff),'y-','LineWidth',2);
        hold on
        plot(fqs,P,'w-','LineWidth',2);
        
        axis tight
        subplot(3,1,2)
        plot(fqs,P);
        axis tight
        title('P')
        subplot(3,1,3)
        plot(fqs,PminusShuffZ);
        axis tight
        title('shZ');ylabel('z')
        plot_horiz_line_at_zero(1.96)
        plot_horiz_line_at_zero(-1.96)
        drawnow
    end
end

