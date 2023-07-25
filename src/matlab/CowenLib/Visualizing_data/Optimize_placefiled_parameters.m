function [cors] = Optimize_placefiled_parameters(S,POS,TrialIntervals,param_conv);
%function [O] = Optimize_placefiled_parameters(S,POS,TrialIntervals,param_conv);
% Runs though the different smoothing parameters and measures the mean
% correlation between all trial intervals. The set of parameters with the
% highests inter-trial correlation is deemed the best set of parameters.
%NOTE: THIS DOES NOT WORK other than helping you eyball a reasonable parameter, inter-trial correlations just keep getting bigger with
%larger smoothing factors. There needs to be another approach. I think what
%it needs to do is to leave a trial out and then you optimize the smoothing
%so that you most accurately predict the location of the rat on a given
%trial. That makes more sense. Then the optimization parameter that you are
%minimizing is the difference between predicted and actual positiun.
% 
% Cowen
n_place_bins = 400;
if nargin < 4
    param_conv = 10:10:450;
end
sFreq_pos = 1000000/median(diff(POS(:,1)));
all_TC = zeros(n_place_bins, n_place_bins, Rows(TrialIntervals),'single');
%all_TC = sparse(n_place_bins, n_place_bins, Rows(TrialIntervals));
all_TCsmth = zeros(n_place_bins * n_place_bins, Rows(TrialIntervals),'single');
%all_Occ = zeros(n_place_bins, n_place_bins, Rows(TiralIntervals));
for iT = 1:Rows(TrialIntervals)
    % Let's not bother with occupancy right now.
    St = Restrict(S,TrialIntervals(iT,:)/100);
    [all_TC(:,:,iT)] = TuningCurves({St}, sFreq_pos ,tsd(POS(:,1)/100,POS(:,2)), n_place_bins, tsd(POS(:,1)/100,POS(:,3)), n_place_bins);
    iT
end
cors = zeros(length(param_conv),1);
for ii = 1:length(param_conv)
    % Calculate the TC and Occ for each interval...
    % Calculate Do the convolution for each of the parameter values and do
    % the correlation between trials.
    ha = hanning(param_conv(ii))*hanning(param_conv(ii))';
    for iT = 1:Rows(TrialIntervals)
        % Let's not bother with occupancy right now.
        %S = S/sum(S(:));
        TCtmp = conv2(double(all_TC(:,:,iT)>0),ha);
        all_TCsmth(:,iT) = TCtmp(1:n_place_bins * n_place_bins);
    end
    C = corrcoef(Z_Scores(all_TCsmth));
    ix = find(triu(ones(Rows(TrialIntervals)),1));
    cors(ii) = mean(C(ix));
    imagesc(TCtmp)
    title(num2str(cors(ii)))
    pause(0.7)
end