function ff = Fano_factor(V,fano_type)
% function ff = Fano(V)
% Compute the fano factor of an input vector n samples long.
%
% Fano factor is dangerous for the following reason... Fano_Factor is a BAD
% measure when you use it as a measure of a MEAN response – it will be terribly 
% sensitive to sample size BECAUSE with lower sample sizes, 
% the variance will be MUCH higher from repeated sampling of the mean. 
% For example, say you have some hidden process with a real mean of 5Hz. 
% You then go ahead and are allowed, each day, to take between 1 and 20 
% samples in order to estimate the mean. If you look at the variance between 
% estimates on the days when you took 1 sample, the variance will be REALLY 
% high relative to the days which you took 20 samples – as these days will
% almost invariably have a mean of 5Hz. Thus, even though the mean is the 
% same, the var will be higher and the fano will be higher.


% Cowen 
if isvector(V)
    if nargin > 1
        error('do not specify type if passing in a vector')
    end
    ff = nanvar(V)./(nanmean(V)+eps);
else
    % Assumes the user passed in a matrix where the rows are trials and the
    % cols are time or position. 
    if nargin < 2
        fano_type = 'by_col'; % Assumed that you will compute fano undependently for each column.
    end
    
    switch fano_type
        case 'by_col'
            % Do 
            ff = nanvar(V)./(nanmean(V)+eps);
        case 'by_row_and_average'
            mn = nanmean(V,2);
            ff = Fano_factor(mn);
        case 'by_col_and_average'
            mn = nanmean(V,1);
            ff = Fano_factor(mn);           
        case 'by_col_separately_and_average'
            mn = nanmean(V,1);
            va = nanvar(V,1);
            ff = nanmean(va./(mn+eps));                       
        case 'by_row_separately_and_average'
            mn = nanmean(V,2);
            va = nanvar(V,2);
            ff = nanmean(va./(mn+eps));           
    end
    
end

if nargout == 0
    %%
    % let's test fano factor against other measures of variance...
    nT = 100;
    sparsity = [.05:.1:.95];
    add_factor = 0:.1:4;
    nReps = 20;
    FF = zeros(length(sparsity),length(add_factor),nReps)*nan;
    type = 'std';
    for iReps = 1:nReps
    for iSp = 1:length(sparsity)
        for iA = 1:length(add_factor)
            v = zeros(nT,1);
            nV = ceil(sparsity(iSp)*nT)
            v(1:nV) = 1;
            %                          v = v + add_factor(iA); xlab = 'add';
            v = v * add_factor(iA); xlab = 'multiply factor';
            switch type
                case 'fano'
                    FF(iSp,iA,iReps) = nanvar(v)/nanmean(v);
                case 'std'
                    FF(iSp,iA,iReps) = nanstd(v);
                case 'entropy'
                    FF(iSp,iA,iReps) = Entropy(v,false);

            end
        end
    end
    end
    M  = mean(FF,3);
    figure
    imagesc( add_factor,sparsity,M)
    ylabel('Sparsity Portion')
    xlabel(xlab)
    title(type)
    axis xy
    colorbar
%     colorbar_label(type)
%     pubify_figure_axis
end