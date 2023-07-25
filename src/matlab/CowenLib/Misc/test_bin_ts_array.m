function test_bin_ts_array (ts_array, dt_timestamps, shift_timestamps)
start_t = inf;
end_t = 0;
for ii = 1:length(ts_array);
    start_t = min([ start_t min(Data(ts_array))]);
    end_t = max([ end_t max(Data(ts_array))]);
end
r = [start_t:shift_timestamps:(end_ts-shift_timestamps)];
Q_bintimes_ts = [r(:) r(:)+dt_timestamps];
