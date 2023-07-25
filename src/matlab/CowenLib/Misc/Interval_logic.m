function [varargout] = Interval_logic(action, varargin)
% Performs various operations on intervals.
%INPUT:
% action:
%
% 'merge' - merges intervals in arg2 that have an inter-interval distance closer 
%   than the time specified by  arg3 
% 'intersect' - within times common to argin 2 and 3.
%
% 'non-overlapping' - returns only those intervals specified in arg2 that 
%  are non-overlapping with arg3. This is good for artifact rejection if
%  arg3 is the interval of the artifact.
%
% OUTPUT: depends

% cowen
switch lower(action)
    case 'merge'
        d_times = varargin{1}(1:end-1,2) - varargin{1}(2:end,1);
        idx = find (d_times < varargin{2});
        start_times = varargin{1}(idx,1);
        end_times = varargin{1}(idx,2);
        
        varargout{1}= [start_times(:) end_times(:)];
    case 'intersect'
    case 'merge_with_big'
        % Assumes the first interval is the primary, big interval
        % Just returns the large range that encompasses the smaller
        % intervals contained within the big interval - this is harder than
        % it seems because the small may overlap with the big at the edges.
        % It should also pass in the small intervals (vargout 2)
        varargout{1}(1:2) = nan;
        big = varargin{1}; small =  varargin{2};
        if min(small(:,1)) > max(big(:)) |  min(big(:)) > max(small(:));
            varargout{1} = big;         
            varargout{2} = big;
            return
        end
        
        ix = find(small(:,1) < big(1),1,'last');
        if ~isempty(ix)
            if small(ix,2) > big(1)
                % Change the movement time and the current start to be this point.
                varargout{1}(1) = big(1);
                small(ix,1) = big(1);
                small = small(ix:end,:);
            else
                varargout{1}(1) = small(ix+1,1);
                small = small((ix+1):end,:);
            end
        end

        ix = find(small(:,2) > big(2),1,'first');
        if ~isempty(ix)
            if small(ix,1) < big(2)
                varargout{1}(2) = big(2);
                small(ix,2) = big(2);
            else
                varargout{1}(2) = small(ix-1,2);
            end
        end
        ix2 = find(small(:,2) > varargout{1}(2));
        small(ix2,:) = [];
        varargout{2} = small;
    otherwise
        error('unknown action')
end

