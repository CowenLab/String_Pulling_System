function [ph, cumphase,PeaksIdx,TroughsIdx] = Phase_from_filtered_signal(CR, method,upsample_multiplier)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [ph] = Phase_from_filtered_EEG(D,method)
% CUMULTAIVE PHASE NOT WORKING PERFECTLY!!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: Given a continuous signal (assumed to have no temporal gaps -
% equal sampling frequency), determine the phase at each point. This is just a single
% column of data.
%
% OUTPUT: phase for each point in D.
% cowen (2014)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    method = 'fit';
end
if nargin < 3
    upsample_multiplier = [];
end
phase_adder = 0;

if nargout ==0
    % Test it with the various types.
    types = {'hilbert' 'fit'};
    PH = [];
    for ii = 1:length(types)
        [PH(ii,:),cs] = Phase_from_filtered_signal(CR, types{ii},upsample_multiplier);
    end
    figure(122)
    clf
    subplot(4,1,1:3)
    plot(1:Cols(PH),PH(1,:)','.-',1:Cols(PH),PH(2,:),'.-',1:length(CR),standardize_range(CR,[0 2*pi]),'.-')
    legend({types{1} types{2} 'original'})
    hold on
    nanix = find(isnan(PH(1,:)));
    plot(nanix,ones(length(nanix),1),'ro')
    nanix = find(isnan(PH(2,:)));
    plot(nanix,ones(length(nanix),1)+1,'co')
    axis tight
    subplot(4,1,4)
    plot(cs)
    axis tight
    label_figure(mfilename)
    pause
    
end

if ~isempty(upsample_multiplier)
    ix_original = 1:length(CR);
    %     CR_original = CR; % note to self: resample may be faster. It does the same thing.
    ix_upsample = linspace(1, length(CR),length(CR)*upsample_multiplier);
    CR = interp1(1:length(CR), CR, ix_upsample,'spline');
end
cumphase = zeros(size(CR))*nan;

switch method
    case 'hilbert'
        hb = hilbert(CR-mean(CR)); % YOU MUST SUBTRACT THE MEAN!!! Otherwise Hilbert transforms do NOT WORK!!!
        ph = angle(hb) + pi; % CITE: This does appear to be correct - but still never hits pi. http://www.mathworks.com/matlabcentral/answers/22907-phase-angle-from-discrte-hilbert-tranform
        %         ph = atan2(imag(hb),real(hb)) % From Scholarpedia - same
        %         thing
        %         Freeman.
        %theta = atan2(imag(z),real(z)) % Should be equivalent to angle.
    case 'fit'
        % move from trough to peak to trough, rescaling data
        % This assumes that every oscillation is a true move of 360
        % degrees. Hilbert does not assume this- this represents two
        % fundamnetal assumptions regarding how the brain works.
        if any(CR<0)
            % THESE HAVE TO BE ALL POSITIVE - otherwise the subtraction will not
            % work later on in the code.
            CR = CR + abs(min(CR));
        end
        
        ph = CR*nan;
        [PeaksIdx,TroughsIdx] = Find_peaks_troughs_zeros(CR);
        PeaksIdx_orig = PeaksIdx;
        TroughsIdx_orig = TroughsIdx;
        
        %         start_ix = min([PeaksIdx(1) TroughsIdx(1)]);
        %         end_ix = max([PeaksIdx(end) TroughsIdx(end)]);
        %
        if PeaksIdx(1) <= TroughsIdx(1)
            % make a guess for the points leading up to the first peak.
            ix = PeaksIdx(1):TroughsIdx(1);
            d = CR(TroughsIdx(1))-CR(PeaksIdx(1));
            ph(ix) = pi + pi*((CR(ix)-CR(PeaksIdx(1)))/d);
             phase_adder = 2*pi;
            
            PeaksIdx = PeaksIdx(2:end);
        end
        
        
        
        for ii = 1:(length(TroughsIdx)-1)
            % Find the 'true' peaks and troughs by fitting a spline.
            % From the peak to the trough is pi. From the trough to the
            % peak is 2pi.
            % A weakness of this method is that it depends on the peak -
            % which will ALWAYS be the max value so not the true peak. A
            % better way would be to interp and get the max of the interp
            % perhaps.
            % go from trough to peak.
            ix = TroughsIdx(ii):PeaksIdx(ii);
            d = CR(PeaksIdx(ii))-CR(TroughsIdx(ii));
            ph(ix) = pi*((CR(ix)-CR(TroughsIdx(ii)))/d);
            %             phase_adder = phase_adder + pi;
            % go from peak to the trough for the second half.
            ix = PeaksIdx(ii):TroughsIdx(ii+1);
            d = CR(TroughsIdx(ii+1))-CR(PeaksIdx(ii));
            ph(ix) = pi + pi*((CR(ix)-CR(PeaksIdx(ii)))/d);
            % Create a measure of cumulative phase.
            cumphase(TroughsIdx(ii):TroughsIdx(ii+1)) = ph(TroughsIdx(ii):TroughsIdx(ii+1)) + phase_adder;
            phase_adder = phase_adder + 2*pi;
        end
        ix = TroughsIdx(end):PeaksIdx(end);
        d = CR(PeaksIdx(end))-CR(TroughsIdx(end));
        ph(ix) = pi*((CR(ix)-CR(TroughsIdx(end)))/d);
        % the start will just be the start of the original data.
        cumphase(ix) = ph(ix) + phase_adder;
        cumphase(1:TroughsIdx(1) ) = ph(1:TroughsIdx(1));
        
        phase_adder = phase_adder + pi;
        % look at the end - if there is a trough at the end - add these
        % points.
        if TroughsIdx(end) >= PeaksIdx(end)
            % make a guess for the points leading up to the first peak.
            ix = PeaksIdx(end):TroughsIdx(end);
            d = CR(TroughsIdx(end))-CR(PeaksIdx(end));
            ph(ix) = pi + pi*((CR(ix)-CR(PeaksIdx(end)))/d);
            %             cumphase(ix) = ph(ix) + phase_adder; % This is nt working
            %             now.
            phase_adder = phase_adder + pi;
        end
        % Fill in the gaps at the beginning and the end with your best
        % guess - which is just the previous or following sequence
        % before
        if PeaksIdx_orig(1) < TroughsIdx_orig(1)
            pts_before = PeaksIdx_orig(1)-1;
            if pts_before > 0
                ph(1:pts_before) = ph(PeaksIdx(2)-pts_before:PeaksIdx(2)-1);
            end
        else
            pts_before = TroughsIdx_orig(1)-1;
            if pts_before > 0
                ph(1:pts_before) = ph(TroughsIdx(2)-pts_before:TroughsIdx(2)-1);
            end
        end
        % Fill in the points after
        if PeaksIdx(end) > TroughsIdx(end)
            last_good_point = PeaksIdx(end);
            npts = length(ph) - last_good_point;
            if npts > 0
                ph(last_good_point:length(ph)) = ph(PeaksIdx(end-1):(PeaksIdx(end-1)+npts));
            end
        else
            last_good_point = TroughsIdx_orig(end);
            npts = length(ph) - last_good_point;
            if npts > 0
                ph(last_good_point:length(ph)) = ph(TroughsIdx(end-1):(TroughsIdx(end-1)+npts));
            end
        end
        % Check for errors
        if 0
            if any(isnan(ph))
                
                disp([mfilename ' found nans'])
                figure(33)
                clf
                plot(1:length(ph),ph,'.-',1:length(CR),CR,'.-')
                hold on
                nanix = find(isnan(ph));
                plot(nanix,ones(length(nanix),1),'ro')
                plot(standardize_range(cumphase,[10 40]),'r')
                pause
            end
        end
        
    otherwise
        error('improper input method')
end
%
if ~isempty(upsample_multiplier)
    ph = interp1(ix_upsample, ph, ix_original);
    cumphase = interp1(ix_upsample, cumphase, ix_original);
end


% --> This is how to norm by the sin. ph = sin(interp1(ThetaPhaseTimes(:,1),ThetaPhaseTimes(:,2), CR(:,1)));
