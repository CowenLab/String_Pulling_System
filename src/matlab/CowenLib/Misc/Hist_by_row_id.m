function [M, A] = Hist_by_row_id(A, bin_centers, n_trials, centers_or_edges)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: nx2 matrix where the first col is the item wished to be
% histogrammed (e.g. alignment times for a PETH). The second col are the
% categories (e.g. trials) for each alignment time. 
%
% NOTE: if n_trials is a vector of trial IDs Hist_by_row_id will ONLY work
% on these trials and ignore the rest.
%
% % NOTE: histc has an id
% OUTPUT: the PETH for all rows from 1:max(A(:,1) or n_trials(if specified)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if nargin == 0
%     % Generate fake data for testing.
%     A(:,1) = rand(10000,1)*1000-500;
%     A(:,2) = round(linspace(.51,30.49,10000));
%     bin_centers = linspace(-400,400,20);
%     A(1:340,1) = 399;
%     A(1250:2390,1) = -399;
%     A(3400:4590,1) = 0;
%     n_trials = 20;
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4
    centers_or_edges = 'edges';
end

binsize = median(diff(bin_centers));

switch centers_or_edges
    case 'centers'
        bin_edges = bin_centers - binsize/2; % the last thing is to catch stragglers - an ideosyncracy of histc.
        bin_edges(end+1) = bin_centers(end) + binsize;
    case 'edges'
        % much more useful if you have discontinuous or odd-sized bins.
        bin_edges = bin_centers;
    otherwise
        error('improper parameter')
end

if isempty(A)
    M = [];
    
    if length(n_trials) > 1
        n_trials = length(unique(n_trials));
    end
    
    if nargin >2
        M = zeros(n_trials,length(bin_edges)-1);
    end
    return
end

if length(n_trials) > 1
    % Restrict the analysis to a set of user-specified trials.
    % This is complicated as we need to renumber the second col of A as
    % this code assumes that A has all trials - (so max(A(:,2)) = ntraials)
    % - this is not true if we wish to ignore some trials.
    % This is a pain, but let's renumber trials.
    
      
    n_trials  = unique(n_trials);
    IX = ismember(A(:,2), n_trials);
    A2 = A(IX,:); 
    for ii = 1:length(n_trials)
        IX2 = A2(:,2) == n_trials(ii);
        if ~isempty(IX2)
            A2(IX2,2) = ii;
        end
    end
    A = A2;
    n_trials  = length(n_trials);
end


u = unique(A(:,2));
if nargin < 3
    n_trials = max(u);
end
M = zeros(n_trials,length(bin_edges)-1); % the last bin is a throw-away

for ii = 1:length(u)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % NOTE: histc does strange things with the last bin - must be exactly
    % equal to this. Solution - 1) shift bins to the left by 1/2 bin size
    % and add a dummy bin to catch the last bin crap.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    M(u(ii),:) = histcounts(A(A(:,2)==u(ii),1),bin_edges); % hist was no faster.
    % A NOTE: This was actually slower --> tic;tmp = ndhist(A(A(:,2)==u(ii),1)',length(bin_edges)-1,bin_edges(1),bin_edges(end));toc
%     M(u(ii),:) = tmp(1:end-1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout == 0
    bin_centers = bin_edges(1:end-1) +binsize/2;
    subplot(4,1,1:3)
    imagesc(bin_centers,[],M)
    subplot(4,1,4)
    plot_confidence_intervals(bin_centers,M)
end