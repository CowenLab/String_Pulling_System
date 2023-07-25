function [T, IDX] = Restrict(I, start_ts, end_ts)
% INPUT:
%      I. A cell array of vectors of timestamps or a single double vector of timestamps OR
%      a matrix where the first column is timestamps.
%      start_ts and end_ts - the start and end valu to restrict the values
%      of I.
% OUTPUT:
%      same format as I, but with times outside of the start and end ts removed
%      IDX  are the indices in the original I of the restricted data.
%
% similar to the restrict function for ts objects except the ts object version does not return idx.
%
% cowen
%    2009: to handle matrices 
%    2020: Simplified considerably
T = []; IDX = [];

if isempty(start_ts) || isempty(I)
%     disp('WARNING: START AND END TS or INPUT ARE EMPTY!!! RETURNING EMPTY.')
    return
end

if min(size(I)) == 1
    I = I(:);
end

if isinteger(I)
    I = double(I);
    disp('WARNING: input to Restrict was an integer when expecting a double. Converting')
end

if nargin == 2
    % 2 column start and end times are provided. 
    end_ts = start_ts(:,2);
    start_ts = start_ts(:,1);
end

if iscell(I)
    % restrict a bunch of things.
    for ii = 1:length(I)
        [T{ii}, IDX{ii}] = Restrict(I{ii},start_ts,end_ts);
    end
    return
end

% The core code is here:
IDX = false(size(I(:,1)));
% the logic is make TRUE good periods of time that fall within the target
% intervals. It starts in the order in which you given the interevals.
% This means that if you have overlapping intervals, then the 'good'
% periods will keep getting bigger and bigger. For exampel, if you have a
% big interval somewhere later or at the begginngin - it will take
% precedence and blur together all the smaller intervals within - which is
% often but not always what you want.

for ii =1:length(start_ts)
    IDX = IDX | I(:,1) >= start_ts(ii) & I(:,1) <= end_ts(ii);
end
T = I(IDX,:);
