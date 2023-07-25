function Batch_process_propagate(function_name, processing_directory_list, control_directory)
%function Batch_process_propagate(function_handle, processing_directory_list, control_directory)
%
% This function works in conjunction with Batch_process_listen.
% Batch_process_listed just waits around, periodically checking the
% control_directory. When a text file appears (e.g. Rat01_20.txtbat) it then renames this to Rat01_20.processing 
% and then starts processing on this directory, running the funcion specified in function_handle in this directory.
% Batch_process_propagate just propagates all of these text files to this
% directory. For example, if you have a dataset with 300 separate
% data directories, Batch_process_propagate will send 300 .txt files to
% this directory. When completed, the file is renamed with .completed at
% the end. 
% If you want a single machine to run multiple processes at once, spawn
% multiple versions of Batch_process_listen and it will run many jobs.
%
% Use a centralized file server for everythign - that way all files will be
% aggregated seamlessly if you use dropbox to synchronize the .m files. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0
    % For testing
    function_name = 'ones'; % just plots a one
    control_directory =  'C:\Temp\Ctrl';
    processing_directory_list = {'a/b/x1' 'c/d/x2' 'e/f/x3'};
end

%%
if ~exist(control_directory,'dir')
    mkdir(control_directory)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a list of text files with the function and directory used for
% analysis.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iF = 1:length(processing_directory_list)
    [p,n] = fileparts(processing_directory_list{iF});
    [p2,n2] = fileparts(p);
    out_name = [n2 '_' n '_' function_name '.txtbat'];
    full_out_fname = fullfile(control_directory,out_name);
    fp = fopen(full_out_fname,'w');
    fprintf(fp,'%s\t%s\n',function_name,processing_directory_list{iF});
    fclose(fp);
end

disp([num2str(length(processing_directory_list)) ' Batch files created in ' control_dir '.'])
