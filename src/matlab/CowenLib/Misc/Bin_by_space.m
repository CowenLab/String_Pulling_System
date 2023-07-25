function OUT = Bin_by_space(D,space_bin_edges,trial_start_end)
% D must have 3 columns: time, value of interest, spatial location.
% 
%Average of the vals second column of D for each space bin in space_bin_edges.
% The first col of D is time. third is space. 
% trail_start_end indicates trial times.
% Cowen 2019
OUT = nan(Rows(trial_start_end),length(space_bin_edges)-1);
for iTrial = 1:Rows(trial_start_end)
    Dtmp = Restrict(D,trial_start_end(iTrial,:));
    for ii = 1:length(space_bin_edges)-1
        IX = Dtmp(:,3) >= space_bin_edges(ii) & Dtmp(:,3) < space_bin_edges(ii+1);
        OUT(iTrial,ii) = nanmean(Dtmp(IX,2));
    end
end
