function E = EP_Data_Structure(varargin);
%function E = EP_Data_Structure(varargin);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT nothing = you get an empty EP structure
% with 2 args, ist is an existing structure. Second is an option. 'validate' validates the current record.
%
% Returns a structure of evoked potentials. 
% The responses must come from a continuous source like EEG or binned spike trains.
% It is assumed that all of the data is aligned
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0
    E.Orignal_data_file = [];  % The original CSC file from which this data was gathered.
    E.Channel_Num = [];        % The recording channel number.
    E.Channel_ID = [];         % The recording channel text ID.
    E.Data = [];               % A matrix where each row is a trial, each column is a point in time.
    E.Trial_start_end_usec = []; % ntrial x 2 matrix that has the start and end of each trial.
    E.Stimulus_trial_type_interval_ms = []; % n trialtypexstimtype X 4 matrix. col1 trial type, col2 stim ID, col3 col4 start and end of stim in msec.
    E.Stimulus_desc = [];     % a cell array from 1:nstimuli that describes each stimulus.
    E.X_axis_msec = [];       % The x axis of the PETH.
    E.sFreq = [];             % The sampling frequency of the data.
    E.Event_Timestamps_usec{1} = []; % Timestamps for each event. 
    E.Event_idx{1} = [];      % The column number in E.Data that corresponds to event {1}. 
    % There may be other events so multiple values are permitted.
    E.Event_description{1} = ''; % Description of the event
    E.Trial_type = [];        % A matrix, n trial rows and n_categories columns that specifies the particular event,
    % for instance, an error trial, an omission trial, trial type 1, etc....
    % You can have multiple columns as there may be multiple categories of responses.
    E.Trial_description{1} = []; % A description of each ID (column), e.g. Ommission_trial, light_tone, tone_light, CS1,etc...
    E.Specific_trial_desc{1} = []; % n trial types by n specific trial category cell array of text descriptions of each trial (eg. 'Rewarded' 'Not Rewarded' )
    E.xyz_from_Bregma_um = [nan nan nan]; % Coordinates of x y and z of the electrode (Bregma).
    % and second columns are the start and end of that event. Keep both the same if it is just a single event.
    E.User_defined_events_desc = {''}; % text descriptions of each event (row) in User_defined_events_usec
    E.Notes = '';
    E.About = ['EP data structure created by EP_Data_Structure.m, cowen(2004) on ' date ] ;
    a = which('EP_Data_Structure');
    E.Source_Code = textread(a,'%s','delimiter','\n','whitespace',''); % Stores this code with the data so that you know what created this file.
elseif nargin == 2
    switch varargin{2}
    case 'validate'
        E = 1;
        % validate an existing EP record to ensure it is correct. Return 0 if not correct, 1 if it is correct.
        % Just checks to see if the field has been filled.
        T = EP_Data_structure;
        fnm = fieldnames(T);
        for ii = 1:length(fnm)
            if isempty(getfield(varargin{1},fnm{ii}))
                disp([fnm{ii} ' IS EMPTY.'])
                E = 0;
            end
        end
        if isempty(varargin{1}.Event_Timestamps_usec)
            disp(['Event_Timestamps_usec IS EMPTY.'])
            E = 0;
        end
        if isempty(varargin{1}.Trial_description)
            disp(['Trial_description IS EMPTY.'])
            E = 0;
        end
        if isnan(sum(varargin{1}.xyz_from_Bregma_um))
            disp(['xyz_from_Bregma_um IS NOT COMPLETE.'])
            E = 0;
        end

        if E == 1
            disp('Valid EP record')
        end
    otherwise
    end
end