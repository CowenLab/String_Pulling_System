function m = day_log(daylog_path_and_file)
%function m = day_log(daylog_dir)
% Summarizes the minutes worked on different things today
%  in a bar graph.
%
% Inspired by: Quicklogger
%  http://lifehacker.com/software/capture-tools/geek-to-live-quicklog-your-
%  work-day-189772.php
%
% 2006 Stephen Cowen

% Where the log file is located
if nargin == 0
    % Set your logfile directory HERE
    daylog_dir = fullfile(database_dir,'Worklog');
    d = dir(fullfile(daylog_dir,'*.log'));
    for ii = 1:length(d)
        m(ii) = datenum(d(ii).date);
    end
    [mx,idx] = max(m); % The most recent file.
    daylog_path_and_file = fullfile(daylog_dir,d(idx).name);
end

% Format of the file.
%  At present it assumes that the second column is the HH:MM:SS
%  and the final column is the project name.
%   - Modify this depending on the format of your log file.
fomat_of_file = '%s%s%s'; % My simpler format.
%fomat_of_file = '%s%s%s%s%s'; % QuickLoggerPlus format

% Find the most recent file.

% Open the file and read the columns
fp = fopen(daylog_path_and_file,'r');
output = textscan(fp,fomat_of_file,'delimiter','\t');
fclose(fp);
% Find the duration of each task
n = datenum(output{1});
dur_days = [diff(n) ; 0];
dur_hours = dur_days*24;
dur_mins = dur_hours*60;
%% categories of tasks
cats{1} = output{end};
cats{2} = output{end-1};
% generate the statistics.
for ii = 1:2
    figure
    [gs nm] = grpstats(dur_hours,cats{ii},{'sum' 'gname'});
    for inm = 1:length(nm)
        lc = min([12 length(nm{inm})]);
        nm{inm} = nm{inm}(1:lc);
    end
    % make the plot
    barh(gs)
    set(gca,'YTickLabel',nm,'FontSize',8)
    set(gca,'YTick',1:length(gs))
    xlabel('Hours')
    title('Hours Per Project Today')
    box off
end