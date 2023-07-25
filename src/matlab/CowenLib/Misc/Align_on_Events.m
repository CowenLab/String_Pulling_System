function [OA] = Align_on_Events(events_to_align, align_events, period_before, period_after)
%function [OA] = Align_on_Events(events_to_align, align_events, period_before, period_after)
% Essentially a PETH or Spike triggered average.
%
% Returns the difference of each events_to_align point to every event in align_events.
%
% INPUT
%   events_to_align: the events to rescale relative to the align events
%     (e.g. the spikes to be aligned to stimulus onset) MUST BE SORTED
%   align_events: the events upon which to align the spikes (e.g. the CS
%     onset)
%   period_before: period in timestamp units before the align events to
%     capture.
%   period_after: period after the align event to capture.
%
% OUTPUT
% OA = nx2 matrix of offet from alignment and the index into align events that corresponds to each interval.
%
%  To get a PETH around the target event, do the following:
%   [OA] = Align_on_Events(events_to_align, align_events, period_before,
%   period_after)
%   CRAPPY:[h,x] = ksdensity(OA(:,1));
%   OR
%   [h,x] = hist(OA(:,1),100);
%   plot(x,h); xlabel('time'); ylabel('count');
%
%   to get raster plots you will need to do the following
%    plot(OA(:,2),OA(:,1),'k.'); ylabel('Trial');xlabel('time')
%   and..
%         M = zeros(length(align_events),length(xx));
%         u = unique(OA(:,2));
%         for ii = 1:length(u)
%             M(u(ii),:) = histc(OA(OA(:,2)==u(ii),1),xx);
%         end
%     imagesc(M)
% OR 
% 
% [M] = Hist_by_row_id(A,bin_centers, n_trials)
% % see peth_raster
% cowen 2006
if isa(align_events,'single')
    error('Does not work on singles')
end
if isempty(events_to_align)
    OA = [];
    return
end

A = cell(length(align_events),1);
G = cell(length(align_events),1);
for ii = 1:length(align_events)
    ast_msec = events_to_align - align_events(ii);
    %
    % Using binsearch instead of find is MUCH (at least 3x) faster.
    %  binsearch DOES NOT WORK FOR SINGLES
    b1 = binsearch(ast_msec,-period_before);
    b2 = binsearch(ast_msec, period_after );
    % I tried binsearch_vector - but for a vector of 2, it does not speed
    % things up.
    if ast_msec(b1) < -period_before
        b1 = b1+1;
    end
    
    if ast_msec(b2) > period_after
        b2 = b2-1;
    end
    
    if b1 <= b2
        % Using cell arrays is MUCH faster than concatenating a matrix.
        A{ii} = ast_msec(b1:b2);
        G{ii} = ones(length(ast_msec(b1:b2)),1)*ii;
    end
end
% This is much faster than concatenating on the fly. FYI.
OA = [cell2mat(A) cell2mat(G)];

if nargout == 0
    subplot(4,1,1:3)
    plot(OA(:,1),OA(:,2),'k.'); ylabel('Trial');xlabel('time')
    hold on
    axis([-period_before period_after 1 length(align_events)]);
    subplot(4,1,4)
    [h,x] = hist(OA(:,1),100);
    plot(x,h)
    axis tight
    b = axis;
    axis([-1*period_before period_after b(3:4)])
    if 0 % Another way to do it...
        xx = linspace(min(OA(:,1)),max(OA(:,1)),101);
        yy = 1:length(align_events);
        
        %     tic
        M = zeros(length(align_events),length(xx));
        u = unique(OA(:,2));
        for ii = 1:length(u)
            M(u(ii),:) = histc(OA(OA(:,2)==u(ii),1),xx);
        end
        %     toc
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        figure
        subplot(4,1,1:3)
        imagesc(xx,yy,M)
        colormap(1-gray)
        a = axis;
        
        axis xy
        subplot(4,1,4)
        plot(xx,mean(M))
        axis tight
        b = axis;
        axis([a(1:2) b(3:4)])
    end
end

