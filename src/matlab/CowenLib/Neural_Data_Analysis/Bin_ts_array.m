function [O,start_end_times] = Bin_ts_array(ts_array, start_end_times, shift, validate)
% A function to bin a cell array of timestamps into a matrix. Unlike other 
% binning programs, the bin start and end times are completely up to the caller.
%
%function [O,start_end_times] = Bin_ts_array(ts_array, start_end_times);
% 
% INPUT: ts_array: a cell array of timestamps(as vectors) or ts objects
%        start_end_times: a n x 2 matrix of start and end time to bin the timestamps. Bins are
%         made from col1 up to but NOT including col 2. Intervals CAN overlap.
%         OR, you can just pass a single value in the same units as what you pass in the ts_array
%         This is assumed to be the space between
%         timestamps in whatever units the timestamps are in. 
%         Results will be binned from the first to the last timstamp with this bin size.
%        shift:(0ptional) A third argument (assuming the second is a binsize)
%        specifies the shift for a sliding bin. For instance, if you want
%        overlapping bins, you could have a binsize of 1000msec and a shift
%        of 200msec.
%
% OUTPUT: a matrix with rows = to the number of start and end times and cols
%         equal to the number of elements in the ts_array.
%         optionally the start and end times of each bin in R.
% 
%  NOTE: MakeQFromS bins on the centers of the values returned from the Range command whereas
%        Bin_ts_array bins between the timestamps returned in R. (>=col1 and < col2). 
%
% cowen 2002
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert to vectors if necessary.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4
    validate = 0;
end
if ~iscell(ts_array)
    ts_array = {ts_array};
end
ncells = length(ts_array);
if isempty(ts_array)
    O =[];
    return
end
if isa(ts_array{1},'ts')
    for ii = 1:ncells
        ts_array{ii} = Data(ts_array{ii});
    end
end

if length(start_end_times) == 1
    % user passed a dt in timestamps!: Create your own start_and_end_times.
    dt = start_end_times;
    mn = inf;
    mx = 0;
    % Find smallest and larges timestamp.
    for ii = 1:ncells
        if ~isempty(ts_array{ii})
            mn = min([ts_array{ii}(1) mn]);
            mx = max([ts_array{ii}(end) mx]);
        end
    end    
    if (~isinf(mn) && mx~=0)
        if nargin >2
            % sliding bins
            tt = mn:shift:mx;
        else
            % non-overlapping bins.
            tt = mn:dt:mx;
        end
        start_end_times = [tt(:) tt(:)+dt];
        
    else
        disp('Could not find any spikes')
        O = [];
        return
    end
    %disp('Created range.')
end

if min(size(start_end_times)) ==1
    % a vector of edges instead of start end times was passed. Convert
    tmp1 = start_end_times(1:end-1);
    tmp2 = start_end_times(2:end)-eps;
    start_end_times = [tmp1(:) tmp2(:)];
end

nbins = size(start_end_times,1);
O = zeros(nbins,ncells);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sort the rows just to be careful. If they aren't sorted, then
% bin_times by intervals WILL fail.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_end_times = sortrows(start_end_times);
for ii = 1:ncells
    %ii
    if ~isempty(ts_array{ii}) % If empty, bin_times_by_intervals could crash.
        if validate == 1
            % Test bin_times_by_intervals against the muuuch slower method.
           
            for jj =1:Rows(start_end_times)
                O(jj,ii) = sum(ts_array{ii} >= start_end_times(jj,1) .* ...
                    ts_array{ii} <= start_end_times(jj,2));
            end
        else
            % NOTE: Sometimes, timestamps won't come in sorted (in teh case
            % when they are alignments relative to an event as in a PETH).
            % That is why I sort.
            %save('C:\debug.mat')
            % NANs Will KILL bin_times_by_intervals. Get rid of them if there are any.
                good_IX = ~isnan(sum(start_end_times,2));
                if ~isempty(good_IX)
                    O(good_IX,ii) = bin_times_by_intervals(sort(ts_array{ii}),start_end_times(good_IX,1),start_end_times(good_IX,2));
                end
%                 O(:,ii) = histcounts(ts_array{ii},start_end_times(:,1),start_end_times(:,2));
        end
    end
end
