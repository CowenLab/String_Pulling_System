function Write_partial_TT(IN_TTname,OUT_TTname,nSpikesPerBlock, spiketimes)
%function Write_partial_TT(IN_TTname,OUT_TTname,nSpikesPerBlock, spiketimes)
%
%

[fdir,fname,fext] = fileparts(TTname);
nSpikes = length(spiketimes);

if nFiles_Or_nSpikes > 100
    nFiles = ceil((nSpikes*(1+Overlap))/(nFiles_Or_nSpikes));
else
    nFiles = nFiles_Or_nSpikes;
end

nSpikesPerExtendedBlock = floor(nSpikesPerBlock*(1+Overlap));
nBlocks = ceil(nSpikes/nSpikesPerBlock);


for ii=1:nFiles
   % create index arrays
   ix = [];
   for ib = 1:nBlocks 
      bstart = min(1+(ii-1)*nSpikesPerBlock+nFiles*(ib-1)*nSpikesPerBlock,nSpikes);
      bend = min(bstart+nSpikesPerExtendedBlock,nSpikes);
      ix = [ix, bstart:bend];
      if bend == nSpikes
         break;
     end%if
  end%ib
  
  switch nTrodes
  case 4
    fnameout = fullfile(fdir, [fname 'b' num2str(ii) '.tt']);
    [tout,wv] = LoadTT0_nt(TTname, t(ix),1);
  case 1
    fnameout = fullfile(fdir, [fname 'b' num2str(ii) '.tt']);
    [tout,wv] = LoadSE0_nt_ext(TTname, t(ix),1);
  end
  
  WriteTT0(fnameout, tout, wv);
end%ii