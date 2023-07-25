function OUT = Fit_to_spline_by_trial(D,x,trial_start_end)
% INPUT: D = 3 cols 1) time, 2)data to fit, 3) xposition
% x = desired x for fitting.
% ST_ED = Start and end for each trial.

OUT = nan(Rows(trial_start_end),length(x));
if Rows(D) < 2
    return
end

for iTrial = 1:Rows(trial_start_end)
    Dtmp = Restrict(D,trial_start_end(iTrial,:));
    Dtmp = Dtmp(~isnan(sum(Dtmp,2)),:);
    if Rows(Dtmp) < 2
        continue
    end
    Dtmp(:,3) = Dtmp(:,3) + randn(Rows(Dtmp),1)/10000;
    Dtmp = sortrows(Dtmp,3);
    [U,ia] = unique(Dtmp(:,3));
    Dtmp = Dtmp(ia,:);
    OUT(iTrial,:) = interp1(Dtmp(:,3),Dtmp(:,2),x,'linear');
end
