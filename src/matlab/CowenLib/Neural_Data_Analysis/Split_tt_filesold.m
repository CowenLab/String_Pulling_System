function split_tt_files(TTname,nWaveforms_per_file,Overlap,overlap_method)
% INPUT:
%  TTname: the name of the tt file
%  nWaveforms_per_file : the number of Waveform waveforms per file 
%     filesize in Waveforms = ceil(total_Waveforms/(nWaveforms_per_file +overlap_Waveforms).
%  Overlap: a number from 0-1 indicating the 'percent' overlap between files.
%  overlap_method: grab overlaps from adjacent files ('adjacent') (default) 
%     or from the entire set ('all_data')
% OUTPUT:
%  files of length: ceil(total_Waveforms/(nWaveforms_per_file +overlap_Waveforms).
%
% cowen
% modified from lipa SpitInBlockedTTFiles
if nargin == 2
    Overlap = 0;
end

if nargin < 4
  overlap_method = 'adjacent';
end

disp('Loading all timestamps')
[fdir,fname,fext] = fileparts(TTname);
if strcmpi(fname(1:2),'TT')
   t = LoadTT0_nt(TTname);
elseif strcmpi(fname(1:2),'ST')
   error('Not implemented yet')
elseif strcmpi(fname(1:2),'SE')
   error('Not implemented yet')
else
   warndlg('Only filenames starting with TT are reckognized!!!','split_tt_files_by_block Warning!');
   return;
end%if
nWaveforms = length(t);
% The extra column will index which Waveforms belong to wich file.
t = [t(:), zeros(nWaveforms,1)];
% Get a random list of Waveforms
rnd_idx = randperm(nWaveforms);
nFiles = ceil((nWaveforms*(1+Overlap))/(nWaveforms_per_file));
if nFiles == 1
    error('Only one file needs to be created. No need to split.')
end

% Label each Waveform with its destination file name (in second column)
for file_id = 1:nFiles
    t(rnd_idx(file_id:nFiles:nWaveforms),2) = file_id;
end
  
for file_id = 1:nFiles
  nUniqueWaveforms = length(t(find(t(:,2)==file_id),1));
  switch overlap_method
  case 'all_data'
    not_in_this_file = t(find(t(:,2)~=file_id),:);
  case 'adjacent'
    if file_id == nFiles
      % Overlap the last with the first.
      file_to_choose = 1;
    else
      file_to_choose = file_id+1;
    end
    % find waveforms that aren't in this particular file (for choosing overlap)
    not_in_this_file = t(find(t(:,2) == file_to_choose),:);
  otherwise
    error('Incorrect parameter');
  end
  
  
  n_overlap_waveforms = round(nUniqueWaveforms*Overlap);
  rnd_idx_2 = randperm(length(not_in_this_file(:,1)));
  overlap_t = not_in_this_file(rnd_idx_2(1:n_overlap_waveforms),:);
  overlap_t(:,2) = file_id;
  % Shame on me. Inefficient. This accumulates all of the overlapping spikes.
  t = [t;overlap_t];
  fprintf('%g ',file_id)
end
fprintf('\n')
clear overlap_t;
clear rnd_idx_2;

% Sort these two matrices by time
t = sortrows(t);
% Save the files
for file_id = 1:nFiles
   fnameout = fullfile(fdir, [fname 'b' num2str(file_id) '.tt']);
   disp(['Writing ' fnameout])
   idx = find(t(:,2)==file_id);
   % The new LoadTT0_nt.
   [rnd_idx,wv] = LoadTT0_nt(TTname,t(idx,1),1);
   WriteTT0(fnameout,rnd_idx,wv);
   
end



nSpikes = length(t);
nSpikesPerExtendedBlock = floor(nSpikesPerBlock*(1+Overlap));
nBlocks = ceil(nSpikes/nSpikesPerBlock);


for ii=1:nFiles
   fnameout = fullfile(fdir, [fname 'b' num2str(ii) '.tt']);
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
