function [O,imf,imfs,psd,fqs] = SPEC_eemd_by_band(LFP,sFreq,bands,P)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [O] = SPEC_eemd_by_band(LFP,sFreq,P) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Ensemble Empirical Mode Decomposition (and regular emd)... 
% 
% see Wang, Y.-H., Yeh, C.-H., Young, H.-W.V., Hu, K., Lo, M.-T., 2014. On
% the computational complexity of the empirical mode decomposition
% algorithm. Phys. A Stat. Mech. its Appl. 400, 159–167.
% https://doi.org/10.1016/j.physa.2014.01.020
%
% Requires code from wang but rename the emd function and references to
% emd_wang so that it does not interfere with Matlab's emd function.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen (2018)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4
    P.emdnItr = 100;
    P.icanItr = 100;
    P.numImf = 8;
    P.nComps = 5;
    P.noiselevel = .4;
    P.method = 'eemd'; % emd
    P.PLOT_IT = false;
end
fqs = min(bands(:)):0.25:max(bands(:));
pbOrd = 120;

switch P.method
    case 'emd'
        % Matlab's built in. pchip or spline
        [imf,residual,info] = emd(LFP,'Interpolation','pchip','SiftMaxIterations',P.emdnItr,'MaxNumIMF',P.numImf);
    case 'eemd'
        % From Wang...
        [imf] = eemd(LFP,P.noiselevel,P.emdnItr,P.numImf);
        imf = imf';
end

% figure; plot(LFP); hold on; plot(sum(imf(:,2:end),2))

% Find the peak frequency for each band.
% [p,f] = pwelch(imf(:,1),sFreq,round(sFreq/2),fqs,sFreq);
[p,f] = pburg(imf(:,1),pbOrd,fqs,sFreq);
psd = zeros(Cols(imf),length(f));
psd(1,:) = 10*log10(abs(p));
for ii = 2:Cols(imf)
    %     [p,f] = pwelch(imf(:,ii),sFreq,round(sFreq/2),fqs,sFreq);
    p = pburg(imf(:,ii),pbOrd,fqs,sFreq);
    %     figure;pburg(imf(:,ii),pbOrd,fqs,sFreq);
    psd(ii,:) = 10*log10(abs(p));
end
% [minval, min_psd_ix] = min(psd,[],2);
% trough_fqs = fqs(min_psd_ix);
% modify psd
% new_psd = psd;
% for ii = 1:Rows(new_psd)
%     new_psd(ii,min_psd_ix(ii):end) = 0;
% end

% if P.lowPass
%     % This will quash high frequency for those situations where there is a
%     % minima above the upper band frequency.
%     for ii = 1:Rows(new_psd)
%         N = 10;
%         if trough_fqs(ii) > fqs(1)+1 && trough_fqs(ii) < fqs(end)-4
%             lowpa = designfilt('lowpassiir','FilterOrder',N, ...
%                 'PassbandFrequency',trough_fqs(ii),...
%                 'SampleRate',sFreq);
%             imf(:,ii) = filtfilt(lowpa,imf(:,ii));
%             figure;pburg(imf(:,ii),pbOrd,fqs,sFreq);
% 
%         end
%     end
% end

[~, ix] = max(psd,[],2);
peak_fqs = fqs(ix);

O = nan(Rows(LFP),Rows(bands));
imfs = cell(Rows(bands),1);
for iB = 1:Rows(bands)
    imfs{iB} = find(peak_fqs >= bands(iB,1) & peak_fqs < bands(iB,2));
    if ~isempty(imfs{iB})
        O(:,iB) = sum(imf(:,imfs{iB}),2);
    end
end
% DONE: On to the next thing.
% Find the bands
% [HH,f] = hht(imf,sFreq);
% [pks,ix] = max(HH,[],1);
% f(ix)
% [pc,sc,lat] = pca(imf);
%
% Mdl = rica(sc(:,1:P.nComps),P.nComps,'IterationLimit',P.icanItr);
% z = transform(Mdl,sc(:,1:P.nComps));

if nargout == 0 || P.PLOT_IT
    figure
    plot_LFP([LFP, O],sFreq)
    
    figure
    plot(fqs,psd(1:6,:)')
    legend()
    
    figure;
    hht(imf,sFreq);
    figure;
    hht(O,sFreq);
    figure
    scatter3(O(:,1),O(:,2),O(:,3),'.')
    
    if 0
        figure
        subplot(3,1,1)
        imagesc(pc)
        xlabel('Component')
        subplot(3,1,2)
        plot(cumsum(lat/sum(lat)),'o-')
        ylabel('cumsum latent')
        
        figure(1)
        for ii = 1:5
            subplot_ij(5,2,ii,1)
            pwelch(sc(:,ii),sFreq,round(sFreq/2),[],sFreq)
            title(['PC' num2str(ii)])
            subplot_ij(5,2,ii,2)
            pwelch(z(:,ii),sFreq,round(sFreq/2),[],sFreq)
            title(['ICA' num2str(ii)])
        end
        figure
        plot_LFP([LFP, z],sFreq)
    end
    
end