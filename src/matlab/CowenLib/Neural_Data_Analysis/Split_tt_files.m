function Split_tt_files(TTname,nFiles_Or_nSpikes,nSpikesPerBlock,Overlap)
%
%  SplitInBlockedTTFiles(TTname,nFiles,nSpikesPerBlock,Overlap)
% 
% Split a TT file (sun or NT) into nFiles blocked TT files (sun format) with
% nSpikesPerBlock consecutive spikes per block.
%
% INPUT: 
%   TTname .... filname of TT input file (string)
%   nFiles or nSpikes.... number of desired output files. If this number is > 100, it is assumed
%      you are specifying the number of spikes per file and nFiles is calculated.
%   nSpikesPerBlock .... number of consecutive spikes per block
%   Overlap  ... percent overlap of spikes in different files (0...1)
%
% cowen 2001. very small modifications to peter's original code. Now it can read extremely huge files
% PL 2001

[fdir,fname,fext] = fileparts(TTname);
if strcmpi(fname(1:2),'TT')
   [t] = LoadTT0_nt(TTname);
elseif strcmpi(fname(1:2),'ST')
   error('Not implemented yet')
elseif strcmpi(fname(1:2),'SE')
   error('Not implemented yet')
else
   warndlg('Only filenames starting with TT are reckognized!!!','split_tt_files_by_block Warning!');
   return;
end%if
nSpikes = length(t);

if nFiles_Or_nSpikes > 100
    nFiles = ceil((nSpikes*(1+Overlap))/(nFiles_Or_nSpikes));
else
    nFiles = nFiles_Or_nSpikes;
end

nSpikesPerExtendedBlock = floor(nSpikesPerBlock*(1+Overlap));
nBlocks = ceil(nSpikes/nSpikesPerBlock);


for ii=1:nFiles
   fnameout = fullfile(pwd, [fname 'b' num2str(ii) '.tt']);
   % create index arrays
   ix{ii} = [];
   for ib = 1:nBlocks 
      bstart = min(1+(ii-1)*nSpikesPerBlock+nFiles*(ib-1)*nSpikesPerBlock,nSpikes);
      bend = min(bstart+nSpikesPerExtendedBlock,nSpikes);
      ix{ii} = [ix{ii}, bstart:bend];
      if bend == nSpikes
         break;
      end%if
   end%ib
  [tout,wv] = LoadTT0_nt(TTname, t(ix{ii}),1);
  WriteTT0(fnameout, tout, wv);
end%ii


