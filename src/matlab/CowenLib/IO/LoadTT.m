function TT = LoadTT(fn)

% TT = LoadTT(fn)
%
% Loads an NSMA TT file.
%
% INPUTS:
%   fn -- .tt file
%
% OUTPUTS:
%   TT is a tsd structure 
%      where data = nSpikes x nSamplesPerSpike x nTrodes
%
% uses mex file LoadTT0(fn) to do the main read.
%
% ADR 1998
% version L5.1
%
% PL 2001:
% added selection of TT files either by 'TT*' or '*.tt'
% cowen 2002
%  modified to recognize files that have prefixes before the TT SE and ST identifiers.
%  
% status PROMOTED

[fdir,fname,fext] = fileparts(fn);
if ~isempty(findstr(fname,'TT')) | strcmpi(fext,'.tt')
   [t, wv] = LoadTT0_nt(fn);
elseif ~isempty(findstr(fname,'ST'))
   [t, wv] = LoadST0_nt(fn);
elseif ~isempty(findstr(fname,'SE'))
   [t, wv] = LoadSE0_nt(fn);
else
   warndlg('Only filenames starting with TT,ST or SE are reckognized by LoadTT!!!','LoadTT Warning!');
   return;
end%if
%t(end) = [];
%wv(end,:,:)=[];
TT = tsd(floor(t),wv);












%--------------------------------------------------------------------------------
function oldLoadTT

nTrodes=4;		% 4 channels for tetrode
nSamplesPerSpike=32;	% number of samples per spike waveform per channel
maxSpikesToRead = inf;  % maximum spikes to read
debugON = 0;

Extract_varargin;	

%---- Open file
[fp, msg] = fopen(fn,'rb','b');
if (fp == -1);   error(msg); end
[tmpdn, tmpfn] = fileparts(fn);
TTWindowName = ['Load TT (' tmpfn ')'];

%---- Read Header
H = ReadHeader(fp);
HSkip = ftell(fp);

%--- Read Timestamps
if (debugON); disp('Reading timestamps...'); end
Ttt = fread(fp, maxSpikesToRead, 'uint32', 2*nSamplesPerSpike*nTrodes); 
nSpikes = length(Ttt);
if (debugON); disp('   Done.'); end

%--- Read V
if (debugON); disp('Reading waveforms...'); end
V = zeros(nSpikes, nTrodes, nSamplesPerSpike);
fseek(fp, HSkip, 'bof');
for iS = 1:nSpikes
   DisplayProgress(iS, nSpikes, 'Title', TTWindowName);
   fseek(fp, 4, 'cof');
   TMP = fread(fp, [nTrodes nSamplesPerSpike], 'int16');
   if (size(TMP) == [nTrodes nSamplesPerSpike])
      V(iS,:,:) = TMP;
   else
      warning('TT file ends early, ignoring last sample');
   end
end
if (debugON); disp('   Done.'); end

fclose(fp);

%--- generate T
TT = tsd(Ttt, V);

return;


