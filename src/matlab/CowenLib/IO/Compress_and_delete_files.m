function Compress_and_delete_files(file_list)
%function Compress_and_delete_files(file_list)
% Pass in a list of files and this program will compress each one and then
% delete the original.
% uses zip.
%
% EXAMPLE:
% file_list = findfiles('*.ntt'); % .nst .unt .eeg .pos
% Compress_and_delete_files(file_list)
%
%% Cowen
if nargin == 0
%      file_list = FindFiles('*.spikes');
%       file_list = FindFiles('*.pos');
       file_list = FindFiles('*.dat');
%     file_list = FindFiles('*.ncs');
%     file_list = FindFiles('*.fet.*');
%      file_list = FindFiles('*.smrx');
end


for iF = 1:length(file_list)
    d_orig = dir(file_list{iF});
    out_file = [file_list{iF} '.zip'];
    zip(out_file, file_list{iF})
    % Make sure that it's still there.
    d = dir(out_file);
    disp(['Compressed ' file_list{iF} ' ' num2str(iF) '/' num2str(length(file_list)) ' ' num2str(round(100*d(1).bytes/d_orig(1).bytes)) '%'])
    if d.bytes > 10000
        delete(file_list{iF})
    else
        disp('Compression failed here.')
        %         delete(out_file)
    end
end
