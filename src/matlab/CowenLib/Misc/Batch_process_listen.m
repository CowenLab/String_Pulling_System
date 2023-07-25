function Batch_process_listen(control_directory)
%function Batch_process_listen(control_directory)
%
% Runs indefinitely in the background and checks to see if a new txtbat
% file appeared in the contro_directory. If so, then rename it to
% .processing and start running the process.
% See Batch_process_propagate.m
%
% INPUT: the path to the control directory used for batch processing.
% Should be a NAS drive.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2014
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% for testing
%     control_directory = 'C:\Temp\Ctrl';
processes_run = 0;
fprintf('Batch_process_listen is listening. <o o>\n')
fprintf('                                     ^\n')
fprintf('                                     -\n')

while(true)
    d = dir(fullfile(control_directory,'*.txtbat'));
    if length(d)> 1
        % read the batch processing file.
        fname = fullfile(control_directory,d(1).name);
        fp = fopen(fname);
        C = textscan(fp,'%s');
        fclose(fp);
        fun_name = C{1}{1};
        fun_path = C{1}{2};
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Now that it's loaded, move it to the .processing status
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [p,n] = fileparts(fname);
        fname_processing = fullfile(p,[n '.' round(now)  '.processing'];
        movefile(fname, fname_processing)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Run the program in the target directory.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        cd (fun_path)
        disp(['Starting process in  ' pwd])
        tic
        O = eval(fun_name); % This must wait until completion.
        time_to_complete_s = toc;
        % Completed. Check to see if it failed.
        if time_to_complete_s < 2
            % The process finished far too quickly. Something must be
            % wrong.
            disp(O);
            movefile(fname_processing,fullfile(p,[n,'.error']))
        else
            movefile(fname_processing,fullfile(p,[n,'.completed']))
        end
        disp('Completed process')
        processes_run = processes_run + 1;
        fprintf('.%d',processes_run)
        
        % Perform some maintenance: Check to see if any .processed files
        % have modification dates that are 2 days ago or more. This would
        % indicate that the process has stalled or the computer was shut
        % down before completion (which will often happen). No processing
        % of a single directory should take 2 days. If so, rename it to .txtbat
        % so that it can be started again.
        if 0 % This section is on the to-do list. Will help clean up killed processes - very important.
            d = dir(fullfile(control_directory,'*.processing'));
            % This ispart is a work in process.
            for iD = 1:length(d)
                % get the start datenum string from the filename.
                % Find the periods in the fname and extract the start
                % timestamp. Compare it to now and if it's too long, restart.
                [p,n] = fileparts(d(iD).name);
                [p,n] = fileparts(p);
                n = strrep(n,'.','');
                days = now-str2double(n);
                if days > 2
                    [p,n] = fileparts(p);
                    movefile(fname_processing,fullfile(control_directory,[p,'.textbat']))
                end
            end
        end
    end
    pause(10) % Check every 10 seconds
end