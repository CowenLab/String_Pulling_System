function [MI] = SPEC_cross_fq_coupling_comodulogram_Schmit(values,hf,lf,phase_bins,sFreq,wavelet_width,GOODIX)
% values         - LFP values
% hf             - Vector of high frequencies (power)
% lf             - Vector of low frequencies  (phase)
% phase_bins     - Number of bins to divide 360 degrees into. Kpell likes 10
%                  degre bins
% sFreq          - Not sure what this is, probably not important.
% wavelet_width  - For wavelet decomp, biger wavelet, more fq precision
% suffix         - for saving
% Tort ABL, Komorowski R, Eichenbaum H, Kopell N.
% Measuring Phase-Amplitude Coupling Between Neuronal Oscillations of Different Frequencies.
% Journal of Neurophysiology. 2010;104(2):1195-1210. doi:10.1152/jn.00106.2010.
if nargin < 7
    GOODIX = [];
end
use_toolbox_cwt = false; % the cwt is a work in progress- not finished so don't make this TRUE until it is worked out
if use_toolbox_cwt
    disp('Using cwt toolbox')
% else
%     disp('Using Cohen method (Colin)')
end
PLOT_IT = true;
%Create bin edges
if isempty(phase_bins)
    phase_bins = 360/10; % 10 degree bins.
end
vec = linspace(-pi,pi,phase_bins+1);

meanie = NaN(1,phase_bins);
MI = NaN(length(hf),length(lf));

% do this at the start to save time - requires some memory though.
if use_toolbox_cwt
    % Work in progress- it appear to be working. Similar results to the
    % Cohen method
    [hf_power] = SPEC_cwt_cowen(values,sFreq,hf,32);
    hf_power = abs(hf_power);
    [lf_phase] = SPEC_cwt_cowen(values,sFreq,lf,32);
    lf_phase = angle(lf_phase); %
else
    [~, hf_power] = SPEC_waveletdecomp(hf,values,sFreq,wavelet_width);
    [lf_phase] = SPEC_waveletdecomp(lf,values,sFreq,wavelet_width);
end
if ~isempty(GOODIX)
    lf_phase = lf_phase(:,GOODIX);
    hf_power = hf_power(:,GOODIX);
end
for lix = 1:length(lf) % For every lf
    %     [lf_phase] = waveletdecomp(lf(lix),values,sFreq,wavelet_width);
    %     [lf_phase] = SPEC_waveletdecomp(lf(lix),values,sFreq,wavelet_width);
    
    for j = 1:length(hf); % for every hf
        %         [~, hf_power, ~] = waveletdecomp(hf(j),values,sFreq,wavelet_width);
        for i = 1:phase_bins
            % Inefficient, but excracts all points within that phase bin
            ix = lf_phase(lix,:) > vec(i) & lf_phase(lix,:) <= vec(i+1);
            meanie(i) = mean(hf_power(j,ix));
        end
        % Normalize
        % we normalize the mean amplitude by dividing each bin value by the sum over the bins
        meanie(:) = meanie(:)/sum(meanie(:));
        %  Kullback–Leibler distance (DKL), infer the amount of difference between two distributions
        % Similar to Shannon Entropy
        % H(P)=??j=1NP(j)?log?[P(j)]
        H = -sum(meanie.*log(meanie));
        % The KL distance is related to the Shannon entropy by
        % DKL(P,?U)=log(N)?H(P)
        % And we define MI as:
        % MI=DKL(P,U)/log(N)
        % So...
        % MI = log(N)?H(P)/log(N)
        MI(j,lix) = (log(phase_bins)-H)/log(phase_bins);
    end
    fprintf('>')
end

if nargout == 0 || PLOT_IT
    clf
    imagesc(lf,hf,MI)
    % set(gca,'XTick',(1:length(lf)),'XTickLabel',lf,'YTick',(1:length(hf)),'YTickLabel',hf)
    axis xy
    title('Modulation Index')
    xlabel('Low Fq (Hz)')
    ylabel('High Fq (Hz)')
    h = colorbar;
    ylabel(h,'Modulation Index')
    colormap(jet)
    drawnow
end

