function [class,P_C_r,priors,P] = Bayes_discriminator(sample, training, group, priors, distribution,  group2)
% INPUT
%      sample   - the data to classify (one row per sample, one column per variable (such as cell))
%      training - the data used to form the prior distributions. (one row per sample, one column per variable (such as cell))
%      group    - the categories for each row in training. Also referred to class.
%      priors   - a vector of the prior probabilities for each category (col) in Rates. This would
%                 be .5 if there are two categories and each is sampled equally. If not specified,
%                 this is calculated by measuring class membership in the training data.
%                 An empty matrix is passed in ([]), then the priors are calculated from the training data.
%      distribution - the type of distribution that is used for the data. If nothing is
%                     specified, the normal distribution is assumed.
%                     ('normal', 'poisson','from_data'). If 'from_data' is specified, a pdf is formed from the
%                     histogram of the training data.
%      group2       - a matrix of the combinations of variables in the training data to combine for the n dimensional
%                     Gaussian posterior estimator. For instance, if group2 = [1 2; 2 3], then the
%                     it calculates the postiors P(Class|cell1,cell2) and P(class|cell2,cell3).
%
%
% OUTPUT
%      class    - Output classses. The classifiaction of the test data into the groups in 'group'
%      P_C_r    - Probability distribution of choosing each category given a particular variable (for
%                 instance, the firing rate of a particular cell)
%      priors   - a vector of the prior probabilities for each category (col) in Rates. This would
%                 be .5 if there are two categories and each is sampled equally.
%      P        - the 3D matrix by vbl, sample, and category
%
%      If nothing is specified as the output argument, then the distributions of the
%      training and test data are displayed, along with the real data.
%
%
% cowen  8/9/00
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do some superfluous error checking. (from classify.m)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

training = full(training); % Sometimes sparse matrices do wierd things.

group = group(:)';

if any(group - round(group)) | any(group < 1)
    error('The third input argument must be positive integers.');
end

[n_train_samples,n_vbls] = size(training);

if n_train_samples ~= length(group),
    error('The number of rows in the second and third input arguments must match.');
end

[n_samples,sc] = size(sample);
if sc ~= n_vbls
    error('The number of columns in the first and second input arguments must match.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Assume a normal distribution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin <= 4
    distribution = 'normal';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If priors are not specified, calculate them
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
group_ids = sort(unique(group));
n_groups = length(group_ids);

if nargin <= 3 | isempty(priors)
    %NOTE: MAKE PRIORS = 1/ncategories as default - this states that you
    %assume that the categories are represented equally in the world so that the
    %results are not biased in one direction or the other.
    priors  = ones(n_groups,1)* 1/n_groups;
    % for ii = 1:n_groups
    %   priors(ii) = sum(group==group_ids(ii))/length(group);
    % end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

priors = priors(:)';                      % Make into a horizontal vector
means  = zeros(n_groups,n_vbls);
stds   = zeros(n_groups,n_vbls);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find the parameter estimates for the distributions for the TRAINING data
% P(r|Grp,Vbl)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for gg = 1:n_groups
    grp_idx{gg} = find(group==group_ids(gg));
    % use mle estimator to get the parameters
    switch distribution
        case {'normal' 'nd_normal'}
            [means(gg,:), stds(gg,:) ] = normfit(training(grp_idx{gg},:));
        case {'poisson'}
            [means(gg,:) ] = poissfit(training(grp_idx{gg},:));
        case {'lognormal'}
            for vbl_id = 1:n_vbls
                [x] = lognfit(training(grp_idx{gg},vbl_id));
                means(gg,vbl_id) = x(1);
                stds(gg,vbl_id) = x(2);
            end
        case {'gamma'}
            % WARNING: SLOWER THAN MOST FITS
            for vbl_id = 1:n_vbls
                [x] = gamfit(training(grp_idx{gg},vbl_id));
                means(gg,vbl_id) = x(1);
                stds(gg,vbl_id) = x(2);
            end
        case {'weibull'}
            % Weibull dist is good as it can approximate a normal OR a
            % gamma-like distribution. Binned spike data seems to fall into
            % this variant category.
            % WARNING: SLOWER THAN MOST FITS
            for vbl_id = 1:n_vbls
                [x] = wblfit(training(grp_idx{gg},vbl_id));
                means(gg,vbl_id) = x(1);
                stds(gg,vbl_id) = x(2);
            end
        case {'ks_density_unbounded'}
            % WARNING: SLOWER THAN MOST FITS
            for vbl_id = 1:n_vbls
                [ksd{gg}{vbl_id}, ks_x{gg}{vbl_id}] = ksdensity(training(grp_idx{gg},vbl_id),sample(:,vbl_id));
                %ksd{gg}{vbl_id} = ksd{gg}{vbl_id}/sum(ksd{gg}{vbl_id});
            end
        case {'ks_density_positive'}
            % WARNING: SLOWER THAN MOST FITS
            for vbl_id = 1:n_vbls
                % KSdensity pisses me off - you get lots of values > 1
                % which makes not sense to me for a probability estimate. I
                % am going to get around this by dividing by the sum.
                %x = linspace(min(sample(:,vbl_id)),max(sample(:,vbl_id)),100);
                [ksd{gg}{vbl_id}, ks_x{gg}{vbl_id}] = ksdensity(training(grp_idx{gg},vbl_id),sample(:,vbl_id),'support','positive');
                %ksd{gg}{vbl_id} = ksd{gg}{vbl_id}/sum(ksd{gg}{vbl_id});
                %pause
            end
        case 'simple_histogram'
        case 'from_data'
        otherwise
            error('WRONG DISTRIBUTION')
    end
    %  means(gg,:) = mean(training(grp_idx{gg},:));
    %  stds(gg,:)  = std(training(grp_idx{gg},:));
end

% n_vbls = n_cells
P = zeros(n_vbls,n_samples,n_groups);

if strcmp('nD_normal',distribution)
    n_vbls = length(group2);
end

% The main loop: go through each variable (which may be cells or cell pairs if using a n dimensional pdf
% Then go through each group (class) and calculate the P(firing rate or spike count|a category)
for vbl_id = 1:n_vbls
    for gg = 1:n_groups
        switch lower(distribution)
            case {'normal' 'gaussian'}
                P(vbl_id,:,gg) = normpdf(sample(:,vbl_id),means(gg,vbl_id)+eps,stds(gg,vbl_id)+eps)*priors(gg);
            case 'nd_normal'
                % Multiple in multiple dimension.
                %  Go through every combination of vbls passed in group2
                % Create a separate matrix of the training data

                % calculate the covariance matrix.
                C = cov(training(:,group2(vbl_id,:)))+eps;
                % the probability the test data was govven from this data.
                warning off
                P(vbl_id,:,gg) = gauss(means(gg,group2(vbl_id,:))+eps,C,sample(:,group2(vbl_id,:))+eps)*priors(gg);
                warning on
            case 'poisson'
                if ~Is_int(sample) | ~Is_int(training)
                    % only works with integers.
                    error('Poisson distribution expects integer values as input')
                end
                P(vbl_id,:,gg) = poisspdf(sample(:,vbl_id),means(gg,vbl_id)+eps)*priors(gg);
            case 'gamma'
                if sum([[sample(:)<0];[training(:)<0]]) > 0
                    error('Gamma distribution requires positive inputs')
                end

                P(vbl_id,:,gg) = gampdf(sample(:,vbl_id),means(gg,vbl_id)+eps,stds(gg,vbl_id)+eps)*priors(gg);
            case 'lognormal'
                if sum([[sample(:)<0];[training(:)<0]]) > 0
                    error('Gamma distribution requires positive inputs')
                end

                P(vbl_id,:,gg) = lognpdf(sample(:,vbl_id),means(gg,vbl_id)+eps,stds(gg,vbl_id)+eps)*priors(gg);
            case 'weibull'
                P(vbl_id,:,gg) = wblpdf(sample(:,vbl_id),means(gg,vbl_id)+eps,stds(gg,vbl_id)+eps)*priors(gg);
            case {'ks_density_unbounded' 'ks_density_positive'}
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Create a pdf given the original data. Table lookup.
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %     z = interp1(ks_x{gg}{vbl_id},ksd{gg}{vbl_id},sample(:,vbl_id),'spline');
                ns = size(sample(:,vbl_id),1);
                z = zeros(ns,1);
                for ii = 1:ns
                    ix = find(ks_x{gg}{vbl_id} == sample(ii,vbl_id),1,'first');
                    z(ii) = ksd{gg}{vbl_id}(ix);
                    %P(vbl_id,ii,gg) = ksd{gg}{vbl_id}(ix)*priors(gg);
                end
                P(vbl_id,:,gg) = z*priors(gg);
            case 'simple_histogram'
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Create a pdf given the original data.
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                % if sum(sample(:,vbl_id)) == 0 | sum(training(:,vbl_id)) ==0
                %   P(vbl_id,:,gg) = 0;
                % else
                % Calculate the range of the histogram
                % the_range     = unique(training(grp_idx{gg},vbl_id));
                [h,the_range] = histcounts(training(grp_idx{gg},vbl_id));
                if length(h) < 4 
                    [h,the_range] = histcounts(training(grp_idx{gg},vbl_id),5);
                end
                the_range = the_range(1:end-1);
                h = h/sum(h);      % Normalize to sum to one (make a pdf) - THIS
                z = interp1(the_range, h, sample(:,vbl_id));
                P(vbl_id,:,gg) = z*priors(gg);
                % end

            case 'from_data'
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Create a pdf given the original data.
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if ~Is_int(sample) | ~Is_int(training)
                    error('Custom distribution expects integer values as input')
                end

                if sum(sample(:,vbl_id)) == 0 | sum(training(:,vbl_id)) ==0
                    P(vbl_id,:,gg) = 0;
                else
                    % Calculate the range of the histogram
                    startpt   = full(min([sample(:,vbl_id); training(:,vbl_id)]));
                    endpt     = full(max([sample(:,vbl_id); training(:,vbl_id)]));
                    %interval  = (endpt-startpt)/30;
                    %interval = min(diff(unique(training(:,vbl_id))));
                    interval = 1; % assume integer differences.
                    the_range = startpt:interval:endpt;
                    h = hist(training(grp_idx{gg},vbl_id),the_range);
                    h = h/sum(h);      % Normalize to sum to one (make a pdf)
                    % take the sample data and look it up (using interpolation) in the pdf
                    z = interp1(the_range, h, sample(:,vbl_id));
                    P(vbl_id,:,gg) = z*priors(gg);
                end
            otherwise
                error('WRONG DISTRIBUTION')
        end
    end
    if n_samples == 1
    else
        norm_factor   = sum(squeeze(P(vbl_id,:,:))')'+eps;
        P(vbl_id,:,:) = squeeze(P(vbl_id,:,:))./repmat(norm_factor,1,n_groups);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sum across variables (cells)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
P(isnan(P))= 0; % get rid of nans
P_C_r = squeeze(sum(P,1)); % remove singleon dimesions.
if n_samples == 1
    P_C_r = P_C_r';
end
% Normalize to sum to 1.
P_C_r = P_C_r./repmat(sum(P_C_r')',1,n_groups);
% Form the categories
[tmp, class] = max(P_C_r');
class = class';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the distributions if nothing is passed as output.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout == 0
    %hi1 = hist(Rates(:,1),min(Rates(:,1)):.05:max(Rates(:,1)));
    [symbols, colors] = get_symbols;
    figure
    bar(P_C_r);xlabel('class')
    %ylabel('sample');
    title('P_C_r')

    figure
    for vbl_id = 1:n_vbls
        %subplot(2,round(n_vbls/2),vbl_id)
        if sum(sample(:,vbl_id)) == 0 | sum(training(:,vbl_id)) ==0
        else
            startpt   = min([sample(:,vbl_id); training(:,vbl_id)]);
            endpt     = max([sample(:,vbl_id); training(:,vbl_id)]);
            interval  = (endpt-startpt)/30;
            %interval  = 1;
            interval = min(diff(unique(training(:,vbl_id))));

            the_range = startpt:interval:endpt;
            % make sure the training data is not all zeros (that will screw things up and
            % make the endpt 0.
            if endpt-startpt > 0
                for gg = 1:n_groups
                    his = hist(training(grp_idx{gg},vbl_id),the_range);
                    his = his/sum(his);      % Normalize to sum to one (make a pdf)
                    h1 = plot(the_range,his,'p-');
                    set(h1,'Color',colors{gg})
                    set(h1,'LineWidth',5)
                    hold on
                    h2 = plot(the_range, poisspdf(round(the_range),means(gg,vbl_id))*priors(gg),':o');
                    set(h2,'Color',colors{gg})
                    set(h2,'LineWidth',3)
                    h3 = plot(the_range, normpdf(the_range,means(gg,vbl_id),stds(gg,vbl_id))*priors(gg),'-.^');
                    set(h3,'Color',colors{gg})
                    set(h3,'LineWidth',3)
                    ylabel('%')
                end
            end
            title(['Vbl ' num2str(vbl_id) ' press spacebar'])

            pause
        end
    end
    title('The Distributions of Rates for each Category')
end
