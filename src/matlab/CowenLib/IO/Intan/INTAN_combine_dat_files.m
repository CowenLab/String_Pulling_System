function INTAN_combine_dat_files(files_to_combine,out_file)
% function INTAN_combine_dat_files(files_to_combine,out_file)
% INPUT: 
%
% 1) cell array of the path/.dat files you would like to combine.
% 2) path/name of the output file you want.
% 
%   e.g., files_to_combine{1} = 'C:\Temp\aaaCh01.dat';
%         files_to_combine{2} = 'C:\Temp\aaaCh05.dat';
%
% out_file = 'C:\Temp\outname01';
% 
% OUTPUT: 
%    a .dat file that has all data combined where each sample is interleaved in order..
%    a .csv file that lists each original file name. This helps with record
%    keeping since such information is not present in the combined int16
%    file.
%  
% This function assumes that you have enough computer memory to load all files at
% once. This also assumes that you are only combining int16 files  - like
% the analog data files - you may be able to put a digital input in there
% as well - not sure as those are UNSIGNED. 
%
% IN SPIKE2: Recall that you need to select the
% correct number of channels when you load this into Spike2
% this is saved in the combined file name.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021 (updated significantly and tested in Spike2)
%
% TODO: verify that it works with DIN files. If not, make it work. read unit16 if
% the filename has a DIN in it, save as an int16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    error('INPUT 2: must supply a full path and filename for the output file');
end

% Create the full name for the output file.
full_out_file = [out_file '_int16_nCh_' num2str(length(files_to_combine)) '.dat'];
f_in = zeros(1,length(files_to_combine));
% open the files - get file pointers
for iF = 1:length(files_to_combine)
    f_in(iF) = fopen(files_to_combine{iF},'r');
end

D = int16([]);
% Read the data files.
% TODO: If user passes in an empty file, then replace the data with all
% zeros.
for iF = 1:length(files_to_combine)
    D(iF,:) = fread(f_in(iF),'int16');
    fclose(f_in(iF));
end
% Write the combined file
f_out = fopen(full_out_file,'w');
fwrite(f_out,D(:),'int16');
fclose(f_out);

% Create a CSV for easy record keeping since the channel info is lost when
% loading into Spike2 as no such info in the .dat file.
fp = fopen(strrep(full_out_file, '.dat', '_channel_list.csv'),'w');
fprintf(fp,'file_name, row_order, ntrode_id, is_sorted, output_spike_file, responsive, notes\n');
for ii = 1:length(files_to_combine)
    [~, file_name] = fileparts(files_to_combine{ii});
    fprintf(fp,'%s, %d,,,,,\n',file_name, ii);
end
fclose(fp);
