function [outsig, outhilbert, filterweights] = SPEC_Filter_hilbert_power_phase(sig,sFreq,Fqs,filterweights)
% this is in process - perform filter hilbert transform for a bunch of
% freuqency bands.
% Each column is a frequency band.
% Cowen 2016
USE_IIR = true; % SO So much faster than FIR.

if nargin < 4
    filterweights = [];
end
if nargout ==0
    %%
    srate = 1e3;
    tgt = 135;
    nSecs = 20;
    offset = 13;
    wave_size = 35; % needs to be much bigger than 5 for this to have any reasonable frequency specificity with wavelets
    t = 0:1/srate:nSecs;
    x = chirp(t,0,20,250);
    x = sin(t*2*pi*tgt);
    x(1:srate*5) = randn(size( x(1:srate*5) ))*.2;
    x = x + randn(size(x))*.2;
    y = x + randn(size(x))*.2;
    % phase lag y
    y = circshift(y,[0 offset ]);
    %     y(round(length(y)/2):end) = randn(size(y(round(length(y)/2):end)))*.2;
    Fq = 1:180;
    [outsig, outhilbert] = SPEC_Filter_hilbert_power_phase(x,srate,Fq,filterweights);
    
    return
end
sig = double(sig(:));

if Rows(Fqs) > 1
    outsig = NaN(length(sig),Rows(Fqs));
    outhilbert = NaN(length(sig),Rows(Fqs));
    filterweightsout = cell(Rows(Fqs),1);
    for iF = 1:Rows(Fqs)
        if iscell(filterweights)
            [outsig(:,iF), outhilbert(:,iF),filterweightsout{iF}] = SPEC_Filter_hilbert_power_phase(sig,sFreq,Fqs(iF,:),filterweights{iF});
        else
            [outsig(:,iF), outhilbert(:,iF),filterweightsout{iF}] = SPEC_Filter_hilbert_power_phase(sig,sFreq,Fqs(iF,:),filterweights);
        end
    end
    filterweights = filterweightsout;
    return
end

%
if Fqs(1) < 0.5
    Fqs(1) = 0.5;
    disp('Cannot have a frequency < 0.5. Converting lower bound to .5')
end

if isempty(filterweights)
    if USE_IIR
        if 0
            % for the future - determine the optimal butterworth filter order.
            Wp = [Fqs]/sFreq/2;
            Ws = [floor(Fqs(1)*.2) floor(Fqs(2)*1.2)]/sFreq/2;
            Rp = 3;
            Rs = 40;
            [filter_order,Wn] = buttord(Wp,Ws,Rp,Rs)
        end
        filter_order = 12;
        filterweights = designfilt('bandpassiir','FilterOrder',filter_order, ...
            'HalfPowerFrequency1',Fqs(1),'HalfPowerFrequency2',Fqs(2), ...
            'SampleRate',sFreq,'DesignMethod' ,'butter');
        %         fvtool(designfilt('bandpassiir','FilterOrder',filter_order, ...
        %             'HalfPowerFrequency1',120,'HalfPowerFrequency2',150, ...
        %             'SampleRate',sFreq,'DesignMethod' ,'butter'))
        
        
        
    else
        % Growing to hate FIR filters.
        nCycles = 3;
        m = -80;
        nyquist = sFreq/2;
        filter_order = m.*ceil(Fqs(1)) + nCycles*sFreq;
        %     filter_order = sFreq * nCycles; % a high order but really could not go lower - response terrible at some frequencies for low values.
        %     pts_for_1cycle = sFreq/ceil(Fqs(1));
        %     pts_for_ncycles = pts_for_1cycle*nCycles
        %     filter_order = round(nCycles*(sFreq/Fqs(1)))+1000;
        %     plot(1:150,sFreq*nCycles*(1-(1:150)/sFreq))
        % m = -20;
        % x = 1:150;
        % b = nCycles*sFreq;
        % plot(x,m.*x + b)
        %     filter_order = m*Fqs(1) + b;
        filter_order = max([sFreq*.6 ,filter_order, round(nCycles*(sFreq/ceil(Fqs(1))))]); %prevent from getting too small
        % we need to figure out a better function for this.
        filterweights = fir1(filter_order,Fqs/nyquist);
    end
end


outsig = filtfilt(filterweights,sig);

if nargout > 1
    outhilbert = hilbert(outsig);
end

if nargout == 0
    figure
    plot(sig,'k')
    hold on
    plot(outsig,'b')
    plot(abs(outhilbert),'c') %envelope
    %     plot(envelope(sig),sFreq*Fqs(1),'r')

    yyaxis('right')
    plot(angle(outhilbert),'r')

end
return
% other
if 0
    spread = .2;
    
    v =mean(Fqs);
    if v < 5
        spread = 1 ; % only for frils
        transition_width = Fqs(1)*spread; % only for frils
        
    elseif v >=5 && v < 15
        spread = .2 ;
    else
        error('Range not figured out')
    end
    ffrequencies_fq = [ 0 (1-transition_width)*Fqs(1) Fqs(1:2) (1+transition_width)*Fqs(2)  nyquist];
    ffrequencies_fq(ffrequencies_fq < 0) = 0;
    
    % filterweights = firls(filter_order,ffrequencies_nq,idealresponse);
    bpFilt = designfilt('bandpassiir','FilterOrder',filter_order, ...
         'HalfPowerFrequency1',Fqs(1),'HalfPowerFrequency2',Fqs(2), ...
         'SampleRate',sFreq);
     fvtool(bpFilt)

     bpFilt = designfilt('bandpassfir','FilterOrder',filter_order, ...
         'CutoffFrequency1',Fqs(1) ,'CutoffFrequency2',Fqs(2) , ...
         'SampleRate',sFreq,'DesignMethod','equiripple');
     
    
    d = designfilt('lowpassfir', ...
    'PassbandFrequency',0.15,'StopbandFrequency',0.2, ...
    'PassbandRipple',1,'StopbandAttenuation',60, ...
    'DesignMethod','equiripple');
    
    filterweights= bpFilt.Coefficients;
    
    ffrequencies_nq = ffrequencies_fq/ nyquist;
    idealresponse = [ 0 0 1 1 0 0 ];
    SSE = sum( (idealresponse-filterweights).^2);
end

if 0
    % Always check your filter.
    figure
    freqz(filterweights,filter_order,0:.2:150,sFreq)
    title(num2str(Fqs))
    for iF = 1:10:140
        
        %         filter_order = round(nCycles*(sFreq/iF));
        filter_order = m.*iF + nCycles*sFreq;
        %         filter_order = round(nCycles*(sFreq/iF))+1000;
        filter_order = max([600,filter_order round(nCycles*(sFreq/ceil(iF)))])
        filterweights = fir1(filter_order,[iF-.5 iF + 5] /nyquist);
        
        figure
        freqz(filterweights,filter_order,0:.2:150,sFreq)
        title([num2str([iF-.5 iF + 5])  ' ord ' num2str(filter_order)])

    end
    
%     hfvt = fvtool(filterweights,1);
end