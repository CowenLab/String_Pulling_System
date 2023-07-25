function [O] = Binary_Choice_Behavior_Stats(CHOICES, ITIs, acorr_binsize_and_dur_sec)
% INPUT: 0 and 1s and assumes that 1's are correct.
% ITIs are assumed to be in seconds. (optional)
% OUTPUT: A bunch of useful stats on behavior.
if nargin < 2
    ITIs = [];   
end
if nargin == 2
    acorr_binsize_and_dur_sec = [1 30];
end

CHOICES = CHOICES(:)';

O.PercentCorrect = nanmean(CHOICES)*100;
% Within session learning measure...
firstthird = round(length(CHOICES)/3);
lastthird = round(length(CHOICES)*(2/3));
O.PCorrByDaySubjFirstThird = nanmean(CHOICES(1:firstthird));
O.PCorrByDaySubjLastThird = nanmean(CHOICES(lastthird:end));
O.WithinSessionLearning = O.PCorrByDaySubjLastThird - O.PCorrByDaySubjFirstThird;
O.WithinSessionLearningBinomialP = binocdf(sum(CHOICES(lastthird:end)),firstthird,O.PCorrByDaySubjFirstThird);

% How often to animals make a subsequent correct choice after a single
% correct choice.
tmplate = [0 1 1];
tmp = conv(CHOICES, tmplate(end:-1:1));
ch1 = tmp(3:end-2) == 2;
tmplate = [0 1 0];
tmp = conv(CHOICES, tmplate(end:-1:1));
ch2 = tmp(3:end-2) == 1;
O.PCorrAfterCorr = sum(ch1)/(sum(ch1) + sum(ch2));
O.Prob011 = mean(ch1);
O.Prob010 = mean(ch2);
[~,O.RunsTest.p,tmp] = runstest(CHOICES);
O.RunsTest.z = tmp.z;
O.RunsTest.nruns = tmp.nruns;
% BELOW: This is the number of contiguous two-correct-in-a-row. Brian
% McElroy came up with this. What this really does is compute percent
% correct but after eliminating the one-off correct responses 010.
O.MeanNum2ContigCorrect = mean(CHOICES(2:end).*CHOICES(1:(end-1))); 
O.MeanNum3ContigCorrect = mean(CHOICES(3:end).*CHOICES(2:(end-1)).*CHOICES(1:(end-2))); 
[~,block_sizes] = Count_contiguous(CHOICES);
[~,anti_block_sizes] = Count_contiguous(~CHOICES);
% The following should really be converted to z scores from a permuted
% distribution of values.
O.MaxContiguousCorrect = nanmax(block_sizes);
O.MeanContiguousCorrect = nanmean(block_sizes);
O.MaxContiguousCorrectProportion = O.MaxContiguousCorrect/sum(CHOICES);

O.MaxContiguousIncorrect = nanmax(anti_block_sizes);
O.MeanContiguousIncorrect = nanmean(anti_block_sizes);
O.MaxContiguousIncorrectProportion = O.MaxContiguousIncorrect/sum(~CHOICES);

permMaxContiguousCorrect = zeros(100,1);
permMeanContiguousCorrect = zeros(100,1);
nT = length(CHOICES);
for ii = 1:100
    [~,block_sizes] = Count_contiguous(CHOICES(randperm(nT)));
    permMaxContiguousCorrect(ii) = max(block_sizes);
    permMeanContiguousCorrect(ii) = mean(block_sizes);
end
O.MaxContiguousCorrectCorrected = (O.MaxContiguousCorrect - nanmean(permMaxContiguousCorrect))/nanstd(permMaxContiguousCorrect);
O.MeanContiguousCorrectCorrected = (O.MeanContiguousCorrect - nanmean(permMeanContiguousCorrect))/nanstd(permMeanContiguousCorrect);

if isempty(O.MaxContiguousCorrect)
    O.MaxContiguousCorrect = 0;
    O.MeanContiguousCorrect = 0;
end
% Change points
tmp = findchangepts(double(CHOICES),'MaxNumChanges',3); % ,'MaxNumChanges',2
O.FirstChangePoint= nan;
if ~isempty(tmp)
    O.FirstChangePoint= tmp(1);
end
tmp = cusum(double(CHOICES),3);
O.FirstChangePointCuSum = nan;
if ~isempty(tmp)
    O.FirstChangePointCuSum = tmp(1);
end
O.WithinDayLearningSlope = nan;
O.WithinDayLearningStats = [];

try
    warning off
    [b,~,stats] = glmfit(1:length(CHOICES),CHOICES); % ,'binomial','link','logit'
    warning on
    P = b(end:-1:1);
    %     pf = polyfit(1:length(CHOICES),CHOICES,1); % same thing as
    %     regression.
    pvs = polyval(P,[1 length(CHOICES)]);
    O.WithinDayLearningSlope = b(2);
    O.WithinDayLearningStartIntercept = pvs(1);
    O.WithinDayLearningEndIntercept = pvs(2);
    O.WithinDayLearningStats = stats;
catch
    disp('WHOOPS')
end

O.Regress = predict_choice_history_regression(CHOICES);
% CHOICE AUTOCORR
% Compute an autocorr...
xc = xcorr(CHOICES,'coeff');
mid = round(length(xc)/2)+1;
O.ACORR_TRIALS = xc(mid:(mid+10));

%%%%%%%%%%%%%%%%%%%
if ~isempty(ITIs)
%     if length(ITIs) > 50
%         error('wtf')
%     end
    O.ITI.meanITISec =  trimmean(ITIs,10); 
    O.ITI.stdITISec =  std(ITIs); 
    O.ITI.LocalVariancePressTimes = LocalVariance(ITIs);
%     nITIs = length(ITIs);
%     
%     lv = zeros(200,1);
%     for ii = 1:200
%         % Create a distribution of ISIs with a mean and std of the same as
%         % the actual data. BUT need to only use abs as you can't have
%         % negative interavals. 
%         ran = abs(O.ITI.stdITISec * randn(1,nITIs) + O.ITI.meanITISec); 
%         lv(ii) = LocalVariance(ran);
%         %         lv(ii) = LocalVariance(ITIs(randperm(nITIs)));
%     end
%     O.ITI.LocalVariancePressTimesCorrected = (O.ITI.LocalVariancePressTimes - mean(lv))/std(lv);
    O.ITI.BurstinessSTD = (std(ITIs)/mean(ITIs) - 1)/(std(ITIs)/mean(ITIs) + 1); % also a measure of bursting - should be robust to mean rates but assumes stationarity within a series of ITIs - local variance does not. https://en.wikipedia.org/wiki/Time-varying_network
    O.ITI.ExperimentDurationSec = nansum(ITIs);
    O.ITI.CorrectRatePerMin = sum(CHOICES)/(O.ITI.ExperimentDurationSec/60);
    t_sec = cumsum(ITIs);
    acorr_binsize_msec = acorr_binsize_and_dur_sec(1)*1000;
    acorr_dur_sec = acorr_binsize_and_dur_sec(2);
    [O.ISI.ACORR, O.ISI.ACORR_x_sec] = AutoCorr(t_sec*10000,acorr_binsize_msec ,round((acorr_dur_sec*1000)/acorr_binsize_msec ));
    O.ISI.ACORR_ISIs_x_sec = O.ISI.ACORR_x_sec/1000;
    O.ISI.Histedges_sec = 0:acorr_binsize_and_dur_sec(1):acorr_binsize_and_dur_sec(2);
    O.ISI.HistISI = histcounts(t_sec,O.ISI.Histedges_sec );
    O.ISI.MeanISIPrecedingCorrect = mean(ITIs(CHOICES==1));
    O.ISI.MeanISIPrecedingIncorrect = mean(ITIs(CHOICES==0));
end
