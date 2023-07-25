function EC = Load_params_from_EC_config(filename)
% Load_params_from_EC_config_file
%
% cowen
L = textread(filename,'%s');
for ii = 1:length(L)
    switch L{ii}
        case 'threshold_compare_method'
            EC.threshold_compare_method = L{ii+1};
            ii = ii + 1;
        case 'templates'
            EC.templates = [];
            % load numbers until you get to a -999.
            count = 1;
            eof = 0;
            while (eof ~= 1)
                V(count) = str2num(L{ii+count});
                if (ii+count) == length(L)
                    eof = 1;
                end
                count = count + 1;
            end
            EC.templates = reshape(V,5,length(V)/5)';
            idx = find(EC.templates(:,1)==-999);
            EC.templates(idx,:) = [];
            EC.templates(find(EC.templates==-999)) = nan; 
            % Get rid of the blanked out cells.
            badidx = find(isnan(EC.templates(:,3)));
            EC.templates(badidx,:)= [];
            % If this experiment never presented vector 3, don't bother
            % displaying it.
            ii = ii+count;
        case 'integration_time_msec'
            EC.binsize_msec = str2num(L{ii+1});
            ii = ii + 1;
        case 'binshift_msec'
            EC.binshift_msec = str2num(L{ii+1});
            ii = ii + 1;
        case 'n_seconds_to_store'
            EC.spike_rate_sliding_window_sec = str2num(L{ii+1});
            EC.spike_rate_sliding_window_bins = EC.spike_rate_sliding_window_sec*1000/EC.binshift_msec;
            ii = ii + 1;
        case 'rate_matrix_rb_secs' % same as above, just renamed
            EC.spike_rate_sliding_window_sec = str2num(L{ii+1});
            EC.spike_rate_sliding_window_bins = EC.spike_rate_sliding_window_sec*1000/EC.binshift_msec;
            ii = ii + 1;
        otherwise
    end
end
