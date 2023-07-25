function M = load_text_file_and_reduce(filename,startcol, ncols,windowsize_bins,shiftsize_bins);
% For very large text files. It will load the file in parts, compute the
% average for windowsize bins and store it in M. It will then move ahead by
% shiftsize_bins and compute the average again. This allows you to read in
% very large files. Timestamps are for the BEGINNING of each bin. 
% filename = the name of the file
% startcol = the starting column to used
% ncols = the number of columns from the startcol to load. 1 means you just
% load the startcol.
% windowsize_bins = the size of the window to average across.
% Shiftsize_bins = the number of points to shift forwards after every
% average.
Im_working = 1;
chunksize = 40000; 
M = [];
start_row = 0; 
end_row = chunksize;
while(Im_working)
    try
        R = dlmread(filename,' ',[start_row startcol end_row ncols-1]);
        sa = Sliding_average(R(:,2:end),windowsize_bins, -1, shiftsize_bins);
        M = [M ; [R(1:shiftsize_bins:end,1) sa]];
        start_row = end_row - windowsize_bins;
        end_row = start_row + chunksize;
        fprintf('%g.',end_row)
    catch
        %R = dlmread(filename,' ',[start_row startcol inf ncols-1]);
        Im_working = 0;
    end
end
% Clean up the overlap.
[m,idx] = unique(M(:,1));
M = M(idx,:);

fprintf('\n')
