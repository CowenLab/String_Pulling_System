function [ISIs_cleaned, INFO] = Spike_train_of_given_local_variance_using_optimization(start_ISIs, target_lv)
%
% INPUT:
%
% OUTPUT:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2022
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PLOT_IT = false;
if nargin == 0
    target_lv = 1.4;
    n_spikes = 100;
    % start with a randome set of n spikes.
    start_ISIs = abs(randn(n_spikes,1));
end
if target_lv == 0
    ISIs_cleaned = repmat(mean(start_ISIs),length(start_ISIs),1);
    INFO.ISIs = ISIs_cleaned;
    INFO.timestamps = [0; cumsum(ISIs_cleaned(:))];
    INFO.lv = 0;
    INFO.duration = INFO.timestamps(end) - INFO.timestamps(1);
    INFO.start_train_duration = sum(start_ISIs);
    INFO.start_ISIs = start_ISIs;
    return
end
%% start_ISIs = repmat(mean(ISIs),length(ISIs),1);
% NOTE: more optimizations need to be performed.
% have a min ISI where they can't get smaller.
% the total train duration must also be kept constant (sum ISI) so that the
% mean firing rate is also kept about the same.
start_train_duration = sum(start_ISIs); % to keep the overall duration of the train similar
start_ISIs = start_ISIs + abs(randn(size(start_ISIs)));
start_ISIs = start_ISIs - min(start_ISIs) + .001;
fun = @(x)(target_lv - LocalVariance(x))^2; % THIS WORKED WHEN I MAKE LOCALVARIANCE() DO ABS(ISIs). I was trying to trick the objective function to convert to absolute value, but this fucked things up. Do it in LocalVariance.
fun = @(x)(target_lv - LocalVariance(x))^2 + sum(x<0.005); % ??? Does not seem to break things but the mean() does not seem to do its job.
% STUFF THAT DID NOT WORK WELL>>.
% fun = @(x)abs(target_lv - LocalVariance(x)) + abs(sum(x)-start_train_duration); % this seems to fail.
% fun = @(x)abs(target_lv - LocalVariance(x) + .4*double(any(x<=0))); % Punish negative ISIs.
% fun = @(x)abs(target_lv - LocalVariance(abs(x)) + abs((sum(abs(x))-duration_before_fmin)/duration_before_fmin)); % Punish negative ISIs.
% sum(x<=0) is to punish negative ISIs. Fails
%  fun = @(x)abs(target_lv - LocalVariance(x)) ;
% fun = @(x)abs(target_lv - LocalVariance(abs(x))) ;
% fun = @(x)(target_lv - LocalVariance(abs(x)))^2 ; % maybe squaring converges faster?
% The other work-around is to reconfigure the ISIs I think so that there is
% no negative. Or, tweak the local-variance function.

max_iter = 55000;
% options = optimset('PlotFcns',@optimplotfval);
% options = optimset('OutputFcn',{@DA_outfun},'MaxIter', max_iter); % DA_outfun does the nice plot.
% options = optimset('PlotFcns',@optimplotfval, 'MaxIter', max_iter);
options = optimset('MaxIter', max_iter);
ISIs = fminsearch(fun,start_ISIs,options);
% ISIs = abs(ISIs); % because the objective function used abs() to eliminate issues with negative numbers.
INFO.lv_before = LocalVariance(ISIs);
% duration_after_fmin = sum(ISIs);
% Get rid of negative ISIs. That's just wrong.
% smallest_ISI = min(ISIs(ISIs>eps));
ISIs_cleaned = abs(ISIs);
% ISIs_cleaned(ISIs_cleaned < eps) = smallest_ISI;
% ISIs_cleaned = ISIs;
% ISIs_cleaned(ISIs_cleaned < 0) = smallest_ISI;

% LocalVariance(x)
INFO.ISIs = ISIs_cleaned;
INFO.timestamps = [0; cumsum(ISIs_cleaned(:))];
INFO.lv = LocalVariance(ISIs_cleaned);
INFO.duration = INFO.timestamps(end) - INFO.timestamps(1);
INFO.start_train_duration = start_train_duration;
INFO.start_ISIs = start_ISIs;


if PLOT_IT
    figure
    subplot(2,2,1)
    histogram(ISIs_cleaned,40)
    title(sprintf('LV: %1.2f, dur: %3.2f, st dur: %3.2f', INFO.lv, INFO.duration, INFO.start_train_duration))
    subplot(2,2,3:4)
    plot(INFO.timestamps, zeros(size(INFO.timestamps)),'+')
    title(sprintf('LV: %1.2f, dur: %3.2f', INFO.lv, INFO.duration))
end


