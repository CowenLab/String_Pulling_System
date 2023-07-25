function [rmatch,rmatch_ideal,INFO] = SPEC_time_to_recover_signal(LFP, LFP_sFreq, LFP_target, fqs,step_size_samples,method, PLOT_IT)
% Given a target LFP signal, determine how quickly you can recover a 'pure'
% signal (e.g., a sine wave of a specific frequency) in the LFP_target
% input. Compare this relative to a pure sine wave of that frequency.
%
%
% develop template.
if nargin < 6
    method = 'wavelet';
    %     method = 'pwelch';
end
oct_res = 16;
wv_scale = 9;

if nargin ==0
    % for testing only.\
    %     fqs = unique((logspace(log10(.4),log10(3000),1650)));
    %     fqs = fqs(fqs >= 600);
    fqs = [.5:.5:250];
    LFP_sFreq = 700;
    method = 'wavelet';
    dur_sec = 1;
    tgt_Hz = 50;
    
    noise = .1;
    step_size_samples = LFP_sFreq/100;
    [LFP_target] = Artificial_LFP(LFP_sFreq, dur_sec, tgt_Hz, 0, 0 );
    [LFP] = Artificial_LFP(LFP_sFreq, dur_sec, tgt_Hz, 0, noise );
    figure
    plot(LFP_target,'b')
    hold on
    plot(LFP,'r')
    figure
    [rmatch,rmatch_ideal,INFO]= SPEC_time_to_recover_signal(LFP, LFP_sFreq, LFP_target,fqs,step_size_samples,method,true);
    title(sprintf('%d Hz',tgt_Hz))
end
if any(isnan(LFP));
    method = 'plomb';
    disp('nans. using plomb()')
end

% [~,~,~,S] = spectrogram(LFP_target,blackman(step_size_samples),step_size_samples,fqs,LFP_sFreq); % Blackman is nice-  seems to narrow the range a bit- better snr.

switch method
    case 'plomb'
        % use this ...
        [template] = plomb(LFP_target,LFP_sFreq,fqs); % treats the case where the signal is sampled uniformly, at a rate fs, but has missing samples. Specify the missing data using NaNs.
    case 'pwelch'
        [template] = pwelch(LFP_target,length(LFP),0,fqs,LFP_sFreq);
    case 'pmtm'
        [template] = pmtm(LFP_target,[],fqs,LFP_sFreq);
    case 'wavelet'
        %         [~,pow] = SPEC_waveletdecomp(fqs,LFP_target,LFP_sFreq,wv_scale);
        [pow,fqs2] = SPEC_cwt_cowen(LFP_target,LFP_sFreq,[min(fqs) max(fqs)],oct_res);
        
        midix = round(Cols(pow)/2);
        pow = abs(pow(:,midix));
        template = interp1(fqs2,pow,fqs);
        %         fqs = fqs(1:length(template));
    case 'wavelet_cohen'
        [~,pow] = SPEC_waveletdecomp(fqs,LFP_target,LFP_sFreq,wv_scale);
        midix = round(Cols(pow)/2);
        template = pow(:,midix);
end
%
steps = step_size_samples:step_size_samples:length(LFP);

M = zeros(length(steps),length(fqs));
Mideal = zeros(length(steps),length(fqs));
rmatch = NaN(length(steps),1);
rmatch_ideal = NaN(length(steps),1);
%
% fprintf('%d:',length(steps))
for ii = 1:length(steps)
    % response to LFP.
    switch method
        case 'plomb'
            M(ii,:) = plomb(LFP(1:steps(ii)),LFP_sFreq,fqs);
            Mideal(ii,:) = plomb(LFP_target(1:steps(ii)),LFP_sFreq,fqs);
        case 'pwelch'
            M(ii,:) = pwelch(LFP(1:steps(ii)),steps(ii),0,fqs,LFP_sFreq);
            
            %             M(ii,:) = pwelch(LFP(1:steps(ii)),[],[],fqs,LFP_sFreq); % FYI: This sucks
            Mideal(ii,:) = pwelch(LFP_target(1:steps(ii)),steps(ii),0,fqs,LFP_sFreq);
        case 'pmtm'
            M(ii,:) = pmtm(LFP(1:steps(ii)),[],fqs,LFP_sFreq);
            Mideal(ii,:) = pmtm(LFP_target(1:steps(ii)),[],fqs,LFP_sFreq);
        case 'wavelet'
            % very slow.
            %             [~,pow] = SPEC_waveletdecomp(fqs,LFP(1:steps(ii)),LFP_sFreq,wv_scale);
            %             [~,pow] = SPEC_waveletdecomp(fqs,LFP(1:steps(ii)),LFP_sFreq,wv_scale);
            [pow,fqs2] = SPEC_cwt_cowen(LFP(1:steps(ii)),LFP_sFreq,[min(fqs) max(fqs)],oct_res);
            % take the middle power - least affected by edges.
            midix = round(Cols(pow)/2);
            pow = abs(pow(:,midix));
            pow = interp1(fqs2,pow,fqs);
            M(ii,:) = pow;
            figure(1010)
            plot(fqs,pow,'LineWidth',5)
            pubify_figure_axis
            ylabel('pow');xlabel('Hz');
            title('Wavelet power.. Units tbd')
            set(gcf,'Position',[ 360.2                     461.8                       560                       156])
            %             [~,pow] = SPEC_waveletdecomp(fqs,LFP_target(1:steps(ii)),LFP_sFreq,wv_scale);
            %             tic
            %             [~,pow] = waveletdecomp(fqs,LFP_target(1:steps(ii)),LFP_sFreq,wv_scale);
            %             toc
            [pow,fqs2] = SPEC_cwt_cowen(LFP_target(1:steps(ii)),LFP_sFreq,[min(fqs) max(fqs)],oct_res);
            pow = abs(pow(:,midix));
            pow = interp1(fqs2,pow,fqs);
            Mideal(ii,:) = pow;
        case 'wavelet_cohen'
            
            
            [~,pow] = SPEC_waveletdecomp(fqs,LFP_target(1:steps(ii)),LFP_sFreq,wv_scale);
            midix = round(Cols(pow)/2);
            pow = pow(:,midix);
            Mideal(ii,:) = pow;
            
            
            if isempty(LFP)
                M(ii,:) = pow;
                
            else
                [~,pow] = SPEC_waveletdecomp(fqs,LFP(1:steps(ii)),LFP_sFreq,wv_scale);
                midix = round(Cols(pow)/2);
                pow = pow(:,midix);
                M(ii,:) = pow;
            end
            %
            
    end
    GIX = ~isnan(M(ii,:));
    %     if any(~GIX)
    %         disp('nans found')
    %     end
    tmp = corrcoef( M(ii,GIX),template(GIX));
    rmatch(ii) = tmp(2);
    % ideal response.
    tmp = corrcoef( Mideal(ii,GIX),template(GIX));
    rmatch_ideal(ii) = tmp(2);
    %     fprintf('%d,',ii)
end

rmatch_ideal = sgolayfilt(rmatch_ideal,3,17); % Smooth with a poly.
rmatch = sgolayfilt(rmatch,3,17); % Smooth with a poly.
% so that correlations stay reasonable.
rmatch_ideal(rmatch_ideal>1) = 1;
rmatch(rmatch>1) = 1;
rmatch_ideal(rmatch_ideal<-1) = -1;
rmatch(rmatch<-1) = -1;


x_st = step_size_samples*(1:length(rmatch))/LFP_sFreq;

ix  = find(rmatch.^2 >= .7,1,'first');
time_to_recover_s = nan;
if ~isempty(ix)
    time_to_recover_s = x_st(ix);
end
ix  = find(rmatch_ideal.^2 >= .7,1,'first');
time_to_recover_ideal_s = nan;
if ~isempty(ix)
    time_to_recover_ideal_s = x_st(ix);
end

if nargout > 2
    INFO.x_st = x_st;
    INFO.template = template;
    INFO.steps = steps;
    INFO.time_to_recover_ideal_s = time_to_recover_ideal_s;
    INFO.time_to_recover_s = time_to_recover_s;
    INFO.M = M;
    INFO.Mideal = Mideal;
end


if PLOT_IT
    clr = lines(2)
    if isempty(LFP)
        LFP = LFP_target;
    end
    x_s = (1:length(LFP))/LFP_sFreq;
    x_st = (1:length(LFP_target))/LFP_sFreq;
    
    clf
    subplot(4,1,1)
    plot(x_s,LFP,'.-b')
    hold on
    plot(x_st,LFP_target,'.-r')
    
    legend('orig','ideal')
    xlabel('s')
    title(method)
    subplot(4,1,2)
    plot(steps/LFP_sFreq,rmatch,'b',steps/LFP_sFreq,rmatch_ideal,'r')
    xlabel('s')
    legend('orig','ideal')
    ylabel('r')
    title(sprintf('Recover r^2 .7 = %1.2f s IDEAl = %1.2f ',time_to_recover_s,time_to_recover_ideal_s))
    
    yyaxis right
    v = 100*(rmatch_ideal.^2 - rmatch.^2)./rmatch_ideal.^2;
    plot(steps/LFP_sFreq,v,'c')
    ylabel('% of ideal')
    subplot(4,1,3)
    imagesc(fqs,[],[M;Mideal])
    colormap(jet)
    xlabel('Hz')
    colorbar_label('power')
    set(gca,'XTickLabel','')
    subplot(4,1,4)
    plot(fqs,M(end,:),'LineWidth',2,'Color',clr(1,:))
    figure
    hold on
    plot(fqs,template,'LineWidth',2,'Color',clr(2,:))
    
    
    %
    figure
    clr = lines(2);
    plot(fqs,M(end,:),'LineWidth',2,'Color',clr(1,:))
    figure
    hold on
    plot(fqs,template,'LineWidth',2,'Color',clr(2,:))
%     set(gca,'XScale','log')
    
    axis tight
    legend('orig','ideal')
    pubify_figure_axis
    xlabel('Hz')
    figure
    plot(1000*steps/LFP_sFreq,rmatch.^2,'Color', 'k','LineWidth',2)
    pubify_figure_axis
    xlabel('Time (ms)')
    ylabel('$$R^2$$','Interpreter','latex')
    
end
