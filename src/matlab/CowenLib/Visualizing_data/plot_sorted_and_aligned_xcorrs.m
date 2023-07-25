function [outCCep] = plot_sorted_and_aligned_xcorrs(xdim, CC, cell1_cell2_EPID, isAC, alignment_epoch, epoch_names,sort_feature,plot_it)
% INPUT
%   xdim - xaxis of the plot
%   CC - n samples x n bins xcorrs.
%   cell1_cell2_EPID  - a n samples x 3 matrix of cell1id (must be unique), cell2(must be unique) id and
%    epoch id.
%   isAC - 1 if autocorr, 0 if xcorr
%   alignment_epoch - the epoch (in cell1_cell2_EPID) on which to align the
%    data - 0 if you want to align each epoch individually.
%   sort_feature - ncorrs x 1 vector of the feature on which to sort (e.g.
%    peak or trough or pc1...
% presumes user smoothes the data CC before passing it in.
%
% OUTPUT plots of hte aligned crosscorrs.
%   or if outCCep is requested, then it returns the matrices used for the
%   plots.
%
% find max for sorting
if nargin < 8 | nargout ==0
    plot_it = true;
end
plot_dots = false; % turn to false if you do not want the dots.

if 0 % This is artificial data to validate the program.
    % sample data for checking the program.
    epoch_names = {'1' '2' '3' '4'};
    alignment_epoch = 1;
    isAC = 0;
    CC = rand(400,200);
    pkix = ceil(rand(200,1)*80);
    %pkix = [pkix;pkix];
        
    CC(sub2ind(size(CC),[1:200]',pkix(:))) = 5;
    % insert a peak somewhere from 
    xdim = linspace(-100,100,200);
    cell1_cell2_EPID = [repmat([1:100;100:-1:1]',4,1) [ones(100,1)*1; ones(100,1)*2; ones(100,1)*3; ones(100,1)*4]];      
end

if isAC
    sort_cols = 1:floor(cols(CC)/2);
else
    sort_cols = 1:cols(CC);
end

outCCep = [];
%if 0
%    % reverse xcorrs with peaks on the left.
%    [mx,ix] = max(CC(:,sort_cols)');
%    ix = find((ix - cols(CC)/2) < 0);
%    CC(ix,:) = CC(ix,end:-1:1);
%end
if alignment_epoch == 0
    % align individually.

else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Remove all other crosscorrs that are not found in this epoch.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ix = find(cell1_cell2_EPID(:,3)==alignment_epoch);
    [c,six] = setdiff(cell1_cell2_EPID(:,1:2),cell1_cell2_EPID(ix,1:2),'rows');
    CC(six,:) = [];
    sort_feature(six) = [];
    cell1_cell2_EPID(six,:) = [];
    fprintf('Removed %g incongruent pairs\n',length(six));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get the alignments for the target epoch.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ix = find(cell1_cell2_EPID(:,3)==alignment_epoch);
    CCep = CC(ix,:);
    sort_feature_ep = sort_feature(ix);
    c1_c2_sorted    = cell1_cell2_EPID(ix,1:2);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [s,sort_ix]     = sort(sort_feature_ep);
    c1_c2_sorted    = c1_c2_sorted(sort_ix,:);    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Reverse xcorrs so that all xcorrs during the target epoch have the
    % same direction of the bias. Apply that reversal rule to the same cell pairs in the other
    % epochs.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isAC
        CCep = CCep(sort_ix,:); % IMportant that everyting is ordered the same.
        sort_feature_ep = sort_feature_ep(sort_ix);      
        subix = find( sort_feature_ep < 0);
        reverse_pairs = c1_c2_sorted(subix,1:2); % Make the epoch code negative - that's the cue to reverse the order.
        % Find JUST those cells in the entire matrix and reverse the suckers.
        for ii = 1:rows(reverse_pairs)
            ix = find(cell1_cell2_EPID(:,1) == reverse_pairs(ii,1) & cell1_cell2_EPID(:,2) == reverse_pairs(ii,2));
            CC(ix,:) = CC(ix,end:-1:1);
            % 
            %ix = find(cell1_cell2_EPID(:,1) == reverse_pairs(ii,1) & cell1_cell2_EPID(:,2) == reverse_pairs(ii,2) & cell1_cell2_EPID(:,3) == alignment_epoch);
            sort_feature(ix) = sort_feature(ix)*-1;
        end
    end
end

uEpochs = unique(cell1_cell2_EPID(:,3));
for iEp = 1:length(uEpochs)
    epix = find(cell1_cell2_EPID(:,3)==uEpochs(iEp));
    CCep = CC(epix,:);
    sort_feature_ep = sort_feature(epix);
    cell1_cell2_EPID_ep = cell1_cell2_EPID(epix,:);
    if alignment_epoch == 0
        % resort each time.
        %[mx,sort_feature_ep] = max(CCep(:,sort_cols)');
        % Remove CC's that did not have significant bias.
        [s,sort_ix] = sort(sort_feature_ep);
    else
        % Find the cellpairs in this epoch that correspond to the pairs in
        % the other epochs.
        sort_ix = [];
        count = 1;
        for ii = 1:rows(c1_c2_sorted)
            ix = find(cell1_cell2_EPID_ep(:,1) == c1_c2_sorted(ii,1) & cell1_cell2_EPID_ep(:,2) == c1_c2_sorted(ii,2));
            if ~isempty(ix)
                sort_ix(count) = ix;
                count = count + 1;
            end
        end
    end
    CCep = CCep(sort_ix,:);
    sort_feature_ep = sort_feature_ep(sort_ix);
    cell1_cell2_EPID_ep = cell1_cell2_EPID_ep(sort_ix,:);
    %
    if nargout > 0
        outCCep{iEp} = CCep;
        cell1_cell2_EPIDep{iEp} = [];
    end
    
    if plot_it
        % plot it
        subplot(length(uEpochs)/2,2,iEp)
        imagesc(xdim,1:rows(CCep),CCep)
        hold on
        %[mx,ix] = max(CCep');
        if plot_dots
            plot(sort_feature_ep,1:rows(CCep),'w.','MarkerSize',6)

            plot(sort_feature_ep,1:rows(CCep),'r.','MarkerSize',4)
        end
        h = plot_in_quadrant(mean(CCep),'upper_left',[.4 .5],'k');
        set(h,'LineWidth',3)
        h = plot_in_quadrant(mean(CCep),'upper_left',[.4 .5],'r');
        set(h,'LineWidth',2)

        % Plot some reference lines
        if ~isAC
            flat = ones(size(mean(CCep)))*min(mean(CCep));
            flat(round(length(flat)/2)) = max(mean(CCep));
            h = plot_in_quadrant(flat,'upper_left',[.4 .5],'w');
            set(h,'LineWidth',3)
            h = plot_in_quadrant(flat,'upper_left',[.4 .5],'r');
            set(h,'LineWidth',2)
        end
        if iEp == alignment_epoch
            title([epoch_names{iEp} ': alignment source'])
        else
            title(epoch_names{iEp})
        end
        if iEp == 1
            xlabel('msec')
            if isAC
                ylabel('autocorr')
            else
                ylabel('crosscorr')
            end
        end
        axis xy
        
    end
end

return
