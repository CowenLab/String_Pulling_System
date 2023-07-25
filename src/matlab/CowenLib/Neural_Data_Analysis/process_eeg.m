function process_eeg(fname,threshold,what_to_filter_for, issun)
% INPUT: A threshold and a file name or cell array of file names (CSC files)
% OUTPUT: ascii files of start and end times.
%

if nargin < 4
    issun = 0;
end 
if nargin < 3
    issun = 0;
    what_to_filter_for = 'ripples';
end

disp(['Using threshold of ' num2str(threshold) ])

if nargin == 1
  EEGfiles = dir('e*_CR*_f');
  filenames =  sort({EEGfiles.name})
else 
  filenames{1} = fname;
end

for nameidx = 1:length(filenames)
    % Change it to a tsd
    [p name e] = fileparts(filenames{nameidx});
    disp(['Loading sleep EEG data for ' filenames{nameidx}]);
    [EEG.original_ts_sec, EEG.original_data, EEG.sampling_freq] = ...
        ReadCR_to_matrix(filenames{nameidx});
end
disp('loaded')

switch (what_to_filter_for)
case {'theta','spindles'}
      disp('Filtering for theta or spindles')
      fn_filt = [name '_' what_to_filter_for];
      min_diff_tstamp = 8000; % Assume a continuous spindle episode should be at least
                          % 1/2 second long
      F   = Filter_7hz([EEG.original_ts_sec EEG.original_data],5,11,EEG.sampling_freq);
      [tmpStart_ts, tmpEnd_ts] = FindRippleIntervals(F, threshold);
      [the_times] = Clean_start_end([Data(tmpStart_ts), Data(tmpEnd_ts)],min_diff_tstamp);
      fn_times = [name '_' what_to_filter_for '.txt'];
      Save_as_ascii(the_times,fn_times,1);
  case 'ripples'
      disp('Filtering for ripples')

      if isempty(threshold)
          threshold = 45;
      end
      
      F = Filter_200hz([EEG.original_ts_sec(:) EEG.original_data(:)], 100, 250, EEG.sampling_freq, 700,0);
      [st_ts, et_ts, all] = Ripple_times(F,threshold,0);
      O = sort([st_ts(:),et_ts(:)]);
      fn_rip = [name '_riptimes.txt'];
      save(fn_rip,'O','-ascii','-double')

      fn_filt = [name '_' what_to_filter_for];
  case 'gamma'
      fn_filt = [name '_' what_to_filter_for];
  otherwise
      error ('Incorrect type specified')
  end
  %disp('Saving filtered data tsd.')
  %save([fn_filt '.mat'], 'F')
  clear F crtsd O st_ts et_ts;
  pack
end

