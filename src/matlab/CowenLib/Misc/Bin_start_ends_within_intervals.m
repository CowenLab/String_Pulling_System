function B = Bin_start_ends_within_intervals(intervals,binsize)
%% For a set of larger intervals - bin within these intervals (at a smaller interval sizze.
% intervals = [1 10; 20 40]; binsize = 2;
% T
total_time = sum(intervals(:,2) - intervals(:,1));
B = zeros(round(total_time/binsize),2)*nan;
last = 1;
for ii = 1:Rows(intervals)
    v = intervals(ii,1):binsize:intervals(ii,2);
    B(last:(last+length(v)-1),1) = v(:);
    last = last + length(v);
end
B(:,2) = B(:,1) + binsize;
