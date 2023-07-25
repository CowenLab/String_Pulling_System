function [g,type_labels] = neuron_subtypes(wv_features,wv_feature_labels,ALL_WV,ALL_WV_x_msec,...
    AC,AC_x_msec, plot_it, thresh)
%function [g,type_labels] = neuron_subtypes(wv_features,wv_feature_labels,ALL_WV,ALL_WV_x_msec,...
%    AC,AC_x_msec, plot_it)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start by finding 2 clusters based on the features. Should pull out the
% interneurons. Uses waveform shapes and autocorr to classify neurons into groups.
%
% INPUT:
%    wv_features: a nSample X nFeature matrix of waveform features (e.g.
%    peak height, energy...)
%
%    wv_feature_labels: a cell array of strings that describe the waveform
%    features (e.g. {'Peak' 'Energy'}) - one for each row in wv_features.
%
%    ALL_WV: The individual waveforms for each sample. nSample x waveform points (e.g. 32 points).
%
%    ALL_WV_x_msec: The time for each column in All_WV (a single vector of length (Cols(All_WV))
%
%    AC: autocorrellograms for each sample (nSample x autocorr points). I
%    often just take the 1st 100msec of the acorr and normalize all the
%    acorrs to have unit energy.
%
%    AC_x_msec: the x axis for the autocorr.
%
%    plot_it: set to 1 if you would like to plot the output
%
%    thresh: optional - you can pass in mandatory thresholds for teh
%    wv_features for classifying interneurons. You may want to do this if
%    you are unsatisfied with the way the automatic clustering (kmeans)
%    segments interneurons. For instance, kmeans won't do a good job if you
%    don't have many waveforms. If you do this, then neuron_subtypes will
%    still automatically cluster the pyramidal cells into 2 groups.
%
%
% OUTPUT:
%   g = the group - classification for each sample. (vector of nSamples)
%   type_labels = text lables for each categorized group.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cowen 2006
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 8
    thresh = [];
end

fontsize1 = 20;
fontsize2 = 22;
mkrsize = 12;
ALL_WV = standardize_range(ALL_WV')';
type_labels = {'IN' 'PK10' 'PK100'};
%g = kmeans(standardize_range(wv_features')',2);
% NOTE: normalizing the wv_features does not help, neither does using the
% entire waveform. That screws everything up. The clusters just don't
% separate well.

if isempty(thresh)
    g = kmeans(nan_to_val(wv_features),2);
else
    % Assumes that the parameter you want is the one that is non-nan.
    g = wv_features(:,1) < thresh(1) & wv_features(:,2) < thresh(2) ; g = g + 1; % THIS IS FOR DREW AND SARA'S DATA!
end

%g = clusterdata(nan_to_val(wv_features),.5); % This does not work.
%g = kmeans(nan_to_val([wv_features AC(:,1:40)]),3); % This does not work
%    either.
% Find the interneurons (the smallest group.)
hg = hist(g,1:2);
%ptw = grpstats(OF.PeakTroughWidth_uSec(:),g);
[xx,INg ]= min(hg);
g = single(g==INg);% Interneurons = 1, other = 0;
%% Cluster based on the acorr.
% subtract off the last 100 msec.
ix = find(AC_x_msec > max(AC_x_msec)-100);
norm_AC = AC - repmat(mean(AC(:,ix),2),1,Cols(AC)); titstr = 'Norm By Mean Rate';
norm_AC = standardize_range(norm_AC')';
% Smooth the AC.
norm_smth_AC = sgolayfilt(norm_AC',3,9)';

pyr_ix = find(g == 0);
PYR_AC = norm_smth_AC(pyr_ix,:);
g2 = kmeans(nan_to_val(PYR_AC),2);
ix1 = find(g2==1); ix2 = find(g2==2);
[mx,mxix1] = max(nanmean(PYR_AC(ix1,:)));
[mx,mxix2] = max(nanmean(PYR_AC(ix2,:)));
%% Classify the cells
if  mxix1 > mxix2
    g(pyr_ix(ix2)) = 2;
    g(pyr_ix(ix1)) = 3;
elseif mxix1 < mxix2
    g(pyr_ix(ix2)) = 3;
    g(pyr_ix(ix1)) = 2;
end
bad_ix = find(isnan(sum(wv_features')) | sum(sum(wv_features'))==0);
g(bad_ix) = nan;

%% Plot
if plot_it
    if 0
        figure
        for ii = 1:Rows(norm_AC)
            clf
            plot(norm_AC(ii,:))
            hold on
            plot(norm_smth_AC(ii,:),'r','LineWidth',4)
            pause
        end
        
    end
    %% Feature plot
    ix = [];
    ix{1} = find(g == 1);
    ix{2} = find(g == 2);
    ix{3} = find(g == 3);
    pyr_ix = find(g > 1);
    figure_label(mfilename)
    plot(wv_features(ix{1},1),wv_features(ix{1},2),'b.','MarkerSize',mkrsize)
    hold on
    plot(wv_features(ix{2},1),wv_features(ix{2},2),'k.','MarkerSize',mkrsize)
    plot(wv_features(ix{3},1),wv_features(ix{3},2),'r.','MarkerSize',mkrsize)
    axis tight
    xlabel(wv_feature_labels{1},'FontSize',fontsize1)
    ylabel(wv_feature_labels{2},'FontSize',fontsize1)
    h = legend(type_labels);set(h,'FontSize',fontsize1); legend boxoff;
    box off
    set(gca,'FontSize',fontsize1)
    a = axis;
    a(2) = 800;
    axis(a)
    %% Feature histograms.
    figure_label(mfilename)
%     hist_groups(standardize_range(wv_features),[],260)
    hist_groups(wv_features,[],260)
    h=legend(wv_feature_labels);set(h,'FontSize',fontsize1); legend boxoff
    title('Waveform Widths','FontSize',fontsize1)
    figure
    hist_groups({wv_features(ix{1},2) wv_features(ix{2},2) wv_features(ix{3},2)},[],260,[0 0 1; 0 0 0; 1 0 0])
    xlabel(wv_feature_labels{2},'FontSize',fontsize1)
    legend(type_labels,'FontSize',fontsize1); legend boxoff
    title('Waveform Peak To Trough Width','FontSize',fontsize1)
    pubify_figure_axis
    %% Waveforms
    fun = @normci;
    figure_label(mfilename)
    %subplot(2,4, [1 2])
    plot(0,0,'b-',0,0,'k-',0,0,'r-','LineWidth',5)
    clrs = [0 0 1; 0 0 0; 1 0 0];
    sym = {'.' '.' '.'};
    hold on
    for ii = 1:3
        [mn, ci] = fun(ALL_WV(ix{ii},:));
        plot_confidence_intervals(ALL_WV_x_msec,mn,ci,clrs(ii,:),0);
        %plot(ALL_WV_x_msec,ALL_WV(ix{ii},:),clrs{ii})
        hold on
    end
    legend(type_labels,'FontSize',fontsize1); legend boxoff
    %xlabel('msec')
    %ylabel('Energy Normalized')
    box off; axis off
    %% Autocorrs
    xix = find(AC_x_msec< 301);
    set(gca,'FontSize',fontsize1)
    
    f1 = figure_label(mfilename);
    f2 = figure_label(mfilename);
    for ii = 1:3
        %subplot(2,4, [5 6])
        figure(f1)
        [mn, ci] = fun(AC(ix{ii},xix));
        plot_confidence_intervals(AC_x_msec(xix),mn,ci,clrs(ii,:),0);
        hold on
        xlabel('msec','FontSize',fontsize1); ylabel('Hz','FontSize',fontsize1)
        box off
        set(gca,'FontSize',fontsize1)
        figure(f2)
        [mn, ci] = fun(norm_AC(ix{ii},xix));
        plot_confidence_intervals(AC_x_msec(xix),mn,ci,clrs(ii,:),0);
        hold on
        xlabel('msec','FontSize',fontsize1); ylabel('Norm Hz','FontSize',fontsize1)
        box off
        set(gca,'FontSize',fontsize1)
    end
    %% Autocorr PC's
    xix = find(AC_x_msec < 150);
    [pc,sc]=pca(nan_to_val([norm_smth_AC(pyr_ix,xix) ]));
    %figure; plot(sc(:,1),sc(:,2),'.')
    SC = pc'*norm_smth_AC(:,xix)';
    SC = SC';
    
    figure_label(mfilename);% subplot(2,4, [3 4])
    for ii = 1:3
        plot(SC(ix{ii},1),SC(ix{ii},2),'.','Color',clrs(ii,:),'MarkerSize',mkrsize)
        hold on
    end
    xlabel('PC1','FontSize',fontsize1);ylabel('PC2','FontSize',fontsize1)
    legend(type_labels);
    box off
    axis tight
    %axis square
    set(gca,'FontSize',fontsize1)
    title('PC of the norm autocorr','FontSize',fontsize1)

    figure
    plot(AC_x_msec(xix),pc(:,1));
    axis tight
    box off 
    %axis off
    title('PC1 of the autocorrs')
end
