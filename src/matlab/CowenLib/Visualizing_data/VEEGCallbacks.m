function SPTool_wrapperCallbacks()
global GP 
global CONST
CONST.EEG = 1;
CONST.TEXTTIMES = 2;
CONST.TEXTDATA = 3;
CONST.T = 4;
cboHandle = gcbo;                          % current uicontrol handle
figHandle = ParentFigureHandle(cboHandle); % current figure handle

switch get(cboHandle, 'Tag')
case 'LoadEEGFileButton'
    expExtension = 'CR*.dat;CSC*.dat';
    [file_name, the_path] = uigetfile(expExtension, 'EEG file');
    fnTextObj = findobj(figHandle, 'Tag', 'EEGFileName');
    set(fnTextObj, 'String',  file_name);
    if file_name~=0 
        GP.file_count = GP.file_count + 1;
        GP.file_name{GP.file_count} = fullfile(the_path, file_name);
        GP.file_type(GP.file_count) = CONST.EEG;
        
        set_file_parameters(get_file_parameters(figHandle), GP.file_count);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Set the times on the screen to match the times in the file.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [GP.All_timestamps] = nlx2matCSC(GP.file_name{GP.file_count},1,0,0,0,0,0 );
        %[GP.global_start_ts{GP.file_count}, GP.global_end_ts{GP.file_count}, samp_rate, nrecords] =...
        %    ReadCR_get_info(GP.file_name{GP.file_count});
        %error('1')
        GP.TSUnitsInSec = str2num(get(findobj(figHandle, 'Tag', 'TSUnitsInSec'),'String'));
        GP.global_start_ts{GP.file_count} = GP.All_timestamps(1)*GP.TSUnitsInSec;
        GP.global_end_ts{GP.file_count}   = GP.All_timestamps(end)*GP.TSUnitsInSec;
        g = findobj(figHandle, 'Tag', 'GlobalStart');
        set(g, 'String', num2str(GP.global_start_ts{GP.file_count}) );
        
        g = findobj(figHandle, 'Tag', 'GlobalEnd');
        set(g, 'String', num2str(GP.global_end_ts{GP.file_count}) );
        g = findobj(figHandle, 'Tag', 'GlobalStartTs');
        set(g, 'String', num2str(round(GP.global_start_ts{GP.file_count})) );
        
        g = findobj(figHandle, 'Tag', 'GlobalEndTs');
        set(g, 'String', num2str(round(GP.global_end_ts{GP.file_count})) );
        
        
        % If the start times have not been set, set them to the default.
        if GP.start_ts == 0
            g = findobj(figHandle, 'Tag', 'BlockSizeMin');
            blocksize_min = str2num(get(g,'String'));
            
            GP.start_ts = GP.global_start_ts{GP.file_count};
            GP.end_ts   = GP.global_start_ts{GP.file_count}  + blocksize_min*60;
        end
        
        set_times(figHandle);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Load CR data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        load_data_file(figHandle, GP.file_name{GP.file_count}, GP.file_count,0)
        g = findobj(figHandle, 'Tag', 'FileList');
        set(g,'String',str2mat(GP.file_name));
    end
    
case 'LoadTextTimeFileButton'
    if isempty(GP.DATA)
        msgbox('You need to load an EEG datafile first.')
        file_name = 0;
    else
        expExtension =  '*.txt;*rip*.*;*.ascii';
        [file_name, the_path] = uigetfile(expExtension, 'Text file of timestamps file');
    end
    
    if file_name 
        GP.file_count               = GP.file_count + 1;
        GP.file_name{GP.file_count} = fullfile(the_path, file_name);
        GP.file_type(GP.file_count) = CONST.TEXTTIMES;
        set_file_parameters(get_file_parameters(figHandle), GP.file_count);

        load_data_file(figHandle, GP.file_name{GP.file_count}, GP.file_count,0)
    end
    
case 'LoadTextDataFileButton'
    if isempty(GP.DATA)
        msgbox('You need to load an EEG datafile first.')
        file_name = 0;
    else
        expExtension = '*.txt;*.ascii';
        [file_name, the_path] = uigetfile(expExtension, 'Choose the timestamped data file.');
    end
    if file_name 
        GP.file_count               = GP.file_count + 1;
        GP.file_name{GP.file_count} = fullfile(the_path, file_name);
        GP.file_type(GP.file_count) = CONST.TEXTDATA;
        set_file_parameters(get_file_parameters(figHandle), GP.file_count);
        
   
        load_data_file(figHandle, GP.file_name{GP.file_count}, GP.file_count,0)
        g = findobj(figHandle, 'Tag', 'FileList');
        set(g,'String',str2mat(GP.file_name));

    end
 
    
case 'LoadTFileButton'
    if isempty(GP.DATA)
        msgbox('You need to load an EEG datafile first.')
        file_name = 0;
    else
        expExtension = '*.t';
        [file_name, the_path] = uigetfile(expExtension, '.t file');
    end
    
    if file_name~=0 
        GP.file_count               = GP.file_count + 1;
        GP.file_name{GP.file_count} = fullfile(the_path, file_name);
        GP.file_type(GP.file_count) = CONST.T;
        load_data_file(figHandle, GP.file_name{GP.file_count}, GP.file_count,0)
   end
    
case 'MoveForward'
    g = findobj(figHandle, 'Tag', 'BlockSizeMin');
    blocksize_min = str2num(get(g,'String'));
    
    [GP.start_ts, GP.end_ts] = get_times(figHandle);
    % Reset the end ts in case the user changed the blocksize
    GP.end_ts =  GP.start_ts + blocksize_min*60;
    GP.start_ts = GP.start_ts + blocksize_min*60;
    GP.end_ts   = GP.end_ts   + blocksize_min*60;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Load CR data for all the file names in memory. You have to reload all of the data.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set_times(figHandle)
    load_data_file(figHandle,GP.file_name, 1:GP.file_count,1)
case 'GoToCurrentTime'

    [GP.start_ts, GP.end_ts] = get_times(figHandle);
    load_data_file(figHandle,GP.file_name, 1:GP.file_count,1)
    
case 'MoveBackward'
    g = findobj(figHandle, 'Tag', 'BlockSizeMin');
    blocksize_min = str2num(get(g,'String'));
    
    [GP.start_ts, GP.end_ts] = get_times(figHandle);
    
    GP.end_ts =  GP.start_ts + blocksize_min*60;
    GP.start_ts = GP.start_ts - blocksize_min*60;
    GP.end_ts   = GP.end_ts   - blocksize_min*60;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Load CR data for all the file names in memory. You have to reload all of the data.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set_times(figHandle)
    
    load_data_file(figHandle,GP.file_name,1:GP.file_count, 1)
    
case 'CalcRiptimes'
    % Get filename
    m = msgbox('Calculating');
    drawnow
    DATA = Filter_200Hz([GP.TIME(:) GP.DATA(:)], 100, 250, GP.FS(end), GP.FS(end));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Time is no longer valid so erase it to avoid future mistakes.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % [st_ts, et_ts, all,peak_starts, peaks] = Ripple_times(F,threshold,0);
    % Computing peaks is slow! Uses mask.
    g = findobj(figHandle, 'Tag', 'RipThreshold');
    threshold = str2num(get(g,'String'));
    [st, et, all] = Ripple_times(DATA,threshold,0);
    
    DATA = ones(size(DATA,1),1)*-.5;

    if ~isempty(st)
        
        for ii =1:length(st)
            sidx(ii) = binsearch( GP.TIME, st(ii));
            eidx(ii) = binsearch( GP.TIME, et(ii));
        end
        
        DATA(sidx) = .6;
        DATA(eidx) = .75;
    else
        msgbox('no ripples found')
    end
    COMPONENT_NAME = 'Signal';
    GP.LABEL = ['ripple_times' num2str(threshold)];
    SPTool('load',COMPONENT_NAME,DATA,GP.FS(end),GP.LABEL);
    try close(m)
    catch
    end
    
case 'ClearAllVariables'
    s = sptool('Signals');
    for ii = 1:length(s)
        sptool('clear',ii)
    end
case 'Spectragram'
    figure
    specgram(GP.DATA,2^10,GP.FS(end),[]);
    xlabel(['seconds from ' num2str(GP.start_ts) ' to ' num2str(GP.end_ts) ''])
case 'AutoCorr'
    figure
    [xc,lags] = xcorr(GP.DATA,round(GP.FS(end)*5),'coeff');
    plot(lags/GP.FS(end),xc);
    title('Auto Correlation')
    ylabel('r')
    axis tight
    xlabel(['seconds from ' num2str(GP.start_ts) ' to ' num2str(GP.end_ts) ''])
case 'PMTM'
    figure
    m = msgbox('Calculating, please wait...')
    drawnow
    try close(m)
    catch
    end
    pmtm(GP.DATA,[],[],GP.FS(end));
case 'PlotPosition'
    if GP.POSITION == []
        windowsize = 10;
        expExtension = '*.ascii';
        [file_name, the_path] = uigetfile(expExtension, '.ascii position file');
        GP.POSITION = load(fullfile(the_path, file_name));
        GP.POSITION(:,2) = Smooth_vel(GP.POSITION(:,2) ,windowsize);
        GP.POSITION(:,3) = Smooth_vel(GP.POSITION(:,3) ,windowsize);
        GP.POSITION(:,1) = GP.POSITION(:,1)*GP.TSUnitsInSec; % Convert to seconds.
    end
    idx = find(GP.POSITION(:,1) > GP.start_ts & GP.POSITION(:,1)< GP.end_ts);
    figure
    pp = plot3(GP.POSITION(1:100:end,2),GP.POSITION(1:100:end,3),ones(size(GP.POSITION(1:100:end,1)))*GP.start_ts,'k.');
    set(pp,'MarkerSize',3)
    hold on
    plot3(GP.POSITION(idx,2),GP.POSITION(idx,3),GP.POSITION(idx,1),'.r');
    
    title( ['Position data: seconds from ' num2str(GP.start_ts) ' to ' num2str(GP.end_ts) ''])
    xlabel('norm x')
    ylabel('norm y')
    zlabel('sec')
    grid on
    
    figure
    subplot(2,1,1)
    pp = plot(GP.POSITION(1:100:end,1),GP.POSITION(1:100:end,2)+GP.POSITION(1:100:end,3),'k.');
    set(pp,'MarkerSize',3)
    hold on
    plot(GP.POSITION(idx,1),GP.POSITION(idx,2)+GP.POSITION(idx,3),'.-r');

    title( ['Position data: seconds from ' num2str(GP.start_ts) ' to ' num2str(GP.end_ts) ''])
    xlabel('x+y')
    ylabel('sec')
    grid on
    subplot(2,1,2)
    pp = plot(GP.POSITION(1:100:end,1),[0;diff(GP.POSITION(1:100:end,2)+GP.POSITION(1:100:end,3))],'k.');
    set(pp,'MarkerSize',3)
    hold on
    plot(GP.POSITION(idx,1),[0;diff(GP.POSITION(idx,2)+GP.POSITION(idx,3))],'.-r');
    title( ['Velocity: seconds from ' num2str(GP.start_ts) ' to ' num2str(GP.end_ts) ''])
    grid on
otherwise
    disp(get(cboHandle, 'Tag'))
    error('Incorrect option')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper functions.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function M = Timestamp_to_hms(timestamp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert timestamp to hh mm ss format
% Copied directly out of Wilson's iolib.c TimestampToString
%
% INPUT : Vector of timestamps
% OUTOUT matrix of hours min sec(and fractions of seconds)
%
%function s = Timestamp_to_hhmmss(timestamp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cowen Thu Apr 29 09:22:12 1999
hour = floor((timestamp./1e4)./3600) ;
min = floor((timestamp./1e4)./60 - 60.*hour);
sec = timestamp./1e4 - 60.*min - 3600.*hour;
M = [hour min sec]; 
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function M = HMS_to_timestamp(hh,mm,ss)
% Convert hours mins and secs to a timestamp
%
% INPUT : hh, mm, ss
% OUTOUT : a timestamp
%
%function M = HMS_to_timestamp(hh,mm,ss)

% cowen Mon Jul  5 16:03:54 1999
M = hh*60*60*1e4+mm*60*1e4+ss*1e4;
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function T = text_ts(HMS_vector)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% input: vector of [h m s]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = [num2str(HMS_vector(1)) ':' num2str(HMS_vector(2)) ':' num2str(HMS_vector(3))]; 
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function S = Time_string(tstamp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% create a string in HH:MM:SS format 
%
% INPUT: a timestamp
% OUTPUT: a string in HH:MM:SS.ss notation
% 
%function Time_string(tstamp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cowen Sat Apr 10 11:53:23 1999

[ S, Err] = sprintf('%d:%d:%d', round(Timestamp_to_hms(tstamp)));

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function load_data_file(figHandle, file_name, file_idx, reload)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
%    Load in the EEG file or eeg files into memory.
% OUTPUT
%    GP.DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global GP
global CONST
global previous_fname 

if ~iscell(file_name)
    f = file_name;
    clear file_name
    file_name{1} = f;
end

for file_no = 1:length(file_name)
    m = msgbox(['Loading ' file_name{file_no}]);
    drawnow

    DATA = [];
    label_string = [];
    
    switch  GP.file_type(file_idx(file_no))
    case CONST.TEXTTIMES
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Text times. A text file of timestamps
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if fopen(file_name{file_no})~=-1
            all_times = load(file_name{file_no});
        else
            msgbox('Could not open file.')
            all_times = [];
        end
        all_times = all_times * GP.TSUnitsInSec;
        
        DATA = zeros(size(GP.DATA))-.5;
        for ii = 1:size(all_times,2)
            idx = [];
            for jj =1:size(all_times,1)
                idx(jj) = binsearch( GP.TIME,all_times(jj,ii));
            end
            DATA(idx) = DATA(idx) + .8*ii/size(all_times,2);
        end

    case CONST.TEXTDATA
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Determine if this is a text file with multiple columns of data.
        % If so, then load each column separately. Interpolation is performed 
        % by default to make sure points align to each timestamp
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if fopen(file_name{file_no})~=-1
            all_data = load(file_name{file_no});
            
            all_data = all_data(find(all_data(:,1)>= GP.start_ts & all_data(:,1) <= GP.end_ts),: );
        else
            msgbox('Could not open file.')
            all_data = [];
        end
        n_cols_of_data = size(all_data,2);
        GP.ORIGINAL_TIME = all_data(:,1)*GP.TSUnitsInSec;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Perform operations, such as interpolation, on the data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for ii = 2:n_cols_of_data
            DATA{ii-1} = [];
            label_string{ii-1} = [];
            GP.DATA = all_data(:,ii);
            [DATA{ii-1}, label_string{ii-1}] = process_data(figHandle, GP.FS(file_idx(file_no)) );
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if n_cols_of_data ==3
            figure
            plot3(DATA{1},DATA{2},(1:length(DATA{2}))./GP.FS(file_idx(file_no)) ,'.');
            title( ['Position data: seconds from ' Time_string(GP.start_ts) ' to ' Time_string(GP.end_ts) ''])
            xlabel('norm x')
            ylabel('norm y')
            zlabel('sec')
            grid on
        end
   
 
    case CONST.T
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % A binary T file
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        tfp = fopen(file_name{file_no});
        if tfp ~=-1
            ReadHeader(tfp);    
            ttimes = fread(tfp,inf,'uint32');	%read as 32 bit ints            fclose(tfp);
        else
            msgbox('Could not open file.')
            ttimes = [];
        end
        ttimes = ttimes * GP.TSUnitsInSec; % Convert to seconds.
        disp([num2str(length(ttimes)) ' spikes loaded'])
        % These are markers of some sort of event.
          
        for ii =1:length(ttimes)
            tidx(ii) = binsearch(GP.TIME,ttimes(ii));
        end
        DATA = zeros(size(GP.DATA))-1;
        DATA(tidx) = .7;

    case CONST.EEG
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % A binary CR file. Blocked record.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if ~strcmp(previous_fname, file_name{file_no}) | reload
            reload = 0;
            [GP.ORIGINAL_TIME,GP.DATA]=ReadCR_to_matrix(file_name{file_no},GP.start_ts/GP.TSUnitsInSec ,GP.end_ts/GP.TSUnitsInSec);
            %idx = find(GP.All_timestamps > GP.start_ts/GP.TSUnitsInSec & GP.All_timestamps < GP.end_ts/GP.TSUnitsInSec);
            %if ~isempty(idx)
            %    [GP.ORIGINAL_TIME,GP.DATA] = nlx2matCSC(file_name{file_no},1,0,0,0,1,0,GP.All_timestamps(idx));
            %else
               % msgbox('No data')
                %end
            GP.ORIGINAL_TIME = GP.ORIGINAL_TIME * GP.TSUnitsInSec; % Convert to seconds.
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Perform operations, such as interpolation, on the data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [DATA, label_string] = process_data(figHandle,file_idx(file_no));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
    otherwise
        error('unknown type')
    end
    previous_fname = file_name{file_no};

            
    if iscell(DATA)
        COMPONENT_NAME = 'Signal';
        [p,n,e] = fileparts(file_name{file_no});
        for ii = 1:length(DATA)
            GP.LABEL = [n label_string{ii} num2str(ii)];
            
            SPTool('load',COMPONENT_NAME,DATA{ii},GP.FS(file_no),GP.LABEL);
        end
        
    else
        COMPONENT_NAME = 'Signal';
        [p,n,e] = fileparts(file_name{file_no});
        GP.LABEL = [n label_string ];
        SPTool('load',COMPONENT_NAME,DATA,GP.FS(file_no),GP.LABEL);
    end
    
    try close(m)
    catch
    end
    
end

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [st,et] = get_times(figHandle);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get times from the GUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
g = findobj(figHandle, 'Tag', 'StartTime');
tmp = get(g, 'String');
if findstr(':',tmp)
    time_vec = sscanf(tmp,'%f:%f:%f'); 
    st = time_vec(1)*60*60+time_vec(2)*60+time_vec(3);
else
    st = str2num(tmp);
end    

g = findobj(figHandle, 'Tag', 'EndTime');
tmp = get(g, 'String');
if findstr(':',tmp)
    time_vec = sscanf(tmp,'%f:%f:%f'); 
    et = time_vec(1)*60*60+time_vec(2)*60+time_vec(3);
else
    et = str2num(tmp);
end    

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function set_times(figHandle)
global GP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set the GUI times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

g = findobj(figHandle, 'Tag', 'StartTime');
set(g, 'String', num2str(GP.start_ts) );

g = findobj(figHandle, 'Tag', 'EndTime');
set(g, 'String', num2str(GP.end_ts) );

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P = get_file_parameters(figHandle)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get file parameters from the GUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global GP
P.Filter7Hz = get(findobj(figHandle, 'Tag', 'Filter7Hz'),'Value');
P.Filter200Hz = get(findobj(figHandle, 'Tag', 'Filter200Hz'),'Value');
P.Interpolate = get(findobj(figHandle, 'Tag', 'Interpolate'),'Value');
P.Normalize = get(findobj(figHandle, 'Tag', 'Normalize'),'Value');
P.Shift = get(findobj(figHandle, 'Tag', 'Shift'),'Value');
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function  set_file_parameters(P, idx)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set parameters in the global variable (not the GUI)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global GP
GP.Filter7Hz(idx) = P.Filter7Hz ;
GP.Filter200Hz(idx) = P.Filter200Hz; 
GP.Interpolate(idx) = P.Interpolate ;
GP.Normalize(idx) = P.Normalize ;
GP.Shift(idx) = P.Shift ;

return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DATA, label_string] = process_data(figHandle, file_idx)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do processing on the data such as filtering or interpolation.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global GP
label_string = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the real sampling frequency for this load
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

GP.FS(file_idx) = length(GP.ORIGINAL_TIME)/((GP.ORIGINAL_TIME(end)-GP.ORIGINAL_TIME(1)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update the start and end times to what was read from the file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GP.start_ts = GP.ORIGINAL_TIME(1);
GP.end_ts   = GP.ORIGINAL_TIME(end);
% Redo the time to assume the points are equally spaced-- even though this may not be the case.
% Interpolation is safer.
GP.TIME = linspace(GP.start_ts,GP.end_ts,length(GP.DATA));



if GP.Interpolate(file_idx)
    % It is critical that ORIGINAL_TIME is used here.
    % Get the start and end time from the GUI. Iterpolate from there.
    [GP.start_ts, GP.end_ts] = get_times(figHandle);
    GP.FS(file_idx) = str2num(get(findobj(figHandle, 'Tag', 'InterpFq'),'String'));
    npoints = round(((GP.end_ts - GP.start_ts)) * GP.FS(file_idx));
    GP.TIME = linspace(GP.start_ts,GP.end_ts,npoints);
    GP.DATA = interp1(GP.ORIGINAL_TIME,GP.DATA,GP.TIME);
    GP.ORIGINAL_TIME = GP.TIME;
    f = find(isnan(GP.DATA));
    mn = mean(GP.DATA(find(~isnan(GP.DATA))));
    m = msgbox(['Found ' num2str(length(f)) ' nans, converting to the mean: ' num2str(mn) '.']);
    GP.DATA(f) = mn;
%    for ii = 1:length(f)
%        if f(ii) == 1
%            GP.DATA(f(ii)) = GP.DATA(f(ii)+1); 
%        elseif f(ii) == length(GP.DATA)
 %           GP.DATA(f(ii)) = GP.DATA(f(ii)-1) ;
 %       else
%            GP.DATA(f(ii)) = GP.DATA(f(ii)+1) ;
%        end
%    end
    label_string = [label_string 'int'];
    try close(m)
    catch
    end
end
DATA = GP.DATA;


if GP.Filter200Hz(file_idx)
    low_rip_fq = str2num(get(findobj(figHandle, 'Tag', 'LowRipFq'),'String'));
    high_rip_fq = str2num(get(findobj(figHandle, 'Tag', 'HighRipFq'),'String'));
    DATA = Filter_200Hz([GP.TIME(:) DATA(:)],  low_rip_fq, high_rip_fq, GP.FS(file_idx), GP.FS(file_idx));
    DATA = DATA(:,2);
    label_string = [label_string 'f200'];
end

if GP.Filter7Hz(file_idx)
    low_7Hz_fq = str2num(get(findobj(figHandle, 'Tag', 'Low7HzFq'),'String'));
    high_7Hz_fq = str2num(get(findobj(figHandle, 'Tag', 'High7HzFq'),'String'));

    DATA = Filter_7Hz([GP.TIME(:) DATA(:)], low_7Hz_fq, high_7Hz_fq, GP.FS(file_idx), GP.FS(file_idx));
    DATA = DATA(:,2);
    label_string = [label_string 'f7'];
end

if GP.Normalize(file_idx)
    DATA = DATA-mean(DATA);
    % Should we be doing the divide by the max thing?
    DATA = DATA./max(abs(DATA));
    label_string = [label_string 'norm'];
end

if GP.Shift(file_idx)
    DATA = DATA+GP.file_count-1;
    label_string = [label_string 'shift'];
end

return