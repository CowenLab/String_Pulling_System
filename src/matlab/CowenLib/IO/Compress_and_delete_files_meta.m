function Compress_and_delete_files_meta()
stuff_to_compress = {'*.dat'};
% stuff_to_compress = {'*.dat' '*.pos' '*.ncs' '*.spikes' '*.ntt' '*.nst' '*.nvt' '*time*.dat'  '*.pvd' '*.smrx'  '*.nrd'};
% stuff_to_delete = {'*.fd' '*klg.1' '*.fet.1'  '*.fet.1.zip' '*.klg.1.zip'};
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % delete stuff that should just be deleted.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for ii = 1:length(stuff_to_delete)
%       file_list = FindFiles(stuff_to_delete{ii});
%       for jj = 1:length(file_list)
%           delete(file_list{jj})
%           disp(['Deleted ' file_list{jj}])
%       end
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPRESS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii = 1:length(stuff_to_compress)
      file_list = FindFiles(stuff_to_compress{ii});
      Compress_and_delete_files(file_list)
end

