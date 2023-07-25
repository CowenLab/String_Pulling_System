function CRfile = ReadCR(EEGfile, StartTS, EndTS)
%
% CRfile = ReadCR(EEGfile)
%            ReadCR(EEGfile, StartTS, EndTS)
%
% 	Returns a CRfile Struct  with fields ts, sFreq, ddRecSize and
% 	dd
%
%
%      data array dd[512*NRecords,1] contains continuous samples in
%      range of StartTS <= ts[NRecords] <=  EndTS.  
%      The TimeStamps ts are measured in units of 1/10000 sec.
%      sFreq is the unique sampling frequency in the file (a
%      warning is printed if sFfreq is not unique).
%       
%       If only one argument is given it reads the whole CR file.
%       
% INPUTS
%      EEGfile = filename containing a std NSMA CR file
%      StartTS, EndTS = start and end timestamps of range interested in
%
% OUTPUTS
%    struct CRfile with fields
%        CRfile.ts   : [NRecords,1] column vector of TimeStamps [0.1 msec] 
%        CRfile.sFreq: sampling Frequency [Hz]
%        CRfile.ddRecSize: length of data array per record 
%        CRfile.dd   : [Ndd,1] column vector of display data [?]

%%%%%%%%%
% CCC: PL 
% Version 0.1 (01/28/99)
% Status: UNDER CONSTRUCTION

%StatusWarning('\nWORKS FOR CHEETAH v1.22.x CR FILES ONLY!\n', 'ReadCR');

%--------------
% Parameters
switch nargin
case 1, StartTS = -Inf; EndTS = Inf;
case 3, 
otherwise
   error('Call with 1 or 3 arguments.');
end

tic;
%----------------
% find file
[fp,msg] = fopen(EEGfile, 'rb','b');
if fp == -1; error(msg); end

H = ReadHeader(fp);
if isempty(H)
   % new NT CR file format
   fprintf('THIS CR FILE HAS NT FORMAT - Running ReadCR_nt\n');
   NSAMPLES = 512;
   [ts,dd,freq] = ReadCR_nt(EEGfile);
   dd(1,1:20)
   ts(1:5)
else   
   % old SUN CR file format
   
   %------------------------------
   % read entire file twice (once for each datatype 'uint16' and 'int16' in record)
   % 
   
   NSAMPLES = 512;               %  # of data samples per record (short=2bytes)
   RECORDSIZE = (5+NSAMPLES)*2;  %  # of bytes per record   
   TotalSamples = 0;
   timestamp = -Inf;
   
   % find # of records in file
   FileStartPosition = ftell(fp);
   fseek(fp,0,'eof');
   FileEndPosition = ftell(fp);
   NRECORDS = floor((FileEndPosition-FileStartPosition)/RECORDSIZE);
   %------------------------------
   % Now read the actual data.  Since we know the total number of records, 
   % we know how large to make the data structures.
   % The format of the Cheetah v1.2.x CR files is (after header):
   %
   %      tsf[1,NRecords]: timestamps_hi        ('uint16')
   %      tsf[2,NRecords]: timestamp_lo         ('uint16')
   %      tsf[3,NRecords]: # valid samples      ('uint16')
   %      tsf[4,NRecords]: sample_freqency_hi   ('uint16')
   %      tsf[5,NRecords]: sample_freqency_lo   ('uint16')
   %      dd[512,NRecords]: data array          ('int16')
   
   cr = zeros([517,NRECORDS]);    % file buffer of all ('int16')
   tsf = zeros([5,NRECORDS]);
   dd = zeros([512,NRECORDS]);
   
   fseek(fp,FileStartPosition,'bof');   
   
   %  read file in 'int16' format and convert the first 5 rows to
   % 'uint16' by 2's complement (i.e. b='uint16' in the range [2^15,2^16-1]
   % are stored in signed a='int16's as a = (b-2^16).  )
   %
   cr = fread(fp,[517,NRECORDS],'int16');
   tsf = 2^16*(cr(1:5,:) < 0) + cr(1:5,:); 
   dd  = cr(6:517,:);
   clear cr;
   fprintf(2,'ReadCR: Done reading whole file. TUsed = %f\n',toc);
   
   % erase bad records (i.e. those whose # of valid samples ~= 512)
   badsamples = find(tsf(3,:)~= NSAMPLES);
   tsf(:,badsamples) = [];
   if ~isempty(badsamples)
      errstr = sprintf('Skipped %i bad sample record(s) !!\n', ... 
         length(badsamples));
      fprintf(2,errstr);
   end%if
   
   % convert ushorts to shorts and merge hi and low words
   ts =  tsf(1,:)*65536 + tsf(2,:); 
   frq = tsf(4,:)*65536 + tsf(5,:);
   
   % check for ascending order of timestamps
   invTickSum = sum(diff(ts) < 0);
   if invTickSum ~= 0
      errstr = sprintf('File contains %i DECREASING time stamps!!\n', ... 
         invTickSum);
      warning(errstr);
   end%if
   
   % check for frequency changes
   nFreqChng = sum(find(diff(frq) ~= 0));
   if nFreqChng ~= 0
      errstr = sprintf('File (Range) contains %i different sampling frequencies !!\n', ... 
         nFreqChng);
      warning(errstr);
   end%if
   freq = frq(1);
   
end%if (SUN / NT format)

% restrict to range [StartTS, EndTS]
if(nargin > 1)
   SkipRecords = find(ts < StartTS | ts > EndTS);
   ts(SkipRecords)    = [];
   [ddrows, ddcols] = size(dd);
   if ddrows == 512
      dd(:,SkipRecords)  = [];
   elseif ddcols == 512
      dd(SkipRecords,:) = []; 
   else
      error('CR Data returned in an unrecognized structure');
   end %if
      
end%if


% cleanup
fclose(fp);

% fill CRfile struct:
CRfile.ts = ts(:);
CRfile.sFreq = freq;
CRfile.ddRecSize = NSAMPLES;
[ddrows, ddcols] = size(dd);
if ddrows == 512
    CRfile.dd = reshape(dd, (ddrows*ddcols), 1);
elseif ddcols == 512
    CRfile.dd = reshape(dd', (ddrows*ddcols), 1); 
else
    error('CR Data returned in an unrecognized structure');
end
fprintf('ReadCR has read in the file: %s\n', EEGfile);
fprintf(2,'ReadCR: Done! Used time  = %f\n',toc);






