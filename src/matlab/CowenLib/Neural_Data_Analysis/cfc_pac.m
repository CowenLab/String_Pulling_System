function [pac] = cfc_pac(LF_phase,HF_power,window,overlap,num_iter)
% [pac] = cfc_pac(LF_phase,HF_power,num_iter)
%  This function calculates Phase Amplitude Coupling
% Cowen modification from Colin who developed from XCohen book
%  Added the shift method of random permutation - keeps the autocorr
%  structure of the data.
if  length(LF_phase)~=length(HF_power)
    error('LF_phase and HF_power must have the same length')
end
ncol = fix((length(LF_phase)-overlap)/(window-overlap));
colindex = 1 + (0:(ncol-1))*(window-overlap);
rowindex = (1:window)';
% lfph = NaN(window,ncol);
% hfpo = NaN(window,ncol);
lfph(:) = LF_phase(rowindex(:,ones(1,ncol))+colindex(ones(window,1),:)-1);
hfpo(:) = HF_power(rowindex(:,ones(1,ncol))+colindex(ones(window,1),:)-1);
% Do PAC without bootstrapping
pac = abs(mean(hfpo.*exp(1i*lfph),1));
% Note: this measure is sensitive to the power fluctuations in the HF band.
% An alternative is to bandpass the HF power in the same range as the lf
% band and THEN hilbert transform the signal in order to allow for
% phase-to-phase comparison. 
if ~isempty(num_iter)
    permutedPAC=zeros(num_iter,length(pac)),class(LF_phase);
    % Do bootstrapping
    % For method 1.
    random_timepoints = randsample(round(window*.8),num_iter)+round(window*.1);
    ix = [1:window]';
%     parpool(3)
    
%     parfor i = 1:num_iter
     for i=1:num_iter
        % Method 1 from Cohen
        lfph2 = lfph(circshift(ix,random_timepoints(i)),:);
        % Method 2 from Cohen - very slow. Does not preserve time series
        % info.
        %         lfph3 = lfph(randperm(window),:);
        %         lfph2 = lfph(RandPermFast(window),:);
        permutedPAC(i,:) = abs(mean(hfpo.*exp(1i*lfph2),1));
        fprintf('%d,',i)
    end
    pac = (pac-mean(permutedPAC,1))./std(permutedPAC);
end


