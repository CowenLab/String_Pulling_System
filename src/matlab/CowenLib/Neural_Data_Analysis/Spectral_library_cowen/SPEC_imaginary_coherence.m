function [Ci, specX] = SPEC_imaginary_coherence(x,y)
% NOTE: if using wavelets, be sure to use a HUGE wavelet order (say 35) if
% you want any reasonable frequency resolution.
%
% See cohen ch 26 See Nolte G, Bai O, Wheaton L, Mari Z, Vorbach S, Hallett
% M (2004) Identifying true brain interaction from EEG data using the
% imaginary part of coherency. Clin Neurophysiol 115:2292–2307.
%
% NOTE: x and y must be complex!! Have phase and power in their structure.
% See SPEC_waveletdecomp and use the 5th output. In retrospct, don't know
% why this isn't the original output anyway. seems like a wast to convert
% it from complex.
% 
% Nolte, G., Bai, O., Wheaton, L., Mari, Z., Vorbach, S., and Hallett, M. (2004). Identifying true brain interaction from EEG data using the imaginary part of coherency. Clin. Neurophysiol. 115, 2292–2307. doi:10.1016/j.clinph.2004.04.029.
%
% Cowen 2016
if nargout ==0
    %%
    % upshot - iCohere does work in that phase-lags of 0 do have 0
    % coherence. There are 2 problems however: 1) the size if iCoh is very
    % much dependent on the offset chosen so different phase lags for the
    % same signal will have very different values of iCoh. This is a
    % problem as it confounds these two measures. 2) at least the use of
    % wavelets makes frequency resolution terrible unless you use very
    % large wavelests (say 35). This could probably be improved by using
    % the Fourier-Hilbert transform instead of wavelets.
    %
    noverlap = 128; nfft = 512;
    srate = 1e3;
    tgt = 135;
    nSecs = 20;
    offset = 13;
    wave_size = 35; % needs to be much bigger than 5 for this to have any reasonable frequency specificity with wavelets
    t = 0:1/srate:nSecs;
    %     x = chirp(t,0,20,250);
    x = sin(t*2*pi*tgt);
    x(1:srate*5) = randn(size( x(1:srate*5) ))*.2;
    x = x + randn(size(x))*.2;
    y = x + randn(size(x))*.2;
    % phase lag y
    y = circshift(y,[0 offset ]);
    
    %     y(round(length(y)/2):end) = randn(size(y(round(length(y)/2):end)))*.2;
    Fq = 1:180;
    [convresphase_x] = SPEC_waveletdecomp_convresphase(Fq,x,srate,wave_size);
    [convresphase_y] = SPEC_waveletdecomp_convresphase(Fq,y,srate,wave_size);
    r = 1:srate*2:length(t);
    C = [];Ci= [];
    for ii = 2:length(r);
        for iF = 1:Rows(convresphase_x)
            
            [Ci(iF,ii-1)] = SPEC_imaginary_coherence(convresphase_x(iF,r(ii-1):r(ii)),convresphase_y(iF,r(ii-1):r(ii)));
            
        end
        C(:,ii-1) = mscohere(x(r(ii-1):r(ii)),y(r(ii-1):r(ii)),hanning(nfft),noverlap,Fq,srate); % Plot estimate

    end
    figure
    mscohere(x,y,hanning(nfft),noverlap,nfft,srate); % Plot estimate
  
    figure
    subplot(2,1,1)
    imagesc(Fq,[],C);colormap(jet);colorbar; title('mscohere')
    subplot(2,1,2)
    imagesc(Fq,[],Ci);colormap(jet);colorbar; title('Imag cohere')
    
    
    ix = find(Fq == tgt,1,'first');
    figure
    plot(t,x,t,y)
    yyaxis right
    
    plot(linspace(t(r(1)),t(r(end)),Cols(Ci)),Ci(ix,:))
    hold on
    plot(linspace(t(r(1)),t(r(end)),Cols(C)),C(ix,:),'k')

    ylabel('iCoh')
    
end

% The function: From Cohen
GIX = ~isnan(x + y);
x = x(GIX);
y = y(GIX);

spec1 = sum(x.*conj(x));
spec2 = sum(y.*conj(y));
specX = sum(x.*conj(y));
Ci = abs(imag(specX./sqrt(spec1.*spec2)));
