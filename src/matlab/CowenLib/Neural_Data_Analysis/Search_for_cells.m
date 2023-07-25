function Search_for_cells(file_list, template_file, goodness_threshold, min_matches_for_template ,comparison_method, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function Search_for_cells(file_list, template_file, goodness_threshold, min_matches_for_template ,comparison_method, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  This program will look through the specified nlx files and search for 
%  waveforms that are sufficiently close to a library of templates. It will
%  then summarize the ones with the nicest waveforms and plot summary statistics
%  for those waveforms. This is a good way to determine which channels have cells
%  when looking at a very large array of channels. 
%
%  goodness_threshold       : A value from 0 to 1. The higher, the more stringent the criterion.
%
%  comparison_method        : How to compare with the templates. 'mahalanobis', 'dot_product'
%
%  min_matches_for_template : If an integer, this is the minimum number of matches above thresh
%                             in order for it to be classified as a valid cluster.
%                             If a fraction less than 1, this is the percent/100 of points to be considered
%                             to be a valid cluster (e.g. .01 means a valid cluster must have 1% of the total points)
%
%  min_matches_for_template : If an integer, this is the minimum number of matches above thresh
%                             in order for it to be classified as a valid cluster.
%
%
%
%  options: (a cell array of strings)
%   'Match_to_noise' : this option will cause the program to match the waveforms to the 
%                    templates for noise (stim artifact, etc...). The output timestamps
%                    can then be subsequently used to filter out bad data.
%
%   By default, the program outputs a tstxt file (a text file of timestamps) for 
%     each of the identified templates and then, at the end, runs Check_Cluster_from_file
%     one these files. All files are ranked according to how close the cluster
%     was to the closest matching template. As a result, you should get ntemplate X n_nTrode 
%     tstxt files. That's a lot. The name of the text file also contains the rank of that template and 
%     the word 'best' if it is the best match of all of the template.
%     As a result, you can just select those files that are from the best matches and ignore the rest.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  The template file is a .mat file with the following structure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%   Templates can be created from WaveformCutter.  %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  TPLT.Name{ntemplates}                : string with a name for the template.
%  TPLT.Location{ntemplates}            : string with information on the location of the cell that was used to make the template (depth, x,y
%  TPLT.Notes{ntemplates}               : string with any notes for each template.
%  TPLT.IsNoiseTemplate(ntemplates)     : some templates may be used to filter out noise from the data. A 1 indicates that this template is such 
%                                         a template and can be used to throw out bad spikes. A 0 indicates it is a template of a real cell.
%  TPLT.Channel(ntemplates)             : the channel (val typically from 1 to 4) (can be > 1 if stereo (1 to 2) or tetrodes (1 to 4))
%  TPLT.Sampling_rate   : the sampling rate in Hz.
%  TPLT.Peak_point      : this is typically point number 8 for all nlx files
%  TPLT.Means(ntemplates,pts)           : the mean values for each point.
%  TPLT.Std(ntemplates,pts)             : the standard_deviation for each point.
%  TPLT.Cov{ntemplates}(pts,pts)        : the covariance matrix. If this exists, then the 
%                                       : mahalanobis distance is used for template comparison.
%  TPLT.Rank(ntemplates)                : a subjective ranking (1-5) of the quality of each template.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2003
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MAX_POINTS_TO_LOAD = 300000;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse out the options the user may have passed in.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Defaults
Use_noise_templates = 0; 
for ii = 1:length(options)
    switch options{ii}
    case 'Match_to_noise'
        Use_noise_templates = 1;
    otherwise
        error('Invalid option')
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the templates.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load(template_file);

for file_count = 1:length(file_list)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Load the spike data.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    FieldSelection = [1 0 0 0 0];
    ExtractHeader = 0; ExtractMode = 1;
    ModeArray = [ ]; % Get allrecords.
    [SD.spiketimes_usec] =  Nlx2MatSpike( file_list{file_count}, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
    if length(SD.spiketimes_usec) < MAX_POINTS_TO_LOAD
        FieldSelection = [1 0 0 0 1];
        ExtractHeader = 1; ExtractMode = 1;
        ModeArray = [ ]; % Get allrecords.
        [SD.spiketimes_usec ,SD.wv, SD.header] =  Nlx2MatSpike( file_list{file_count}, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
    else
        FieldSelection = [1 0 0 0 1];
        ExtractHeader = 1; ExtractMode = 3;
        ModeArray = [1:MAX_POINTS_TO_LOAD]; % Get allrecords.
        [SD.spiketimes_usec ,SD.wv, SD.header] =  Nlx2MatSpike( file_list{file_count}, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
        clear ModeArray
        pack
        disp(['File over limit, loaded first ' num2str(MAX_POINTS_TO_LOAD) ' points.'])
    end
    [p,n,e] = fileparts(file_list{file_count});
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Change the order of the file to something reasonable and consistent.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if (~isempty(findstr(n,'SE')) | strcmp(e,'.nse'))
        nChannels = 1;
        GP.wv = permute(GP.wv,[3 1 2]);
        GP.wv = reshape(GP.wv,size(GP.wv,1),1,size(GP.wv,2));
    elseif (~isempty(findstr(n,'TT'))| strcmp(e,'.ntt'))
        GP.wv = permute(GP.wv,[3 2 1]);
        nChannels = 4;
    elseif (~isempty(findstr(n,'ST'))| strcmp(e,'.nst'))
        GP.wv = permute(GP.wv,[3 2 1]);
        nChannels = 2;
    else
        error('Could not identify type of electrode file (should have a SE,TT,or ST in the filename.)');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get rid of all points that go over the threshold: Artifact or saturating cells.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ridx,cidx] = find(SD.wv > 2046 || SD.wv < -2046);
    ridx = unique(ridx);
    disp(['Saturation filter: ' num2str(lenght(ridx)) ' points'])
    SD.spiketimes_usec(ridx) = [];
    SD.wv(:,:,ridx) = [];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Iterate through each template.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for tmplt_count = 1:length(TPLT.Name{ntemplates})
        fprintf('.')
        distance_to_template{tmplt_count} = 0; 
        SD.GoodIdx{tmplt_count} = [];
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Multiply by the covariance matrix to determine the distance in stds
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        switch comparison_method
        case 'mahalanobis'
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Better but more memory intensive.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            mean_distance_to_template = []; % A value from 0 to 1. 1 is the mean of the distances of the classified cells to the closest template.
            keeper_template_ID = []; % The ID of the template that most closely matched the target.
            d = mahaldist(squeeze(SD.wv(:,ch,:)),[],inv(TPLT.Cov{tmplt_count}));
            idx = find(d > goodness_threshold);
            if length(d) > min_matches_for_template
                mean_dist = mean(d(idx));
                if mean_dist >best_distance_to_template
                    best_distance_to_template{tmplt_count} = mean_dist;
                    SD.GoodIdx{tmplt_count} = idx;
                end
            end
                
        case 'dot_product'
        otherwise
            error('Incorrect comparison method')
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Write out the best matched spikes to a file.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~isempty(SD.GoodIdx)
        [p,n,ext] = fileparts(file_list{file_count});
        new_name = sscanf( [round(distance_to_template*100) keeper_template_ID n], 'tmatch_d%d_t%d_%s_.tstxt');
        filename = fullfile(p,new_name);
        fp = fopen(filename,'w');
        % The following header attachment is not working!
        if ~isempty(SD.header)
            for ii = 1:length(SD.header)
                fprintf(fp,'\% %s\n',SD.header{ii})
            end
        end
        fprintf(fp,'%.0f\n',SD.spiketimes_usec(sort(SD.GoodIdx)))
        fclose(fp)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print out the waveform data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch ext
case '.nse'
    Check_all_SE_files(pwd, pwd, [], 'tstxt');
otherwise
    disp('No summarizer availiable for this file type yet. Contact Stephen')
end

