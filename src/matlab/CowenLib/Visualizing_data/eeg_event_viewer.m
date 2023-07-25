function eeg_event_viewer(varargin)
%function eeg_event_viewer(varargin)
%
% INPUT:
%     arg 1: 'Passdata'
%     arg 2: event_times_sec (nx2 matrix of start and end times.)
%     arg 3: the data ( a vector of continuous data )
%     arg 4: timestamps for the data. in seconds (must be the same size as
%     the data)
%     arg 5: [space left sec    space right sec] (padding to the left and
%     right of each event).
%     arg 6: sleep stage intervals sec [nx2] (optional) - intervals (start
%     and end times) for different sleep stages.
%     arg 7: sleep interval labels (nx? matrix of string labels for each
%            interval) (optional) - must be one for each row in arg 6
% 
% OUTPUT: An interactive viewer of eeg events with the events marked in
% red.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen (2006) Stephen Cowen, MIT License
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global GP
% Constants:
if nargin==0
    action = 'Init';
elseif isnumeric(varargin{1})
    action = 'Init';
elseif ~isempty(dir(varargin{1}))
    action = 'LoadFile';
else
    action = varargin{1};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main action loop. actions are called by recursive calls to
% this function.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch action
    case 'LoadFile'
        GP.space_left_sec = 1;
        GP.space_right_sec = 1;
    case 'PassData'
        GP.nEventsPerPage = 9;
        GP.event_times_sec = varargin{2};
        GP.nEvents = size(GP.event_times_sec,1);
        GP.signal = varargin{3};
        GP.signal_time_sec = varargin{4};
        GP.sFreq = 1/median(diff(GP.signal_time_sec ));
        GP.space_left_sec = varargin{5}(1);
        GP.space_right_sec = varargin{5}(2);
        if nargin > 5
            GP.stage_intervals_sec = varargin{6};
            GP.stage_labels = varargin{7};
            GP.stage_labels(end) = [];
        else 
            GP.stage_intervals_sec = [];
            GP.stage_labels = [];
        end
        if isempty( GP.event_times_sec)
            error('NO EVENTS!')
        end
        eeg_event_viewer('InitForm'); 

    case 'InitForm'
        GP.page_count = 1;
        GP.main_fh = figure;
        GP.cur_event_idx = 1;
        uicontrol('Parent', GP.main_fh, ...
            'Units', 'Normalized', 'Position', [.0 0 .2 .05], ...
            'Style', 'pushbutton', 'Tag', 'MoveLeft', 'String', 'Back', 'Callback', 'eeg_event_viewer(''MoveLeft'')', ...
            'TooltipString', 'Move to the previous page');
        uicontrol('Parent', GP.main_fh, ...
            'Units', 'Normalized', 'Position', [.21 0 .2 .05], ...
            'Style', 'pushbutton', 'Tag', 'MoveRight', 'String', 'Forward', 'Callback', 'eeg_event_viewer(''MoveRight'')', ...
            'TooltipString', 'Move to the next page');
        uicontrol('Parent', GP.main_fh, ...
            'Units', 'Normalized', 'Position', [.8 0 .2 .05], ...
            'Style', 'pushbutton', 'Tag', 'Exit', 'String', 'Exit', 'Callback', 'eeg_event_viewer(''Exit'')', ...
            'TooltipString', 'Exit');
        set(gcf,'Name','EEG Event Viewer (cowen)')
        eeg_event_viewer('Draw');    
    case 'MoveLeft'
        GP.cur_event_idx = GP.cur_event_idx - 2*GP.nEventsPerPage;
        eeg_event_viewer('Draw');
    case 'MoveRight'
        % Dont have to do anything. This is the default condition.
        eeg_event_viewer('Draw');
    case 'Exit'
        close(GP.main_fh)
    case 'Draw'
        if GP.cur_event_idx < 1
            GP.cur_event_idx = GP.cur_event_idx + GP.nEvents;
        end
        if GP.cur_event_idx > GP.nEvents
            GP.cur_event_idx = 1;
        end
        context_window_start_sec = GP.event_times_sec(GP.cur_event_idx,1) -GP.space_left_sec;
        for ii = 1:GP.nEventsPerPage
            % If the current event is greater than the number of events
            % go to the beginng. 
            if GP.cur_event_idx > GP.nEvents
                GP.cur_event_idx = 1;
            end
            % If the current event is negative (from moving backwards)
            % wrap around to the end.
            if GP.cur_event_idx < 1
                GP.cur_event_idx = GP.cur_event_idx + GP.nEvents;
            end
            page_event_idx(ii) = GP.cur_event_idx;
            subplot(4,3,ii)
            cla
            window_start_sec = round( GP.event_times_sec(GP.cur_event_idx,1) - GP.space_left_sec);
            window_end_sec   = round( GP.event_times_sec(GP.cur_event_idx,2) + GP.space_right_sec);
            dur = ( GP.event_times_sec(GP.cur_event_idx,2) -  GP.event_times_sec(GP.cur_event_idx,1));
            win_ix = [binsearch(GP.signal_time_sec,window_start_sec ): binsearch(GP.signal_time_sec,window_end_sec )];
            evt_ix = [binsearch(GP.signal_time_sec,GP.event_times_sec(GP.cur_event_idx,1) ): binsearch(GP.signal_time_sec,GP.event_times_sec(GP.cur_event_idx,2) )];
            % NOTE: find is much too slow. binsearch is much faster.
            %            win_ix = find(GP.signal_time_sec >window_start_sec & GP.signal_time_sec <window_end_sec);
            %            evt_ix = find(GP.signal_time_sec >GP.event_times_sec(GP.cur_event_idx,1) & GP.signal_time_sec <GP.event_times_sec(GP.cur_event_idx,2));
            plot(GP.signal_time_sec (win_ix),GP.signal(win_ix,:))
            hold on
            plot(GP.signal_time_sec (evt_ix),GP.signal(evt_ix,:),'r')
            %            plot(0,0,'k>')
            %           plot(dur,0,'r<')
            [THMS] = HMS(GP.event_times_sec(GP.cur_event_idx,1) *10000);
            THMS = round(THMS);
            str = [num2str(THMS(1)) ':' num2str(THMS(2)) ':' num2str(THMS(3)) ];
            if ii== 1
                title([num2str(GP.cur_event_idx) ' of ' num2str(size(GP.event_times_sec,1)) '  dur ' num2str(dur) 's ' str])
            else
                title([num2str(GP.cur_event_idx) ' dur ' num2str(dur) 's ' str])
            end
            axis tight
            set(gca,'FontSize',10)
            GP.cur_event_idx = GP.cur_event_idx + 1;
        end
        context_window_end_sec = GP.event_times_sec(GP.cur_event_idx-1,1)+GP.space_right_sec;
        % Plot a context view.
        subplot(4,3,10:12)
        cla
        ix = [binsearch(GP.signal_time_sec,context_window_start_sec ):2:binsearch(GP.signal_time_sec,context_window_end_sec )];
        %        ix = find(GP.signal_time_sec > context_window_start_sec & GP.signal_time_sec < context_window_end_sec );
        %        ix = ix(1:10:end);
        plot(GP.signal_time_sec(ix), GP.signal(ix))
        hold on
        plot(GP.event_times_sec(page_event_idx,1),zeros(1,length(page_event_idx)),'r*')
        axis tight
        patch_intervals(GP.event_times_sec(page_event_idx,:),'c',.2);
        a = axis;
        colors = {'r' 'b' 'g' 'y' 'm' 'c' 'k' 'r' 'b' 'g' 'y' 'm' 'c' 'k' 'r' 'b' 'g' 'y' 'm' 'c' 'k'  };
        u = unique(GP.stage_labels);
        text_pos = a(3) + .2*(a(4) - a(3));
            
        for ii = 1:length(u)
            ix = find_string_in_ca(GP.stage_labels, u{ii});
            patch_intervals(GP.stage_intervals_sec(ix,:),colors{ii},.2);
            text(GP.stage_intervals_sec(ix,1),ones(length(ix),1)*text_pos,GP.stage_labels(ix));
        end
        zoom on
        GP.page_count = GP.page_count + 1;
    otherwise
        error('wierdo command')       
end