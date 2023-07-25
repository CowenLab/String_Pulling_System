function ST = ST_Data_Structure(varargin);
%function ST = ST_Data_Structure(varargin);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT nothing = you get an empty EP structure
% with 2 args, ist is an existing structure. Second is an option. 'validate' validates the current record.
%
% Returns a structure of evoked potentials. 
% The responses must come from a continuous source like EEG or binned spike trains.
% It is assumed that all of the data is aligned
%
% This should be saved in the EVT file. This along with the raw data should be all that you need.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0
    % A stimulus does not have to be confined to a single stimulus. It could also be a trial type (predictive vs. non predictive, rewarded vs non-rewarded. It is up 
    % to the experimenter and the question. (also, Foil or not foil). Granted, there will be a lot of 
    % overlap, but that is the nature of the beast.
    ST.Stimulus{1}.ID = [];   % A unique ID. 
    ST.Stimulus{1}.Name = [];   % name of the stimulus (for instance, Rewarded Trials, Predictive Trial Type 1...
    ST.Stimulus{1}.Description = [];  % Specific description of the stimulus or trial typST.
    ST.Stimulus{1}.Notes = [];  % General notes about the stimulus or the protocol.
    ST.Stimulus{1}.Start_end_ts_usec = []; % ntrials x 2 matrix of start and end times for these trials in the original data.
    ST.Protocol = []; % Description of the experimental protocol
    ST.Notes = '';    % General notes about this channel or recording session
    ST.About = ['EP data structure created by EP_Data_Structure.m, cowen(2004) V1.0 on ' date ] ;
    a = which('EP_Data_Structure');
    ST.Source_code = textread(a,'%s','delimiter','\n','whitespace',''); % Stores this code with the data so that you know what created this file.
elseif nargin == 2
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
            if isempty(varargin{1}.Stimulus{1}.Start_end_ts_usec)
                disp(['Stimulus{' num2str(ii) '}.Start_end_ts_usec IS EMPTY.'])
                ST = 0;
            end
            if isempty(varargin{1}.Stimulus{1}.Name)
                disp(['Stimulus{' num2str(ii) '}.Name IS EMPTY.'])
                ST = 0;
            end
        end

        if ST == 1
            disp('Valid EP record')
        end
    otherwise
    end
end