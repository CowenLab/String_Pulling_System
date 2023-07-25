% Code to check the MakeQFromS function.
% First, some real timestamps... (.1msec)
t = [          16687889.77
               16687904.2
               16687918.62
               16687932.64
               16687958.69
               16687973.51
               16687985.93
               16687994.35
               16688028.81
               16688064.87
               16688089.31
               16688100.93
               16688111.75
               16688234.76
               16688244.37
               16688600.98
               16689197.99
                  16689208
               16689236.85
               16689661.17
               16700809.65
               16704554.39
               16707875.62
               16712562.35
               16713094.86
               16741958.13
               16742102.38
               16742342.38
               16742359.61
               16742520.29
               16742854.45
               16742936.19
               16742964.24
               16742979.06
               16743051.18
               16743230.69
               16743291.99
               16743300.01
                16743889.4
               16744353.39
               16746111.97
               16746176.48
               16746237.78
               16746245.79
               16746337.95
               16746380.02
               16746783.91];
% Now, some intervals from which to bin them...

R = [          16687889.77              16697889.769
               16697889.77              16707889.769
               16707889.77              16717889.769
               16717889.77              16727889.769
               16727889.77              16737889.769
               16737889.77              16747889.769
               16747889.77              16757889.769];
           
% MakeQFromS uses the first timestamp in the cell array to determine the start timestamp
% and increments by dt_timestamps. I am making an intervals array so that I can more easily
% compare my program's results with makeQfromS.

ts_array = {ts(t)};
interval_msec = 1000;
Qctsd = MakeQFromS(ts_array,interval_msec*10);
rQctsd = Range(Qctsd);
dQctsd = Data(Qctsd);
% Here are the results.
dQctsd(1:7,:)
% Do it the old fashioned way-- by using find.
h = [];
for ii = 1:6
    h(ii)=length(find(t>=rQctsd(ii) & t<rQctsd(ii+1)));
end
h
% Are they different? If so, we have a problem. What might be happening is that MakeQfromS
% treats the times as the CENTER of the bin not the beginning and the end. This makes
% things a little confusing. I really don't understand exactly how makeQFrom S does the final binning.
% it uses the sparse function in an interesting and opaque way.

% The following assumes the range from the ctsd is actually the centers of the bins.
h = [];
v = 10*interval_msec/2;
for ii = 1:7
    
    h(ii)=length(find(t>=rQctsd(ii)-v & t<rQctsd(ii)+v));
end
h
% This seems to work fine. Viola-- the real answer is that the 
% range represents the centers of the bins and not the start and end.

%%%%%%%%
% let's test the mex bin stuff.

O1 = Bin_ts_array(ts_array,R);
shift_msec = 500;
interval_msec = 1000;
intervals = t(1):(shift_msec*10):t(end);
Rs = [intervals(:) intervals(:)+interval_msec*10];
Rs = Rs(1:7,:);
O2 = Bin_ts_array(ts_array,Rs);
