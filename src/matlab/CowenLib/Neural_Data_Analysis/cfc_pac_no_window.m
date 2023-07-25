function [pac] = cfc_pac_no_window(LF_phase,HF_power,num_iter)
% [pac] = cfc_pac(LF_phase,HF_power,num_iter)
%  This function calculates Phase Amplitude Coupling
% Cowen modification from Colin who developed from XCohen book
if  length(LF_phase)~=length(HF_power)
    error('LF_phase and HF_power must have the same length')
end
if nargin < 3
    num_iter = 100;
end
LF_phase = LF_phase(:);
HF_power = HF_power(:);
% % Do PAC without bootstrapping
pac = abs(mean(HF_power.*exp(1i*LF_phase)));
% Note: this measure is sensitive to the power fluctuations in the HF band.
% An alternative is to bandpass the HF power in the same range as the lf
% band and THEN hilbert transform the signal in order to allow for
% phase-to-phase comparison.
if ~isempty(num_iter)
    permutedPAC=zeros(num_iter,1,class(LF_phase));
    % Do bootstrapping
    % For method 1.
    %     random_timepoints = randsample(round(window*.8),num_iter)+round(window*.1);
    ix = (1:length(LF_phase))';
    random_timepoints = randsample(round(length(LF_phase)*.8),num_iter)+round(length(LF_phase)*.1);
    
    for i=1:num_iter
        % Method 1 from Cohen
        ix2 = circshift(ix,[random_timepoints(i) 0]);
        %         lfph2 = circshift(lfph,random_timepoints(i),2);
        % Method 2 from Cohen - very slow. Does not preserve time series
        % info.
        %         lfph2 = LF_phase(randperm(window),:);
        %         lfph2 = lfph(RandPermFast(window),:);
        permutedPAC(i) = abs(mean(HF_power.*exp(1i*LF_phase(ix2,:))));
    end
    pac = (pac-mean(permutedPAC,1))./std(permutedPAC);
end


