% This process eeg is for analyzing Mark's cortical data
% see Q14 in hyper 5 for details.
%
% Load in a dataset CR file.
threshold = 45; % 40 is the default.

EEGfiles = dir('marksCR8_??');
filenames =  {'marksCR8_s1' 'marksCR8_m1' 'marksCR8_s2'};

for nameidx = 1:length(filenames)
  % Change it to a tsd
  disp(['Loading sleep EEG data for ' filenames{nameidx}]);
  crtsd = CR_to_tsd(ReadCR(filenames{nameidx}));
%  crtsd = Restrict(crtsd,1,200000);
  % Resort the data: I suspect problems in Mark's CR data.
  [t idx] = sort(Range(crtsd,'ts'));
  d = Data(crtsd);
  crtsd = tsd(t, d(idx));
  disp('loaded')

  if ~isempty(findstr('CR0',filenames{nameidx})) % 7 Hz eeg
    disp('FIltering for 7 Hz')
    F   = Filter_7hz(crtsd);
    fn_filt = [filenames{nameidx} '_7Hz'];
  else                       % 200 Hz eeg
    F = Filter_200hz(crtsd);
    %fn_filt = [filenames{nameidx} '_200Hz'];
    [st_ts, et_ts, all, peak_starts, peaks] = Ripple_times(F,threshold,0);
    O = round([Data(st_ts),Data(et_ts)]);
    P = round([Data(peak_starts)]);
    allP = round([Data(peaks)]);
    fn_rip = [filenames{nameidx} '_riptimes.ascii'];
    Save_as_ascii(O,fn_rip,1);
    fn_rip = [filenames{nameidx} '_peak_riptimes.ascii'];
    Save_as_ascii(P,fn_rip,1);
    fn_rip = [filenames{nameidx} '_allpeak_riptimes.ascii'];
    Save_as_ascii(allP,fn_rip,1);
  end
  disp('Saving filtered data')
  %save(fn_filt, 'F')
  clear F crtsd O st_ts et_ts
end

