function TPLT = waveform_template(TPLT, operation, val)
% Returns an empty structure of data ready to be filled with template information.
% Poor man's object oriented programming.
% function TPLT = waveform_template(TPLT, operation, val)
%  output: a template structure
%  input: noting-- returns an empty template
%         TPLT -- an existing template.
%         operantion -- some operation to perform on that template (such as plotting)
%         val -- some operation specific value.
% cowen
pts = 32; % assumes this is constant per array of templates.
%
if nargin < 2
    operation = 'add';
end
switch operation
case 'add'
    
    ntemplates = length(TPLT.Name)+1;
    
    TPLT.Name{ntemplates}  = [];            % string with a name for the template.
    TPLT.Stereotaxic_location{ntemplates} = [];         % string with information on the location of the cell that was used to make the template (depth, x,y
    TPLT.File_path_and_name{ntemplates} = [];  % The path and name of the original data file used to create the template.
    TPLT.Notes{ntemplates} = [];            % string with any notes for each template.
    TPLT.Rank(ntemplates) = nan;            % a subjective ranking (1-5) of the quality of each template.
    TPLT.Template_type(ntemplates) = nan;   % There are different types of templates. A value less than one indicates that it is a noise template, for stimulus artifact or something like it. Positive
                                            % values can indicate specific cell types. 
    TPLT.Template_type_lexicon = {'<0 = noise templates','>0 = cell templates'};   % Keeps track of the types of templates. For infomational purposes only.
    TPLT.Channel(ntemplates) = nan; %(ntemplates)             % the channel (val typically from 1 to 4) (can be > 1 if stereo (1 to 2) or tetrodes (1 to 4))
    TPLT.Sampling_rate_Hz(ntemplates)  = nan;  % the sampling rate in Hz.
    TPLT.Alignment_point(ntemplates) = nan;      % this is typically point number 8 for all nlx files
    TPLT.Mean = [TPLT.Mean ; zeros(1,pts)*nan];   % the mean values for each point.
    TPLT.Std   = [TPLT.Std ; zeros(1,pts)*nan];   % the standard_deviation for each point.
    TPLT.Upper_limits_bitvals = [TPLT.Upper_limits_bitvals; zeros(1,pts)*nan];  % This can be converted to Z scores by subtracting the mean and dividing std.
    TPLT.Lower_limits_bitvals = [TPLT.Lower_limits_bitvals; zeros(1,pts)*nan];  
    TPLT.Cov = [ TPLT.Cov; zeros(pts,pts,1)*nan];         % the covariance matrix. If this exists, then the 
    
    % mahalanobis distance is used for template comparison.
case 'delete'
    TPLT.Rank(val) = [];            % a subjective ranking (1-5) of the quality of each template.
    TPLT.Template_type(val) = []; % (ntemplates)     % some templates may be used to filter out noise from the data. A 1 indicates that this template is such 
    %  a template and can be used to throw out bad spikes. A 0 indicates it is a template of a real cell.
    TPLT.Channel(val) = [];         % the channel (val typically from 1 to 4) (can be > 1 if stereo (1 to 2) or tetrodes (1 to 4))
    TPLT.Sampling_rate_Hz(val)  = [];  % the sampling rate in Hz.
    TPLT.Alignment_point(val) = [];      % this is typically point number 8 for all nlx files
    TPLT.Mean(val,:) = [] ;        % the mean values for each point.
    TPLT.Std(val,:) = [];           % the standard_deviation for each point.
    TPLT.Upper_limits_bitvals(val,:) = [];      
    TPLT.Lower_limits_bitvals(val,:) = []; 
    TPLT.Cov(val,:,:) = [];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    count = 1;
    for ii = 1:length(TPLT.Name)
        if ~ismember(ii,val)
            TPLT.Name{count}  = TPLT.Name{ii};       
            TPLT.Stereotaxic_location{count} = TPLT.Stereotaxic_location{ii};
            TPLT.Notes{count} = TPLT.Notes{ii}; 
            TPLT.File_path_and_name{count} = TPLT.File_path_and_name{ii};
            count = count + 1;
        end
    end
    % Remove the straglers
    for ii = count:length(TPLT.Name)
        TPLT.Name{ii}  = [];               % string with a name for the template.
        TPLT.Stereotaxic_location{ii} = [];            % string with information on the location of the cell that was used to make the template (depth, x,y
        TPLT.Notes{ii} = [];               % string with any notes for each template.
        TPLT.File_path_and_name{ii} = [];    
    end
case 'plot'
    % Plot the desired templates
    if nargin == 1
        val = 1:length(TPLT.Name)
    end
    for ii = val
        figure
        plot(TPLT.Mean(ii,:))
        hold on
        plot(TPLT.Mean(ii,:)+TPLT.Std(ii,:),'r:')
        plot(TPLT.Mean(ii,:)-TPLT.Std(ii,:),'r:')
        plot(TPLT.Upper_limits_bitvals(ii,:),'mo')
        plot(TPLT.Lower_limits_bitvals(ii,:),'mo')
        title(TPLT.Name{ii})        
        xlabel([TPLT.Location{ii} TPLT.Description{ii} ])        
    end
   
otherwise
    error('invalid type of operation')
end