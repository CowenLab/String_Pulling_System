function [pac] = cfc_ppc(LF_phase,HF_lowpass_phase,window,overlap,num_iter)
% [pac] = cfc_pac(LF_phase,HF_power,num_iter)
%  TThis is phase-phase coupling and taken from
%  http://neuroinformatics.gr/node/41
% Cowen
if  numel(LF_phase)~=numel(HF_lowpass_phase)
    error('LF_phase and HF_lowpass_phase must have the same length')
end
ncol = fix((numel(LF_phase)-overlap)/(window-overlap));
colindex = 1 + (0:(ncol-1))*(window-overlap);
rowindex = (1:window)';
lfph = NaN(window,ncol);
hfph = NaN(window,ncol);
lfph(:) = LF_phase(rowindex(:,ones(1,ncol))+colindex(ones(window,1),:)-1);
hfph(:) = HF_lowpass_phase(rowindex(:,ones(1,ncol))+colindex(ones(window,1),:)-1);
% Do PAC without bootstrapping
pac = abs(mean(exp(1i*(lfph - hfph)),1));
% pac = abs(mean(hfpo.*exp(1i*lfph),1));
% % Note: this measure is sensitive to the power fluctuations in the HF band.
% An alternative is to bandpass the HF power in the same range as the lf
% band and THEN hilbert transform the signal in order to allow for
% phase-to-phase comparison. 
if ~isempty(num_iter)
    permutedPAC=zeros(num_iter,numel(pac));
    % Do bootstrapping
    % For method 1.
    %     random_timepoints = randsample(round(window*.8),num_iter)+round(window*.1);

    for i=1:num_iter
        % Method 1 from Cohen
        %         lfph2 = circshift(lfph,random_timepoints(i),2);
        % Method 2 from Cohen - very slow. Does not preserve time series
        % info.
        lfph2 = lfph(randperm(window),:);
        %         lfph2 = lfph(RandPermFast(window),:);
        permutedPAC(i,:) = abs(mean(exp(1i*(lfph2 - hfph)),1));
    end
    pac = (pac-mean(permutedPAC,1))./std(permutedPAC);
end


