function [pac, pacp, pacraw] = SPEC_cross_fq_coupling_pac(LF_phase,HF_power,window,overlap,num_iter,method)
%% [pac] = cfc_pac(LF_phase,HF_power,num_iter)
%  This function calculates Phase Amplitude Coupling
% Cowen modification from Colin who developed from XCohen book
%  Added the shift method of random permutation - keeps the autocorr
%  structure of the data.
% Cowen - modified to make much more memory efficient.
% Cowen - needs to deal with Nans. Added nanmeans.
if nargin == 0
    % Validate...
    [L1, INFO] = Artificial_LFP(500, 40, [7], [0], 0.01 );
    [L2] = Artificial_LFP(500, 40, [40], [0], 0.01 );
    L3 = L1 + abs(L1 > 0).*(L2*.5);
    % I NOW KNOW WHY THIS IS NOT WORKING - it's because phase is PERFECTLY
    % locked the entire time withth erandoms singal and even shuffling by
    % shifting the time in one trace will only decrement the phase locking
    % a little bit so your random phase locking will look REALLY HIGH. To
    % make this more realistic, the data should not be perfectly phase
    % locked and the frequency should shift somewhat randomly through time
    % and not be perfect.
    
    % put some random spaces in the data - otherwise the permutation method
    % of baseline calculation would not work as no matter how you would
    % time-shift the data, 1/2 of the dat would be strongly phse coupled.
    figure
    plot(L1)
    hold on
    plot(L2)
    plot(L3,'k','LineWidth',4)
    legend_cowen('1','2','3')
    
    % Filter
    filter_order = 8;
    filterweightsLF = designfilt('bandpassiir','FilterOrder',filter_order, ...
        'HalfPowerFrequency1',5 ,'HalfPowerFrequency2',10, ...
        'SampleRate',500,'DesignMethod' ,'butter');
    filterweightsHF = designfilt('bandpassiir','FilterOrder',filter_order, ...
        'HalfPowerFrequency1',35 ,'HalfPowerFrequency2',50, ...
        'SampleRate',500,'DesignMethod' ,'butter');
    Lf = filtfilt(filterweightsLF,L3);
    LFph = angle(hilbert(Lf));
    Hf = filtfilt(filterweightsHF,L3);
    HFp = envelope_cowen(Hf);
    figure
    subplot(4,1,1)
    plot(Lf)
    hold on
    plot(Hf)
    
    
    subplot(4,1,2)
    plot(LFph)
    hold on
    plot(HFp)
    
    [pac, pacp, pacraw] =  SPEC_cross_fq_coupling_pac(LFph(:),HFp(:),500*10,0,100,2);
    [pacr, pacpr, pacraw_r] =  SPEC_cross_fq_coupling_pac(LFph(:),HFp(randperm(length(HFp))),500*10,0,100,1);

    subplot(4,1,3)
    bar([pac(:) pacr(:)])
    
    nbins=18;
    nsurrogates=200;
    randtype=2; %timesplice
    mi = [];
    n = 1000;
    rp_big = randperm(length(LFph));
    for ii = 1:20
        rp = randperm(length(LFph));
        out = get_mi(LFph(rp(1:n))',HFp(rp(1:n))',nbins,nsurrogates,randtype);
        mi(ii) = out.MI;
        out2 = get_mi(LFph(rp(1:n))',HFp(rp_big(1:n))',nbins,nsurrogates,randtype);
        mis(ii) = out.MIsurr;
        
        [ppac(ii), ppacp(ii), ppacraw(ii)] =  SPEC_cross_fq_coupling_pac_no_window(LFph(rp(1:n))',HFp(rp(1:n))',nsurrogates,1);

        [rppac(ii), rppacp(ii), rppacraw(ii)] =  SPEC_cross_fq_coupling_pac_no_window(LFph(rp(1:n))',HFp(rp_big(1:n))',nsurrogates,1);

        
    end
    return
end

if  length(LF_phase)~=length(HF_power)
    error('LF_phase and HF_power must have the same length')
end

if nargin < 6
    method = 1;
end
if nargin < 5
    if method ==1 || method == 3
        % Seems to require more permutations given the variance in the
        % estimates.
        num_iter = 200;
    else
        % A more clean distribution - requires fewer samples to estimate.
        num_iter = 100;
    end
end

pacp = [];
ncol = fix((length(LF_phase)-overlap)/(window-overlap));

if sum(~isnan(LF_phase+ HF_power)) < window
    disp('TOO MANY NANS IN THIS WINDOW. ABORTING.')
    pac = NaN(1,ncol);
    pacp = NaN(1,ncol);
    return
end

colindex = 1 + (0:(ncol-1))*(window-overlap);
rowindex = (1:window)';
lfph = LF_phase(rowindex(:,ones(1,ncol))+colindex(ones(window,1),:)-1);
hfpo = HF_power(rowindex(:,ones(1,ncol))+colindex(ones(window,1),:)-1);
% Do PAC without permutation testing
pacraw = abs(nanmean(hfpo.*exp(1i*lfph),1));
% histogram(rad2deg(angle(nanmean(hfpo.*exp(1i*lfph),1))))
% Note: this measure is sensitive to the power fluctuations in the HF band.
% An alternative is to bandpass the HF power in the same range as the lf
% band and THEN hilbert transform the signal in order to allow for
% phase-to-phase comparison.
if isempty(num_iter)
    disp('You should use at LEAST 100 permutations to compute pac. It is very prone to contamination by high-power events.')
else
    permutedPAC = zeros(num_iter,length(pacraw),class(LF_phase));
    % Do bootstrapping
    % For method 1.
    random_timepoints = [];
    if method == 1
        if round(window*.8) > num_iter
            random_timepoints = randsample(round(window*.8),num_iter)+round(window*.1);
        else
            random_timepoints = randperm(window);
            random_timepoints(random_timepoints < window/10) = [];
            while length(random_timepoints) < num_iter
                random_timepoints = [random_timepoints(:); randperm(window)'];
                random_timepoints(random_timepoints < window/10) = [];
            end
            random_timepoints = random_timepoints(1:num_iter);
        end
    end
    %     parpool(3)
    %     parfor i = 1:num_iter
%     fprintf(['Permutation meth' num2str(method) ' ->  '])
%     tic
    for i=1:num_iter
        switch method
            case 1
                % Permutation method 1: select random time point
                %                     random_timepoint = randsample(round(Rows(hfpo)*.8),1)+round(Rows(hfpo)*.1);
                %                     timeshiftedpwr   = [ hfpo(random_timepoint:end,:); hfpo(1:random_timepoint-1,:) ];
                %                     permutedPAC2 = abs(nanmean(timeshiftedpwr.*exp(1i*lfph)));
                % TO DO:
                %                 r = randsample((window-20)+10,20); % chose 20 random starting points;
                %                 rs = sort(r);
                %                 st = rs(1:2:end-1);
                %                 ed = rs(2:2:end);
                %                 ix = zeros(window,1);
                %
                %                 for ii = 1:length(r)
                %                     ix2 = find(rs>r(ii),'first',1);
                %                     ln = r(ix2) - r(ii) + 1;
                %                     ix(r(ii):r(ix2)) = 0;
                %                 end
                %  ix2 = circshift(rowindex(:),[random_timepoints(i) 0]);
                % for ii = 1:20
                %     ch_size = round(window*.2);
                %     % grab a chunk and put it somewhere else.
                %     ix2(random_timepoints(ii):random_timepoints(ii)+ch_size)
                %                 ix2 = circshift(ix2,[random_timepoints(ii) 0]);
                % end
                ix2 = circshift(rowindex(:),[random_timepoints(i) 0]);
                permutedPAC(i,:) = abs(nanmean(hfpo.*exp(1i*lfph(ix2,:)),1));
            case 2
                % Permutation method 2: totally randomize power time series
                % Cohen does not recommend this - from personal coversation
                % and he suggests this in his book.
                % NOTE: Colin rand tests using artificial data and this
                % method performed better than method 1 at detecting CFC
                % events. Method 1 just missed CFC events. The confusion is
                % that this method is in theoretically non-preferred as it
                % does not include autocorr information which could be a
                % source of spurious CFC events. Upshot, this method has a lower false
                % negative but higher false postive rate than method 1.
                % Tradoffs.
                % A big concern that I have with this is that if you
                % compare this with the pac value - THE VAST majority of
                % values are above zero. This stronly indicates that the
                % pacz values do not represent mean above chance.
                % Consequently - comparisons above some other baseline is
                % the only thing you can do as you cannot trust the p
                % values.

                permutedPAC(i,:)  = abs(nanmean(hfpo.*exp(1i*lfph(randperm(window),:))));
                
            case 3
                % Permutation method 3: FFT-based power time series randomization
                % this is slow and perhaps not implemented optimally. 
                f = fft(hfpo); % compute FFT
                A = abs(f);   % extract amplitudes
                zphs=cos(angle(f))+1i*sin(angle(f)); % extract phases
                powernew=real(ifft(A.*zphs(randperm(Rows(zphs)),:))); % recombine using randomized phases (note: use original phases to prove that this method reconstructs the original signal)
                powernew=powernew-repmat(min(powernew),Rows(powernew),1);
                permutedPAC(i,:)  = abs(nanmean(powernew.*exp(1i*lfph)));
        end
%         if rem(i,20)==0
%             fprintf('%d,',i)
%         end
    end
%     fprintf(' took %f min\n',toc/60)
    pac = (pacraw-nanmean(permutedPAC,1))./nanstd(permutedPAC,[],1); % I compared the trimmed mean vs. the mean vs. the median and there is virutally no differnece.

    if nargout > 1
        m = repmat(pacraw,Rows(permutedPAC),1)-permutedPAC;
        pacp = ones(size(pac),class(pac));
        for ii = 1:length(pac)
            pacp(ii) = signtest(m(:,ii),0,'tail','right'); % Only values ABOVE the permuted values are really valid (the right side)
        end        
    end
    % The logic for dividing by the std is that if there is a lot of
    % variation in the permutations, then it would suggest that there is a
    % lot of artifactual noise in the system. On the other hand, could it
    % not also mean that there is, once in a while, repeating phase
    % coupling and permuting results in
    %     pac2 = (pac-prctile(permutedPAC,50))./iqr(permutedPAC); % IF you have very non-normal distributions, then this is an option.
    %     hist([pac(:) permutedPAC(1,:)'],100)
    %     figure
    %     hist([pac(:) mean(permutedPAC)'],100)
    %     figure
    %     hist([pac(:)-mean(permutedPAC)'],100)
end

