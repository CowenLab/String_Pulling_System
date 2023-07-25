function O = Template_match_time_warp(T,D,compression_range)
%function O = Template_match_time_warp(T,D,compression_range)
%
% INPUT: T = A template that will be slid over vector D to find the best match.
%  compression_range is the range of compression (<1) or expansion (>1) of
%  the template that will be explored. In general, make this to be less than
%  15 as the bigger the range, the longer this takes. (0.4:.2:2.4 is good).
%
%  The program automatically does a second pass at finer resolution once
%  the best guess is made.
%
%  The T will be stretched and compressed as well. The match strenth and
%  indices for each compression size will be
%
% THIS PROGRAM ASSUMES THERE IS ONLY ONE MATCH BETWEEN T AND D!
%
% This program works really well if I may say so myself. It could be
%  optimized a lot though.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 0;
    embed_pt = 1000;

    % Generate fake data for testing.
    Torig = cumsum(randn(100,1)); % this is what goes into the data series D
    D = cumsum(randn(10000,1));
    Torig = Torig - (Torig(1) - D(embed_pt)); % So it's at roughly the same DC level as the rest of the data.
    % BUT compress T by a factor of .5.
    T = decimate(Torig,2); % A smaller version that will have to be scaled up by a factor of 2 to find a match.
    % Embed this pattern into D
    D(embed_pt:(embed_pt + length(Torig)-1)) = Torig;
    %
    % Ensure that T upsampled looks like the original.
    Tup = resample(T,2,1);
    if 1
        figure(1)
        clf
        subplot(3,1,1)
        plot(Torig)
        hold on 
        plot(Tup,'r')
        legend('original','resampled')
        subplot(3,1,2)
        plot(T)
        subplot(3,1,3)
        plot(D);
        hold on
        plot(embed_pt:(embed_pt + length(Torig)-1),D(embed_pt:(embed_pt + length(Torig)-1)),'r')
    end
end
%
if nargin < 3
    compression_range = 0.4:.2:2.4;
end
step_amount = median(diff(compression_range));

T = T(:);
D = D(:);
%%
base = 100;

template_resample_factors = round(base*(compression_range));

r = zeros(length(D),length(template_resample_factors));
size_Tr = zeros(length(template_resample_factors),1);

for iWarp = 1:length(template_resample_factors)
    Tr = resample(T,template_resample_factors(iWarp),base);
    % resampling can screw up the edges so replace the edges with known
    % values.
    Tr(1:2) = T(1:2); Tr(end-1:end) = T(end-1:end);
    size_Tr(iWarp) = length(Tr);
    lenTr = length(Tr);
    for jj = 1:(length(D)-(length(Tr)+1));
        tmp =  corrcoef(D(jj:(jj+lenTr-1)),Tr);
        r(jj,iWarp) =tmp(2);
    end
    fprintf('%d,',iWarp)
end
%% Find the best match. Now fine-tune the shifting.
[best_rs_for_each_shift time_of_best_match] = max(r);
[best_shift_r best_shift_warp_ix]  = max(max(r));
best_global_resample_params = [template_resample_factors(best_shift_warp_ix) base];

new_step_amount = step_amount/10;

if best_shift_warp_ix > 1 && best_shift_warp_ix < length(template_resample_factors)
    new_template_resample_factors =  round(linspace(template_resample_factors(best_shift_warp_ix-1) + ...
        new_step_amount, template_resample_factors(best_shift_warp_ix+1) - new_step_amount,10));
elseif best_shift_warp_ix ==1
    new_template_resample_factors =  round(linspace(template_resample_factors(best_shift_warp_ix) - 3*step_amount, template_resample_factors(best_shift_warp_ix+1) - new_step_amount,10));
elseif best_shift_warp_ix == length(template_resample_factors)
    new_template_resample_factors =  round(linspace(template_resample_factors(best_shift_warp_ix-1) + ...
        new_step_amount, template_resample_factors(best_shift_warp_ix) + 3*step_amount,10));
end

% Ensure that the previous best match is included in this list...
new_template_resample_factors = unique([new_template_resample_factors best_global_resample_params]);


r = zeros(length(D),length(new_template_resample_factors));
size_Tr = zeros(length(new_template_resample_factors),1);
templates = cell(length(new_template_resample_factors),1);
for iWarp = 1:length(new_template_resample_factors)
    Tr = resample(T,new_template_resample_factors(iWarp),base);
    Tr(1:2) = T(1:2); Tr(end-1:end) = T(end-1:end);
    templates{iWarp} = Tr;
    size_Tr(iWarp) = length(Tr);
    lenTr = length(Tr);
    for jj = 1:(length(D)-(length(Tr)+1));
        tmp =  corrcoef(D(jj:(jj+lenTr-1)),Tr);
        r(jj,iWarp) =tmp(2);
    end
    fprintf('n %d,',iWarp)

end
[new_best_rs_for_each_shift new_time_of_best_matches] = max(r);
[new_best_shift_r new_best_shift_warp_ix]  = max(max(r));
new_time_of_best_match = new_time_of_best_matches(new_best_shift_warp_ix);

new_best_global_resample_params = [new_template_resample_factors(new_best_shift_warp_ix) base];

O.template_compression_ratio = new_best_global_resample_params(1)/new_best_global_resample_params(2);
O.index_of_best_match = new_time_of_best_match;
O.matching_template = templates{new_best_shift_warp_ix};
O.template_compression_parameters = new_best_global_resample_params;
O.correlations_of_best_match = r(:,new_best_shift_warp_ix);

if nargout == 0
    figure   
%     subplot(4,1,1:2)
%     imagesc(size_Tr/length(T),[],r)
    subplot(3,1,1)
    plot(O.correlations_of_best_match )
    subplot(3,1,2)
    plot(O.matching_template )
    subplot(3,1,3)
    plot(D);
    hold on
    plot(O.index_of_best_match:(O.index_of_best_match + length(O.matching_template)-1),D(O.index_of_best_match:(O.index_of_best_match + length(O.matching_template)-1)),'r')
    plot(O.index_of_best_match:(O.index_of_best_match + length(O.matching_template)-1),O.matching_template,'k')
end
