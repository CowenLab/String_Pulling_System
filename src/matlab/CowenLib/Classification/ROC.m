function [TP_rate,FP_rate,STATS,TP_rate_rand,FP_rate_rand] = ROC(data, group, option, option_parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [class, ROC, area_under_curve]= ar_discriminant_and_ROC(data, group, option, option_parameters)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: data = nsamples by ndimensions; group, a vector of group membership IDs.
% 
%        option = 'plot' plot summary performance comparing L1O results with the randomly mixed version 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% to test, do the following...
%[class, ROC, area_under_curve] = ar_discriminant_and_ROC([], [], {'use_testdata'},{[]})
%AUC of a classifier is equivalent to the probability that the classifier will rank
%a randomly chosen positive instance higher than a randomly chosen
%negative instance. This is equivalent to the Wilcoxon test of ranks
%(Hanley and McNeil, 1982). The Wilcoxon rank sum test is equivalent to the Mann-Whitney U test
% A problem with the Wilcoxon method is that you can get a low p value if
% the ROC curve is way above OR way BELOW the diagonal. As a result, you
% don't know if performance is above or below chance. In this respect, AOC
% is nicer.
%
%  The type and prior parameters are only applicable if you are using matlab 6.5 or above.
% 
% NOTE: MAY WANT TO SEE ROC_Cawley05 - should we use convex hull or not?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen(2004)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3
    option = [];
end
wtLD = [];


if ismember('cross_validate',option)
    % Create a new dataset by running the LD on all but one sample, then transform that sample and 
    % add it to the new set. Then run the analysis. 
    if ismember('use_testdata',option)
        % Test with test data. User can just pass in empty strings or whatever for the other parameters
        nSamples = 60;
        data = randn(nSamples,10);
        group = ones(nSamples,1);
        idx = round(nSamples/2);
        group(idx:end) = 0;
        data(idx:end,4)   = randn(length(data(idx:end,4)),1)-0.9;
        data(1:(idx-1),3:5) = randn(length(data(1:idx-1,3)),3)+.57;
    end
    
    
    nVariables = Cols(data);
    nSamples = Rows(data);
    wtLD = zeros(size(data))*nan;
    if nVariables ==1
        disp('Only ONE variable (dimension) specified. No point in doing a LD.')
        new_data = data;
    else
        disp('Performing linear discriminant transformation on the multidimensional input data.')
        new_data = zeros(nSamples,1);
        for ii = 1:nSamples
            idx = setdiff(1:nSamples,ii);
            [LD, wtLD(ii,:)] = Linear_discriminant(data(idx,:),group(idx));
            new_data(ii) = wtLD(ii,:)*data(ii,:)';
        end
    end
    
    op = [];
    if ismember('plot',option)
        op = {'plot'};
        figure;subplot(3,1,1);imagesc(wtLD);
        title('Weights from the LD and Leave-One-Out analysis')
        subplot(3,1,2);error_bars(wtLD);
        xlabel('column in original data')
        axis tight
        subplot(3,1,3);imagesc(data);
    end
    [TP_rate,FP_rate,STATS,TP_rate_rand,FP_rate_rand] = ROC(new_data,group,op);
    STATS.wtLD = wtLD;
    %pause
else
    group_ids = unique(group);
    nSamples = Rows(data);
    nGroups = length(group_ids); % Can only be 2
    
    rand_group = group(randperm(length(group)));
    if Cols(data) > 1
        [D, Linear_discriminant_wt] = Linear_discriminant(data,group);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % NOTE: If you resort the rand_group, you will likely see an effect
        % as LD will overfit the data. Be careful and cross-validate.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [rand_D, randLinear_discriminant_wt] = Linear_discriminant(data,rand_group);
        [s,idx ]= sort(rand_group);
        disp('DANGER DANGER: Make sure you cross-validate if you do this. LD will overfit.')
        figure;
        plot(D(idx))
        hold on
        plot(rand_D(idx),'r')
        %disp('Performed linear discriminant transformation on the multidimensional input data.')
       % error('Transform your data into a single dimension')
    else
        D = data;
        rand_D = data; % we already random permuted the order of groups so rand_d can be the same as data
        %Linear_discriminant_wt = zeros(1,Cols(D));
        %randLinear_discriminant_wt = zeros(1,Cols(D));
    end
    if nGroups ~= 2
        error('Must only have 2 groups')
    end
    group1_idx = find(group == group_ids(1));
    group2_idx = find(group == group_ids(2));
    
    rand_group1_idx = find(rand_group == group_ids(1));
    rand_group2_idx = find(rand_group == group_ids(2));
    
    % LINEAR DISCRIMINANT TRANSFORMATION.
    % NOTE: doing LD on even random groups WILL lead to
    % above chance classification: REALLY! It may be OK if you compare
    % it to randomly categorized data. 
    %[LD, Linear_discriminant_wt] = Linear_discriminant(data(idx,:),group(idx))
    %LD = data;
    rng = linspace(min(D),max(D),100);
    [h1,r] = hist(D(group1_idx),rng);
    [h2,r] = hist(D(group2_idx),rng);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Do the ROC analysis
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    TP = zeros(length(rng),1);
    FP = zeros(length(rng),1);
    TPrand = zeros(length(rng),1);
    FPrand = zeros(length(rng),1);
    for ii = 1:length(rng)
        thresh = rng(ii);
        TP(ii) = sum(D(group1_idx) > thresh);
        FP(ii) = sum(D(group2_idx) > thresh);
        TPrand(ii) = sum(rand_D(rand_group1_idx) > thresh);
        FPrand(ii) = sum(rand_D(rand_group2_idx) > thresh);
    end
    
    TP_rate = TP/length(group1_idx);
    FP_rate = FP/length(group2_idx);
    TP_rate_rand = TPrand/length(group1_idx);
    FP_rate_rand = FPrand/length(group2_idx);
    
    % Find the area under the curve. Just add in the lower right corner and
    % subtract from the half diagonal.
    % following from http://theoval.sys.uea.ac.uk/matlab/roc/auroc.m but I
    % get a VERY different and apparently WRONG result with this code.
    %[s,ix] = sort(TP_rate);
    %TP_rate = TP_rate(ix);
    %FP_rate = FP_rate(ix);
    %%n = length(TP_rate);
    %A = sum((FP_rate(2:n) - FP_rate(1:n-1)).*(TP_rate(2:n)+TP_rate(1:n-1)))/2;


    STATS.area_under_curve = polyarea([0; FP_rate(:); 1],[0; TP_rate(:); 1]); %- polyarea([0 max(FP_rate) max(FP_rate)],[0 max(TP_rate) min(TP_rate)]);
    STATS.rand_area_under_curve = polyarea([FP_rate_rand(:); 1],[TP_rate_rand(:); 0]);% - polyarea([0 max(FP_rate_rand) max(FP_rate_rand)],[0 max(TP_rate_rand) min(TP_rate_rand)]);
    % Do some traditional statistics for comparisons.
    warning off
    [STATS.P_wilcoxon H_wilcoxon] = ranksum(D(group1_idx),D(group2_idx));
    [H, STATS.P_ttest] = ttest2(D(group1_idx),D(group2_idx));
    [H, STATS.P_kstest] = kstest2(D(group1_idx),D(group2_idx));
    [STATS.rand_P_wilcoxon H_wilcoxon] = ranksum(rand_D(rand_group1_idx),rand_D(rand_group2_idx));
    warning on
    for ii = 1:length(option)
        switch option{ii}
            case 'plot'
                figure
                subplot(2,2,1:2)
                plot(r,h1/sum(h1),r,h2/sum(h2))
                legend('1','2',0)
                title('Distribution')
                ylabel('p')
                xlabel('Data Value')
%                subplot(2,2,2)
%                bar(group)
%                title('group')
%                axis tight
                subplot(2,2,3)
                plot(FP_rate,TP_rate,'.-')
                hold on
                plot(FP_rate_rand,TP_rate_rand,'k')
                %h = text(FP_rate,TP_rate,num2str(rng','%0.2f'));
                % set(h,'FontSize',6)
                axis tight
                axis square
                plot([0 1], [0 1],'r')
                ylabel('TP rate')
                xlabel('FP rate')
                title(['ROC:  AUC = ' num2str(STATS.area_under_curve,'%0.2f') ' rAUC = ' num2str(STATS.rand_area_under_curve,'%0.2f') ' Wcx= ' num2str(STATS.P_wilcoxon,'%0.2f') ' rWcx= ' num2str(STATS.rand_P_wilcoxon,'%0.2f')])
                subplot(2,2,4)
                rnd_idx1 = randperm(length(group1_idx));
                rnd_idx2 = randperm(length(group2_idx));
                plot([D(group1_idx(rnd_idx1)); D(group2_idx(rnd_idx2))],'b');
%                plot([group1_idx]
                
                hold on
                plot([rand_D(rand_group1_idx(rnd_idx1));rand_D(rand_group2_idx(rnd_idx2))],'r')
%                plot(rand_D,'r')
                axis tight;drawnow
                a = axis;
                d = diff(group);
                idx = find(d ~=0);
                start = a(1);
                colors = {'b' 'r' 'g' 'm' 'c' 'k' 'y'};
                for ii = 1:length(idx)
                    plot([start (idx(ii))],[a(3) a(3)],colors{ii},'LineWidth',4) 
                    start = idx(ii);
                end
                xlabel('Category: order shuffled within category')
                ylabel('Value')
            otherwise
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For posterity, here is another, although perhaps less valid (no
% separation between training and test set) way to cross validate. Because
% there is no separation, you need to compeare the answer with the results
% from a randomly generated and LD transformed dataset. In practice, the
% method implemented above makes more intuitive sense and appears quite
% robust.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if ismember('cross_validate1',option)
%     % Test with test data. User can just pass in empty strings or whatever for the other parameters
%     nSamples = Rows(data);
%     TP_rate = zeros(100,nSamples);
%     FP_rate = zeros(100,nSamples);
%     TP_rate_rand = zeros(100,nSamples);
%     FP_rate_rand = zeros(100,nSamples);
%     for ii = 1:nSamples
%         idx = setdiff(1:nSamples,ii);
%         %[LD, Linear_discriminant_wt] = Linear_discriminant(data(idx,:),group(idx))
%         %idx = ceil(rand(nSamples,1)*nSamples);
%         [TP_rate(:,ii),FP_rate(:,ii),area_under_curve(ii),TP_rate_rand(:,ii),FP_rate_rand(:,ii),rand_area_under_curve(ii)] = linear_discriminant_and_ROC(data(idx,:),group(idx));
%     end
%     figure
%     plot(mean(FP_rate'),mean(TP_rate'))
%     hold on
%     plot(mean(FP_rate_rand'),mean(TP_rate_rand'),'g')
% %%%%
% 
%     plot(mean(FP_rate') + std(FP_rate'),mean(TP_rate') + std(TP_rate'),'r:')
%     plot(mean(FP_rate') - std(FP_rate'),mean(TP_rate') - std(TP_rate'),'r:')
% 
%     plot(mean(FP_rate_rand') + std(FP_rate_rand'), mean(TP_rate_rand') + std(TP_rate_rand'),'c:')
%     plot(mean(FP_rate_rand') - std(FP_rate_rand'), mean(TP_rate_rand') - std(TP_rate_rand'),'c:')
% 
%     [oTP,oFP] = linear_discriminant_and_ROC(data,group);
%     plot(oFP,oTP,'k')
%     axis square
%     axis tight
%     plot([0 1], [0 1],'r')
%     ylabel('TP rate')
%     xlabel('FP rate')
%     title(['ROC:  AUC = ' num2str(mean(area_under_curve),'%0.2f') ' rAUC = ' num2str(mean(rand_area_under_curve),'%0.2f') ])
%    
% else