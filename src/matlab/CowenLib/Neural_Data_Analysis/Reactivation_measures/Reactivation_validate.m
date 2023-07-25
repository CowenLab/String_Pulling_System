%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reactivation_validate - validate the reactivation measure.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Validation will be measured in a number of ways.
%
% For all measures: 
%
% 1) Correlation of the output of the reactivation measure with changes in
%    the known reactivation strength of many iterations of the artificial
%    dataset. 
% 2) Effect size difference between Mean (mangnitude) and Std (reliability)
%    using Cohen's D of the measure produced by the reactivation measure on
%    datasets with reactivation vs. datasets without reactivation.
%
% For ensemble-identification-based measures: (e.g., template matching)
% 0) the measures above will also be applied.
% Classification performance: 
% 1) portion of correctly-identified reactivation ensembles
% 2) the true positive rate.
% 3) the false positive rate.
%
%

reactivation_methods = {'Reactivation_EV' 'Reactivation_Bias' 'Reactivation_OReillyCoincidence'};
binsize_ms = 20; % for the EV measure
sets_to_load = 1:10;
p = fileparts(which(mfilename));
validation_root = 'from_real_';
data_set_dir = fullfile(p,'Validation_datasets');


for iDataSet = 1:length(sets_to_load)
    fname = [validation_root num2str(sets_to_load(iDataSet))];
    load(fullfile(data_set_dir,fname)); % Load the dataset.
    for iMethod = 1:length(reactivation_methods)
        switch reactivation_methods{iMethod}
            case 'Reactivation_EV'
                rip_bins = Bin_start_ends_within_intervals(OUT.RIP.POST_USEC, STM_rest_binsize_msec*1000);
                [STM.Ripples.POST.M, STM.Ripples.POST.ts] = Bin_ts_array(OUT.SPKS.REP_POST_USEC{iRep}, rip_bins);
                %
                [RP(iRep).React, RP(iRep).FR, RP(iRep).Pval] = Reactivation_EV({STM.Ripples.PRE.M STM.BEHAVIOR.M STM.Ripples.POST.M}, ...
                    
            case 'Reactivation_Bias'
        end
    end
end