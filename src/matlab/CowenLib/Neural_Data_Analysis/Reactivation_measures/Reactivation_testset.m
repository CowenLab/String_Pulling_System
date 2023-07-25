function OUT = Reactivation_testset(RCT, nReps)
%function OUT = Reactivation_testset(RCT.proportion_of_reactivated_sequences, jitter_ms, compression_ratio, nReps)
% Given some realistic data, create timestmaps for ripple events during
% behavior and pre/post behavior sleep. Snippets of behavior
% time slices will be inserted into patterns in post-behavior sleep accordiing
% to the proportions and jitter specified in the inputs.
%
% OUTPUT: Timestamps for spikes during each behavioral period.
% Use: The best measure of reactivation would be the measure that most
% accurately correlates with RCT.proportion_of_reactivated_sequences and
% inversly scales with the jitter.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Assumtions, etc...
%   reactivation will only occur during ripple events.
%   reactivation will be for brief sections of behavior.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 1 || isempty(RCT.RCT)
    RCT.proportion_of_reactivated_sequences = 0.5; % how much of the 'offline' data be actually reactivated - rest is random.
    RCT.jitter_ms = 0;
    RCT.compression_ratio = 7/1;
    t = [.4 .6 .8 1 1.2 1.4 1.5];
    p = [30 20 15 10 10 8 5];
    p = p/sum(p);
    RCT.dist_of_snippet_length_s = [p;t]; % distribution of the amount of snippets at each length.
    RCT.dist_of_ensemble_size = [.6 .4 .2; 2 4 6]; % The size of the ensembles - number of neurons in an ensemble.
    RCT.n_unique_ensembles = 10; % number of unique ensembles to embed.
    RCT.n_neurons = []; % if empty, then this is determined by the dataset that is loaded.
    RCT.data_set_type = 'load_from_disk'; % alternative: 'construct_artificial_set'
    RCT.random_number_seed = 123;
    % A random number generator will pick out snippets from this list
end
if nargin < 2 || isempty(nReps)
    nReps = 15;
end

rng(RCT.random_number_seed); % Let's use a consistent seed for replication's sake
% Load the data that will be used to create the reactivated sequences.
switch RCT.data_set_type
    case 'load_from_disk'
        %% Load a dataset.
        p = fileparts(which('Reactivation_testset'));
        % this just has some ripple times, pre-sleep, and behavior activaion.
        load(fullfile(p,'Reactivation_testset_input'),'SPKS','SPD','RIP')
        if isempty(RCT.n_neurons)
            RCT.n_neurons = length(SPKS.PRE_USEC);
        end
    otherwise
        error('wrong data set type passed');
end
%
if 0
    % Dummy code that created the original sample set from some old data.
    % Need to recerence this data.
    SPKS = [];
    for ii = 1:length(IN.SPKS.PRE)
        SPKS.PRE_USEC{ii} = IN.SPKS.PRE{ii} *100;
        SPKS.BEHAVIOR_USEC{ii} = IN.SPKS.BEHAVIOR{ii} *100;
    end
    RIP = [];
    RIP.PRE_USEC = IN.RIP.PRE;
    SPD = [];
    SPD.BEHAVIOR_USEC_PIX = [IN.SPD.BEHAVIOR(:,1) IN.SPD.BEHAVIOR(:,2)];
    save('Reactivation_testset_input','SPKS','SPD','RIP')
end

%% modify this dataset and create a post-behavior dataset that has
% reactivation embedded within it along with parts from the original
% dataset.
rip_durations_usec = (RIP.PRE_USEC(:,2) - RIP.PRE_USEC(:,1));
post_start_usec = SPD.BEHAVIOR_USEC_PIX(end,1) + 20e6;
for ii = 1:length(SPKS.PRE_USEC)
    SPKS.POST_USEC{ii} = SPKS.PRE_USEC{ii} + post_start_usec;
end
RIP.POST_USEC = RIP.PRE_USEC + post_start_usec;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get snippets from behavior. If the average ripple duration is 70 ms, then
% the average snippet lenght will be 70*compression_ratio
% Grab a bunch so that we can select values that are above a
% behavior intervals.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Behavior_start_usec    = Find_start( SPKS.BEHAVIOR_USEC);
Behavior_end_usec      = Find_end( SPKS.BEHAVIOR_USEC);
Behavior_duration_usec = Behavior_end_usec - Behavior_start_usec;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% intervals_usec = Behavior_start_usec:70*compression_ratio*1000:Behavior_end_usec;
% For each ripple during pre, grab a random snippet from behavior - given
%% the compression ratio.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
behav_snip_durations_usec = rip_durations_usec*RCT.compression_ratio;
% Do a bunch of reps.

for iRep = 1:nReps
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    start_times_usec          = Behavior_start_usec + sort(rand(Rows(RIP.PRE_USEC),1)*(Behavior_duration_usec-10e6));
    end_times_usec            = behav_snip_durations_usec + start_times_usec;
    snp                       = cell(Rows(RIP.PRE_USEC),1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for iR = 1:Rows(RIP.PRE_USEC)
        snp{iR} = Restrict(SPKS.BEHAVIOR_USEC, start_times_usec(iR), end_times_usec(iR));
    end
    nSpksPerRip = zeros(length(snp{1}), length(snp));
    for iR =1:length(snp)
        for iCell = 1:length(snp{iR})
            if ~isempty(snp{iR}{iCell})
                nSpksPerRip(iCell,iR) = length(snp{iR}{iCell});
            end
        end
    end
    nCellsWithSpikesPerRip = nSpksPerRip;
    nCellsWithSpikesPerRip(nCellsWithSpikesPerRip>0) = 1;
    %     sum(nCellsWithSpikesPerRip);
    SPKS.REP_POST_USEC{iRep} = SPKS.POST_USEC;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Insert these snippets into a proprtion of ripples
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    target_ripples_ix = randperm(Rows(RIP.POST_USEC));
    target_ripples_ix = sort(target_ripples_ix(1:round(RCT.proportion_of_reactivated_sequences*Rows(RIP.POST_USEC))));
    
    for iR = 1:length(target_ripples_ix)
        S = snp{target_ripples_ix(iR)};
        st_ed = RIP.POST_USEC(target_ripples_ix(iR),:);
        % Delete the current spikes in this ripple
        for iCell = 1:length(snp{iR})
            ix = find(SPKS.REP_POST_USEC{iRep}{iCell} > st_ed(1) & SPKS.REP_POST_USEC{iRep}{iCell} < st_ed(2) );
            if ~isempty(ix)
                SPKS.REP_POST_USEC{iRep}{iCell}(ix) = [];
            end
        end
        % Insert the spikes from behavior - allowing for compression and
        % jitter.
        newS = S;
        for iCell = 1:length(S)
            if ~isempty(S{iCell})
                S{iCell} = S{iCell} - start_times_usec(iR);
                d = diff([0 ; S{iCell}]);
                d = d/RCT.compression_ratio; % compress this thing in time.
                if RCT.jitter_ms > 0
                    d = d + randn(size(d))*RCT.jitter_ms*1000;
                end
                newS{iCell} = cumsum(d);
                SPKS.REP_POST_USEC{iRep}{iCell} = [SPKS.REP_POST_USEC{iRep}{iCell};  st_ed(1) + newS{iCell}];
            end
        end
    end
    for iCell = 1:length(SPKS.REP_POST_USEC{iRep})
        SPKS.REP_POST_USEC{iRep}{iCell} = round(sort(SPKS.REP_POST_USEC{iRep}{iCell} ));
    end
    fprintf('.')
end
fprintf('\n')

OUT.SPKS = SPKS;
OUT.RIP = RIP;
OUT.RCT = RCT;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use the EV measure to test this technique. Note the variance.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout == 0
    RP = [];
    meth = 'EV';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test this with EV reactivation.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    STM_rest_binsize_msec = 20;
    rip_bins = Bin_start_ends_within_intervals(OUT.RIP.PRE_USEC, STM_rest_binsize_msec*1000);
    [STM.Ripples.PRE.M, STM.Ripples.PRE.ts] = Bin_ts_array(OUT.SPKS.PRE_USEC, rip_bins);
    [STM.BEHAVIOR.M, STM.BEHAVIOR.ts] = Bin_ts_array(OUT.SPKS.BEHAVIOR_USEC, STM_rest_binsize_msec*1000);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    R = zeros(length(OUT.SPKS.REP_POST_USEC),3)*nan;
    
    for iRep = 1:length(OUT.SPKS.REP_POST_USEC)
        rip_bins = Bin_start_ends_within_intervals(OUT.RIP.POST_USEC, STM_rest_binsize_msec*1000);
        [STM.Ripples.POST.M, STM.Ripples.POST.ts] = Bin_ts_array(OUT.SPKS.REP_POST_USEC{iRep}, rip_bins);
        %
        switch meth
            case 'EV'
                [RP(iRep).React, RP(iRep).FR, RP(iRep).Pval] = Reactivation_EV({STM.Ripples.PRE.M STM.BEHAVIOR.M STM.Ripples.POST.M}, ...
                    [STM_rest_binsize_msec STM_rest_binsize_msec*OUT.RCT.compression_ratio STM_rest_binsize_msec],{'only_significant'});
                %         [RP(iRep).React, RP(iRep).FR, RP(iRep).Pval] = Reactivation_EV({STM.Ripples.PRE.M STM.BEHAVIOR.M STM.Ripples.POST.M}, ...
                %             [STM_rest_binsize_msec STM_rest_binsize_msec*OUT.compression_ratio STM_rest_binsize_msec]);
                %         [RP(iRep).React] = Reactivation_PCA({STM.Ripples.PRE.M STM.BEHAVIOR.M STM.Ripples.POST.M}, ...
                %             [STM_rest_binsize_msec STM_rest_binsize_msec*OUT.compression_ratio STM_rest_binsize_msec]);
                R(iRep,1) = RP(iRep).React.AllR.rAB;
                R(iRep,2) = RP(iRep).React.AllR.rBC;
                R(iRep,3) = RP(iRep).React.reactivation_strength;
            case 'Bias'
                [tmp] = Reactivation_Bias({OUT.SPKS.PRE_USEC OUT.SPKS.BEHAVIOR_USEC OUT.SPKS.REP_POST_USEC{iRep}}, STM.BEHAVIOR.M, STM_rest_binsize_msec*OUT.RCT.compression_ratio, 'usec');
                %         R(iRep,1) = tmp.ReactBias.rAB;
                %         R(iRep,2) = tmp.ReactBias.rBC;
                %         R(iRep,3) = tmp.ReactBias.rBC - tmp.ReactBias.rAB;
                R(iRep,1) = tmp.ReactCOM.rAB;
                R(iRep,2) = tmp.ReactCOM.rBC;
                R(iRep,3) = tmp.ReactCOM.rBC - tmp.ReactCOM.rAB;
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure
    clf
    subplot(2,4,1:3)
    bar(R)
    legend('PRE','POST','STR')
    ylabel('r');xlabel('Simulation #')
    s = sprintf('%s Prop: %2.2f Jit: %2.2fms Comp: %2.2f binsz: %d ms',meth, OUT.RCT.proportion_of_reactivated_sequences,OUT.RCT.jitter_ms,OUT.RCT.compression_ratio,STM_rest_binsize_msec);
    title(s)
    axis tight
    subplot(2,4,4)
    errorb(mean(R),Sem(R))
    axis tight
    set(gca,'XTickLabel',{'Pre' 'Post'  'Str'})
    subplot(2,4,5:6)
    imagesc(STM.Ripples.PRE.M')
    title('Pre - rips only')
    subplot(2,4,7:8)
    imagesc(STM.BEHAVIOR.M')
    title('Behavior')
end

%%
if 0
    snp = cell(length(intervals_usec)-1,1);
    for ii = 1:length(intervals_usec)-1
        snp{ii} = Restrict(SPKS.BEHAVIOR_USEC,intervals_usec(ii), intervals_usec(ii+1));
    end
    V = zeros(length(snp{1}), length(snp));
    for iT =1:length(snp)
        for iCell = 1:length(snp{iT})
            if ~isempty(snp{iT}{iCell})
                V(iCell,iT) = length(snp{iT}{iCell});
            end
        end
    end
end