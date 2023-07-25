function Reduce_CSC(CSCfilename, start_ts, end_ts)
%function Reduce_CSC(CSCfilename, start_ts, end_ts)
% Takes a CSC file and spits out another for just the times specified by start_ts and end_ts
%
%start_ts  = 8364412838;
%end_ts    = 13940592958;
[p,n,e] = fileparts(CSCfilename);
[TimeStamps, ChannelNumbers, SampleFrequencies, NumberValidSamples, Samples, NlxHeader] = Nlx2MatCSC(CSCfilename,1,1,1,1,1,1,start_ts,end_ts);
Mat2NlxCSC(fullfile(p,[n '_r' e]), TimeStamps, ChannelNumbers, SampleFrequencies, NumberValidSamples, Samples, length(TimeStamps));
