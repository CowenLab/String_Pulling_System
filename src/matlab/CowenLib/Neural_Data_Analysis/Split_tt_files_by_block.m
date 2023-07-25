function split_tt_files(TTname,nWaveforms_per_file,Overlap)
% INPUT:
%  TTname: the name of the tt file
%  nWaveforms_per_file : the number of Waveform waveforms per file 
%     filesize in Waveforms = ceil(total_Waveforms/(nWaveforms_per_file +overlap_Waveforms).
%  Overlap: a number from 0-1 indicating the 'percent' overlap between files.
% 
% OUTPUT:
%  ceil(total_Waveforms/(nWaveforms_per_file +overlap_Waveforms).
%
% cowen
% modified from lipa SpitInBlockedTTFiles

[fdir,fname,fext] = fileparts(TTname);
if strcmpi(fname(1:2),'TT')
   t = Waveform_times_from_TT_nt(TTname);
elseif strcmpi(fname(1:2),'ST')
   error('Not implemneted yet')
elseif strcmpi(fname(1:2),'SE')
   error('Not implemneted yet')
else
   warndlg('Only filenames starting with TT are reckognized!!!','split_tt_files_by_block Warning!');
   return;
end%if

nWaveforms = length(t);
% The extra column will index which Waveforms belong to wich file.
t = [t(:); zeros(nWaveforms,1)];
% Get a random list of Waveforms
rnd_idx = randperm(nWaveforms);

nFiles = ceil(nWaveforms/(nWaveforms_per_file));
% Label each Waveform with its destination file name (in second column)
for ii = 1:nFiles
    t(rnd_idx(ii:nFiles:end),2) = ii;
end

% Get Overlap Waveforms and add them.
t_overlap = zeros(nOverlapWaveforms,2);

% Sort these two matrices by time
t = sortrows([t;t_overlap]);
% Save the files
for file_id = 1:nFiles
   fnameout = fullfile(fdir, [fname 'b' num2str(file_id) '.tt']);
   idx = find(t(:,2)==file_id);
   %Write_waveform_from_TT(fname,t(idx,1))
end


