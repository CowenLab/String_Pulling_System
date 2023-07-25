function [ LV, LVR, INFO ] = LocalVariance( ISI, ISI_outlier_thresh, window_and_step_size )
% ASSUMES milliseconds! LVR (but not LV) will be corrupted otherwise.
% function [ LV, LVR, INFO ] = LocalVariance( ISI, ISI_outlier_thresh, window_and_step_size )
%LocalVariance - Calculate local variance of a spike train. The inputs are
%the inter-spike intervals. If you just want LV, the units do not matter.
%If you want LVR (second output), then units need to be in ms.
%
% INPUT: ISI - vector of ISIs. PREFERRABLY IN MILLISECONDS (necessary for
%              LVR)
%        ISI_outlier_thresh - optional threshold for BIG ISIs you want to
%        ignore.
%        optional - window and step size in case you want to slide this
%        over your data. The times for the window are output in INFO
%
%
% Basic LV (first output):
% - A simple calculation that works well, but may not be as sensitive as
% the newer revised version (see 2009 paper).
%
% Shinomoto S, Miyazaki Y, Tamura H, Fujita I. 2005. Regional and laminar differences in in vivo firing patterns of primate cortical neurons. J Neurophysiol 94:567–575.
% Shinomoto S, Shima K, Tanji J. 2003. Differences in Spiking Patterns among Cortical Neurons. Neural Comput 15:2823–2842.
%
% Revised LV (LVR: second output): Assumes value R = 5 ms (from paper).
% THIS Revised LVR assumes times are in msec.
%
% Shinomoto, S., Kim, H., Shimokawa, T., Matsuno, N., Funahashi, S., Shima, K., et al. (2009). Relating Neuronal Firing Patterns to Functional Differentiation of Cerebral Cortex. PLoS Comput. Biol. 5, e1000433. doi:10.1371/journal.pcbi.1000433.
% Here is another paper that may be related (need to check out).http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3473113/
%
% Cowen 2021
% Cowen version - altered from Leroy's version. Vectorized for speeed.
% Cowen Added LVR
INFO = [];
if nargin == 0
    ISI = abs(randn(100,1));
end
if nargin < 2 || isempty(ISI_outlier_thresh)
    ISI_outlier_thresh = prctile(ISI,95);
end

INFO.ISI_outlier_thresh = ISI_outlier_thresh;

if isempty(ISI)
    LV = nan; LVR = nan;
    return
end
ISI = abs(ISI); % Assumes and even requires that ISIs are positive
if nargin <= 1
    v = (ISI(1:(end-1))-ISI(2:end))./(ISI(1:(end-1))+ISI(2:end));
else
    % Get rid of looong pauses.
    ISI(ISI>ISI_outlier_thresh) = nan;
    v = (ISI(1:(end-1))-ISI(2:end))./(ISI(1:(end-1))+ISI(2:end));
    v = v(~isnan(v));
    ISI = ISI(~isnan(ISI));
end
if nargin < 3
    window_and_step_size = [];
end

if ~isempty(window_and_step_size)
    % do a sliding window
    step = window_and_step_size(2); 
    starts = 0:step:sum(ISI);
    ends = starts + window_and_step_size(1);
    LV = zeros(size(starts));
    LVR = zeros(size(starts));
    c = cumsum(ISI);
    for ii = 1:length(starts)
        IX = c >=starts(ii) & c < ends(ii);
        [LV(ii), LVR(ii)] = LocalVariance(ISI(IX));
    end
    INFO.start_and_end_times = [starts(:) ends(:)];
    return
end


if length(ISI) < 10
    % Too small to be interpretable.
%     disp('WARNING: less than 10 spikes or so')
    LV = nan; LVR = nan;
end
LV = 3*sum(v.^2)/(length(ISI)-1);

if nargout > 1
    % TODO: Compute the revised version of local variance (eq. 3 from the paper.)
    % Shinomoto, S., Kim, H., Shimokawa, T., Matsuno, N., Funahashi, S., Shima, K., et al. (2009). Relating Neuronal Firing Patterns to Functional Differentiation of Cerebral Cortex. PLoS Comput. Biol. 5, e1000433. doi:10.1371/journal.pcbi.1000433.
    
    R_ms = 5;
    
    I1 = ISI(1:(end-1));
    I2 = ISI(2:end);
    
    v1 = 1-(4*I1.*I2)./(I1 + I2).^2;
    v2 = 1+(4*R_ms)./(I1 + I2);
    %     disp('LVR needs a bit more testing - just implemented')
    % I did a little and the LV and LVR are highly
    % correlated - which is good.
    LVR = 3*sum(v1.*v2)/(length(ISI)-1);
    if any(LVR > 10)
        disp('WARNING (LocalVariance): some very large LVR values. Be sure you are passing in ISI in ms, not seconds.')
    end
end

if nargout == 0
    %% Validate some assumptions.
    % Make sure removing a regular subset of data will not corrupt this
    % measure. This relates to the FSCV scan interval that is blanked out.
    % Will this corrupt the estimate of Local Variance?
    pth = fileparts(which('LocalVariance'));
    files = dir(fullfile(pth,'Artifical_Spikes','RealHi*.mat'));
    LV = []; FR = [];
    LVR = [];
    LVx = []; FRx = [];
    cnt = 1;
    for iF = 1:length(files)
        F = load(fullfile(pth,'Artifical_Spikes',files(iF).name));
        for iS = 1:length(F.S)
            if strcmp(F.S(iS).Type_label,'PK10')
                t = Restrict(F.S(iS).t,F.epochs.Rest1);
                t_ms = t/10;
                FR(cnt) = 1000/median(diff(t_ms));
                [LV(cnt), LVR(cnt)] = LocalVariance(diff(t_ms));
                
                % Explore and test some assumptions. What changes the LV?
                % the removal of the 14.5ms interval does not change
                % anythign. That is good for DANA FSCV.
                % Removing outliers can reduce the LV score, as one might
                % expect. For example, removing ISIs > 3000ms dramatically
                % reduces the LV in HC pyr cells. Event removing ISIs >
                % 10000ms (10s) can reduce things considerably. To me,
                % eliminating such huge intervals is reasonable.
                if 0
                    % now remove a 14.5 window every 200ms.
                    
                    interval_st = t_ms(1):200:t_ms(end);
                    interval_ed = interval_st + 200-14.5;
                    t_ms2 = Restrict(t_ms,interval_st,interval_ed);
                else
                    t_ms2 = t_ms;
                end
                FRx(cnt) = 1000/median(diff(t_ms2));
                %                 LVx(cnt) = LocalVariance(diff(t_ms2),prctile(diff(t_ms2),99));
                LVx(cnt) = LocalVariance(diff(t_ms2),10000);
                cnt = cnt + 1;
            end
        end
    end
    figure
    histogram_cowen({LV LVR LVx })
    figure
    histogram_cowen({FR FRx})
    [nanmean(LV)  nanmean(LVR) nanmean(LVx)  ]
    [mean(FR)    mean(FRx)]
    
end
