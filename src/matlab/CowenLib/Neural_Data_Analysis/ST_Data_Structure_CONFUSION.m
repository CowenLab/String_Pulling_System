function [ST, B] = ST_Data_Structure(varargin);
%function ST = ST_Data_Structure(varargin);
% Yes, this is essentially an object with out the hassle of matlab objects.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT nothing = you get an empty EP structure
% with 2 args, ist is an existing structure. Second is an option. 'validate' validates the current record.
% [ST, T] = ST_Data_Structure(ST, 'get','FullTrial') - gets all ST with the
%     given text in the name. T is the combined matrix of all of the
%     timestamps
% structuree records with FullTrail in the name.
% Returns a structure of evoked potentials. 
% The responses must come from a continuous source like EEG or binned spike trains.
% It is assumed that all of the data is aligned
%
% This should be saved in the EVT file. This along with the raw data should be all that you need.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ST = [];, B = [];
if nargin == 0
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % A stimulus does not have to be confined to a single stimulus. It could also be a trial type (predictive vs. non predictive, rewarded vs non-rewarded. It is up 
    % to the experimenter and the question. (also, Foil or not foil). Granted, there will be a lot of 
    % overlap, but that is the nature of the beast.
    % PERHAPS I SHOULD GET RID OF THE METADATA AND JUST ASSUME IT"S AN ARRAY OF STIMULI. THIS WOULD SIMPLIFY THINGS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ST.Stimulus{1}.Name = [];   % name of the stimulus (for instance, Rewarded Trials, Predictive Trial Type 1...
    ST.Stimulus{1}.Start_end_ts_usec = []; % ntrials x 2 matrix of start and end times for these trials in the original data.
    ST.Stimulus{1}.Description = [];  % (optional) Specific description of the stimulus or trial typST.
    ST.Stimulus{1}.Notes = [];  % (optional) General notes about the stimulus or the protocol.
    ST.Protocol = []; % Description of the experimental protocol This field is ignored
    ST.Notes = '';    % General notes about this channel or recording session
    ST.About = ['EP data structure created by ST_Data_Structure.m, cowen(2004) V1.0 on ' date ] ;
    a = which('EP_Data_Structure');
    ST.Source_code = textread(a,'%s','delimiter','\n','whitespace',''); % Stores this code with the data so that you know what created this file.
elseif nargin >= 2
    switch varargin{2}
    case 'validate'
        ST = 1;
        % validate an existing EP record to ensure it is correct. Return 0 if not correct, 1 if it is correct.
        % Just checks to see if the field has been filled.
        T = ST_Data_structure;
        fnm = fieldnames(T);
        for ii = 1:length(fnm)
            if isempty(getfield(varargin{1},fnm{ii}))
                disp([fnm{ii} ' IS EMPTY.'])
                ST = 0;
            end
        end
        disp([num2str(length(varargin{1}.Stimulus)) ' Stimuli detected.'])
        for ii = 1:length(varargin{1}.Stimulus)
            fprintf('%i %s, ', ii, varargin{1}.Stimulus{ii}.Name)
            if isempty(varargin{1}.Stimulus{ii}.Start_end_ts_usec)
                disp(['Stimulus{' num2str(ii) '}.Start_end_ts_usec IS EMPTY.'])
                ST = 0;
            end
            if isempty(varargin{1}.Stimulus{ii}.Name)
                disp(['Stimulus{' num2str(ii) '}.Name IS EMPTY.'])
                ST = 0;
            end
        end
        fprintf('\n')

        if ST == 1
            disp('Valid ST record.')
        end
    case 'get'
        % ST_Data_structure(ST,'get','CS')
        ST = ST_Data_structure;
        count = 1;
        for ii = 1:length(varargin{1}.Stimulus)
            if findstr(varargin{3}, varargin{1}.Stimulus{ii}.Name)
                ST.Stimulus{count} = varargin{1}.Stimulus{ii};
                count = count + 1;
            end
        end
    case {'merge' 'union'}
        % Merges the stimuli (indicated by a cell array of stimulus names) into 
        % one stimulus.
        if nargin ~= 3
            error('Wrong number of parameters (ST,''merge'',cell_array)')
        end
        ST = ST_data_structure;
        ST.Name = 'MergedStimuli';
        if isstr(varargin{3})
            % If a single string is passed in, then merge all records that contain that string.
            for ii = 1:length(varargin{1})
                if findstr(varargin{3},varargin{1}{ii}.Name)
                    ST.Start_end_ts_usec = [ST.Start_end_ts_usec; varargin{1}{ii}.Start_end_ts_usec];
                end
            end
        else
            % If a cell array is passed in, assume the user only wants exact matches with the passed in records.
            for ii = 1:length(varargin{1})
                for jj = 1:length(varargin{3})
                    if strcmp(varargin{3}{jj},varargin{1}{ii}.Name)
                        ST.Start_end_ts_usec = [ST.Start_end_ts_usec; varargin{1}{ii}.Start_end_ts_usec];
                    end
                end
            end
        end
        %ST.Start_end_ts_usec = sortrows(ST.Start_end_ts_usec);
        % Only return the unique event times in case there is some overlap
        ST.Start_end_ts_usec = unique(ST.Start_end_ts_usec,'rows'); 
    case {'intersect'}
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Requires you to specify two stimulus NAMES in a cell array.
        % Return the stimulus times in ST1 that contain the times specified in ST2.
        % It also adds some additional fields, namely the offset of the second ST from the first
        % As well as the original timestamps of the second ST.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if iscell(varargin{3})
            count = 1;
            for ii = 1:length(varargin{3})
                tmp = ST_Data_structure(varargin{1},'intersect',varargin{3}{ii});
                if ~isempty(tmp{1}.Offset_of_ST2)
                    ST{count} = tmp;
                    fprintf('%s\t%i\t%i\n',ST{count}{1}.Name, ST{count}{1}.Start_end_ts_usec(1,1),ST{count}{1}.Start_end_ts_usec(1,2) )
                    count = count + 1;
                end
            end
        else
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Recall, the delay after S2 is relative to the off time of S1, not the start of the trial
            % as a result, you NEED to pass in the T_big that starts with the off time of S1.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            tmp = ST_Data_structure;
            ST = tmp.Stimulus;
            ST{1}.Offset_of_ST2 = [];
            ST{1}.ST2_Start_end_ts_usec = [];
            ST{1}.Notes = 'Offset_of_ST2 is the time in timestamps from the first ST to the second. ST2_Start_end_ts_usec are teh original timestamps of the second ST';
            if isnumeric(varargin{1})
                % The user just passed in a matrix of start and end times.
                T_big = varargin{1};
                Name1 = ['stim1'];
            else
                % user passed in an ST structure.
                T_big = varargin{1}.Start_end_ts_usec;
                ST{1}.Description = ['Intersection between ' varargin{1}.Name ' and ' varargin{3}.Name  ];
                Name1 = varargin{1}.Name;
                %if strcmp(varargin{3}.Name,varargin{1}.Name)
                %    % return if the two stimuli are the same.
                %    return
                %end
            end
            T_small = varargin{3}.Start_end_ts_usec;


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            for rr = 1:Rows(T_big)
                idx = find(T_small(:,1) >= T_big(rr,1) & T_small(:,2) <= T_big(rr,2));
                idx = idx(:);
                if ~isempty(idx)
                    ST{1}.Name = [Name1 '_and_' varargin{3}.Name ];
                    ST{1}.Start_end_ts_usec = [ST{1}.Start_end_ts_usec ; T_big(idx,:) ];
                    ST{1}.Offset_of_ST2 = [ST{1}.Offset_of_ST2; T_small(idx,1) - T_big(rr,1) T_small(idx,2) - T_big(rr,1)];
                    ST{1}.ST2_Start_end_ts_usec = [ST{1}.ST2_Start_end_ts_usec ; T_small(idx,:) ];
                end
            end
        end
     case {'get_contained_event_offsets'}
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % INPUT: 1 = master ST (that contains the events)
        %        3 = ST structure that has the sub-events.
        % output: structure that has the event name and the mean offset from the start of the
        % master ST record. This can be used to plot the event times on the PETH plots and the like
        % 
        % Return the offsets of each event in the structure 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if iscell(varargin{3})
            count = 1;
            ST = [];
            for ii = 1:length(varargin{3})
                tmp = ST_Data_structure(varargin{1},'get_contained_event_offsets',varargin{3}{ii});
                if ~isempty(tmp.Offset)
                    ST{count} = tmp;
                    fprintf('%s\t%i\t%i\n',ST{count}.Name, ST{count}.Offset(1,1),ST{count}.Offset(1,2) )
                    count = count + 1;
                end
            end
        else
            % Recall, the delay after S2 is relative to the off time of S1, not the start of the trial
            % as a result, you NEED to pass in the T_big that starts with the off time of S1.
            T_big = varargin{1}.Start_end_ts_usec;
            T_small = varargin{3}.Start_end_ts_usec;
            ST.Offset = [];
            ST.Timestamps = [];
            ST.Name = varargin{3}.Name;
            ST.Description = 'This structure contains the offsets from the start of the target ST structure. This is useful for PETH plots.';
            if strcmp(varargin{3}.Name,varargin{1}.Name)
                % return if the two stimuli are the same.
                return
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            for rr = 1:Rows(T_big)
                idx = find(T_small(:,1) >= T_big(rr,1) & T_small(:,2) <= T_big(rr,2));
                idx = idx(:);
                if ~isempty(idx)
                    ST.Offset = [ST.Offset; T_small(idx,1) - T_big(rr,1) T_small(idx,2) - T_big(rr,1)];
                    ST.Timestamps = [ST.Timestamps ; T_small(idx,:) ];
                end
            end
        end
    case {'save_xml'}
        % Save as xml code.
        
    otherwise
        error('Incorrect parameter')
    end
end