% File loader and pre-processor for the stress studies.
% It assumes there is a cell array of text strings that
% tell it what to load. It must be called what_to_load.
%
% ALL RELEVANT VARIABLES MUST BE DECLARED IN CALLING SCRIPT!
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% On thing that must be loaded...
% The start and end of all of the epochs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Thresholds for removing neurons
[p,name] = fileparts(Ses(dsn).data_dir);
[animal, id] = get_name_id(name);
dset_number = str2num([animal id]);

if ~exist('High_threshold_fq')
    High_threshold_fq = 2.5;
end
if ~exist('Low_threshold_fq')
    Low_threshold_fq = .00;
end
if ~exist('get_rid_of_interneurons')
    get_rid_of_interneurons = 0;
end
if ~exist('smooth_position')
    smooth_position = 1;
end

epoch_times = Load_times(Ses(dsn).data_dir);
riprate = zeros(1,length(epochs_to_load))*nan;
nrips = nan;

for thing_to_load = 1:length(what_to_load)
    
    disp(['Loading ' what_to_load{thing_to_load} '.'])
    
    switch(lower(what_to_load{thing_to_load}))
    case 'neurons'
        if get_rid_of_interneurons
            load_restrictions = 'no_interneuron';
        else
            load_restrictions = []
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % If it's mark's data, load it in differently.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        a_tsl = LoadTsObjects(tsl,fullfile(Ses(dsn).data_dir,'ts_objects','*.mat'), load_restrictions);
        a_tsl = set(a_tsl,'name',name);
        %a_tsl = ScrambleCells(a_tsl);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Restrict by --- really, just look at the maze period. If the firing
        % rate is too high, get rid of the cell.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        badidx = [];
        for flepoch = 2
            r = get(Restrict(a_tsl,epoch_times(flepoch,:)),'firing_rate');
            badidx = [badidx ; find(r > High_threshold_fq | r < Low_threshold_fq)];
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%Q%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Eliminate the naughty cells.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        disp(['File_loader: Removing ' num2str(length(unique(badidx))) ' bad cells.'])
        a_tsl = Remove(a_tsl,badidx);
        for flepoch = epochs_to_load
            tsl_spikes{flepoch} = Restrict(a_tsl,epoch_times(flepoch,:));
            ctsa_spikes{flepoch} = tsl_spikes{flepoch}(1:end); % For legacy code.
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        n_cells = get(a_tsl,'ncells');

    case 'qtsds'
        %tsd_stamps = [];
        for flepoch = epochs_to_load
            R = Range(MakeQfromS(ctsa_spikes{flepoch}, dt_msec*10),'ts');
            Qtsd{flepoch}  = tsd(R,Data(MakeQfromS(ctsa_spikes{flepoch}, dt_msec*10)));
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % tsd_stamps is used to for filtering out times we don't want.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            tsd_stamps{flepoch} = tsd(R,R);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if plotit
                subplot(length(epochs_to_load),1,flepoch)
                bar(Frequency(ctsa_spikes{flepoch}))
                axis tight
                grid on
                title([name ' Firing rate for epoch: ' epochtext{flepoch}]);
                ylabel('Hz')
                xlabel('Neuron')
            end
        end
    case 'event_times'
        [ev.open_door ] = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'),'OPEN_DOOR_GATE');
        [ev.close_door ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'CLOSE_DOOR_GATE');
        [ev.open_curtain ] = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'),'OPEN_CURTAIN_GATE');
        [ev.close_curtain ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'CLOSE_CURTAIN_GATE');
        [ev.pre_feed_tone_door ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'PRE_FEED_TONE_DOOR');
        [ev.pre_feed_tone_curtain ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'PRE_FEED_TONE_CURTAIN');
        [ev.pre_feed_tone_base ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'PRE_FEED_TONE_BASE');
        [ev.fed_base ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'FED_BASE');
        [ev.fed_door ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'FED_DOOR');
        [ev.fed_curtain ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'FED_CURTAIN');
        [ev.door_tone ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'DOOR_TONE');
        [ev.curtain_tone ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'CURTAIN_TONE');
        count_1 = 1;
        count_2 = 1;
        for ii = 1:length(ev.pre_feed_tone_door)
            cd = ev.close_door(find(ev.close_door>ev.pre_feed_tone_door(ii)));
            fd = ev.fed_door(find(ev.fed_door>ev.pre_feed_tone_door(ii)));
            if min(fd)>min(cd)
                ev.pre_feed_tone_door_not_fed(count_1) = ev.pre_feed_tone_door(ii);
                count_1 = count_1 + 1;
            else
                ev.pre_feed_tone_door_fed(count_2) = ev.pre_feed_tone_door(ii);
                count_2 = count_2 + 1;
            end
            
        end
        count_1 = 1;
        count_2 = 1;
        for ii = 1:length(ev.pre_feed_tone_curtain)
            cc = ev.close_curtain(find(ev.close_curtain>ev.pre_feed_tone_curtain(ii)));
            fc = ev.fed_curtain(find(ev.fed_curtain>ev.pre_feed_tone_curtain(ii)));
            if min(fc)>min(cc)
                ev.pre_feed_tone_curtain_not_fed(count_1) = ev.pre_feed_tone_curtain(ii);
                count_1 = count_1 + 1;
            else
                ev.pre_feed_tone_curtain_fed(count_2) = ev.pre_feed_tone_curtain(ii);
                count_2 = count_2 + 1;
            end
            
        end
        count_1 = 1;
        count_2 = 1;
        for ii = 1:length(ev.pre_feed_tone_base)
            t = sort([ev.door_tone(:);ev.curtain_tone(:)]);
            tone = t(find(t>ev.pre_feed_tone_base(ii)));
            fb = ev.fed_base(find(ev.fed_base>ev.pre_feed_tone_base(ii)));
            if min(fb)>min(tone)
                ev.pre_feed_tone_base_not_fed(count_1) = ev.pre_feed_tone_base(ii);
                count_1 = count_1 + 1;
            else
                ev.pre_feed_tone_base_fed(count_2) = ev.pre_feed_tone_base(ii);
                count_2 = count_2 + 1;
            end
        end
        ev.pre_feed_tone_fed = sort([ev.pre_feed_tone_door_fed(:);ev.pre_feed_tone_curtain_fed(:);ev.pre_feed_tone_base_fed(:)]);
        ev.pre_feed_tone_not_fed = sort([ev.pre_feed_tone_door_not_fed(:);ev.pre_feed_tone_curtain_not_fed(:);ev.pre_feed_tone_base_not_fed(:)]);
        
    case 'arm_times'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Determine the start, middle and end times of each traversal of an arm. The best way to do this 
        % appears to be by using the pre-feed tone as a marker and then taking the open_door tone 
        % preceeding this and the close door tone following as the markers for the open and close times.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [open_door ] = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'),'OPEN_DOOR_GATE');
        [pre_feed_tone_door ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'PRE_FEED_TONE_DOOR');
        [close_door ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'CLOSE_DOOR_GATE');
        [open_curtain ] = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'),'OPEN_CURTAIN_GATE');
        [pre_feed_tone_curtain ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'PRE_FEED_TONE_CURTAIN');
        [close_curtain ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'CLOSE_CURTAIN_GATE');
        [pre_feed_tone_base ]  = Extract_from_logfile(fullfile(Ses(dsn).data_dir,'logfile.txt'), 'PRE_FEED_TONE_BASE');
        close_doors = sort([close_curtain;close_door]);
        open_doors = sort([open_curtain;open_door]);
        % Door entry and leaving times.
        enter_door=[];exit_door=[];enter_curtain=[];exit_curtain=[];at_door_feeder=[];at_curt_feeder=[];at_base_feeder=[];
        for ii = 1:length(pre_feed_tone_door)
            
            % Find the open door gate immediately preceding the tone.
            idx = Closest(open_door,pre_feed_tone_door(ii));
            enter_door(ii) = open_door(idx);
            % Find the close_door immediately after the tone.
            idx = Closest(close_door,pre_feed_tone_door(ii));
            exit_door(ii) = close_door(idx(end));
            % Determine when the animal is at the feeder.
            at_door_feeder(ii) = pre_feed_tone_door(ii);
        end
        % curt entry and leaving times.
        for ii = 1:length(pre_feed_tone_curtain)
            % Find the open curt gate immediately preceding the tone.
            idx = Closest(open_curtain,pre_feed_tone_curtain(ii));
            enter_curtain(ii) = open_curtain(idx);
            % Find the close_curt immediately after the tone.
            idx = Closest(close_curtain,pre_feed_tone_curtain(ii));
            exit_curtain(ii) = close_curtain(idx(end));
            % Determine when the animal is at the feeder.
            at_curt_feeder(ii) = pre_feed_tone_curtain(ii);
        end
        % base entry and leaving times.
        for ii = 1:length(pre_feed_tone_base)
            % Find the open curt gate immediately preceding the tone.
            idx = Closest(close_doors,pre_feed_tone_base(ii));
            enter_base(ii) = close_doors(idx(end));
            % Find the close_curt immediately after the tone.
            idx = Closest(open_doors,pre_feed_tone_base(ii));
            exit_base(ii) = open_doors(idx);
            % Determine when the animal is at the feeder.
            at_base_feeder(ii) = pre_feed_tone_base(ii);
        end
        
        if use_journeys_to & use_journeys_return
            % The end time is messy here-- some overlap with the base or curt or door arms.
            door_times = [enter_door(:)   exit_door(:)-10000];
            curt_times = [enter_curtain(:)   exit_curtain(:)-10000];      
            base_times = [enter_base(:)   exit_base(:)+5000];
        elseif use_journeys_to & ~use_journeys_return
            % The start and end times are clean
            door_times = [enter_door(:)   at_door_feeder(:)+3000];
            curt_times = [enter_curtain(:)   at_curt_feeder(:)+3000];
            base_times = [enter_base(:)   at_base_feeder(:)+3000];
        end
    case 'position'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Position data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if fopen(fullfile(Ses(dsn).data_dir,'VT1cleaned.ascii')) ~= -1 
            position = load(fullfile(Ses(dsn).data_dir,'VT1cleaned.ascii')); 
            loaded_cleaned = 1;
        elseif fopen(fullfile(Ses(dsn).data_dir,'VT1.ascii')) ~= -1 
            position = load(fullfile(Ses(dsn).data_dir,'VT1.ascii')); 
            loaded_cleaned = 0;
        elseif fopen(fullfile(Ses(dsn).data_dir,'VT_Raw1.ascii')) ~= -1 
            position = load(fullfile(Ses(dsn).data_dir,'VT_Raw1.ascii')); 
            loaded_cleaned = 0;
        else
            error('Could not open pos file.')
        end
        disp('Loaded pos file')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Having a position of 0,0 is typically an error in tracking so get rid of it.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if ~loaded_cleaned
            position = position(find(position(:,2)~=0),:);
            position = position(find(position(:,3)~=0),:);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            n_pixels = 20; % Eliminate jumps larger than this.
            d = [0; diff(position(:,2))];
            % Find points where the position jumped 30 pixels.
            position = position(find(d<n_pixels),:);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            d = [0; diff(position(:,2))];
            % Do it twice in case their are pairs of points at extremes (happens)
            position = position(find(d<n_pixels),:);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            d = [0; diff(position(:,3))];
            % Find points where the position jumped 30 pixels.
            position = position(find(d<n_pixels),:);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            d = [0; diff(position(:,3))];
            % Find points where the position jumped 30 pixels.
            position = position(find(d<n_pixels),:);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Find double timestamps (can sometimes happen-- don't know why)
            d = [0; diff(position(:,1))];
            position = position(find(d>0),:);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            new_range = round(position(1,1):200:position(end,1))';
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Fill in the gaps left by excluded points.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            xi = interp1(position(:,1),position(:,2),new_range);
            yi = interp1(position(:,1),position(:,3),new_range);
            position = [new_range(:) xi(:) yi(:)];
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            disp('Position data cleaned, saving to VT1cleaned.ascii')
            fid = fopen(fullfile(Ses(dsn).data_dir,'VT1cleaned.ascii'),'w')
            fprintf(fid,'%d \t %d \t %d\n',position');
            fclose(fid)
            clear xi;
            clear yi;
        end
        
        
        for flepoch = epochs_to_load
            x_pos{flepoch} = Restrict(tsd(position(:,1),position(:,2)),epoch_times(flepoch,1),epoch_times(flepoch,2));
            y_pos{flepoch} = Restrict(tsd(position(:,1),position(:,3)),epoch_times(flepoch,1),epoch_times(flepoch,2));
            if smooth_position
                 
                x_pos{flepoch} = Smooth_tsd(x_pos{flepoch},10);
                y_pos{flepoch} = Smooth_tsd(y_pos{flepoch},10);
                
            end
        end
        clear position;
        %pack
        disp('done with position')
        if 0
            nplace_bins = 8;
            for flepoch = maze_epochs
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Plot place fields ALL
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                [TC{flepoch},Occ{flepoch}] = TuningCurves(ctsa_spikes{flepoch}, ...
                    x_pos{flepoch}, nplace_bins, y_pos{flepoch}, nplace_bins);
                NTC{flepoch} = Normalize_TC(TC{flepoch},Occ{flepoch});
                figure;Multi_plot(NTC{flepoch},'imagesc','axis_str','ij');text([0 0], [0 0],name)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Plot place fields Journeys TO
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                [TC{flepoch},Occ{flepoch}] = TuningCurves(ctsa_spikes{flepoch}, ...
%                    Restrict(x_pos{flepoch},[base_times(:,1);door_times(:,1);curt_times(:,1)] ,[base_times(:,2);door_times(:,2);curt_times(:,2)]),...
%                    nplace_bins, Restrict(y_pos{flepoch},[base_times(:,1);door_times(:,1);curt_times(:,1)] ,[base_times(:,2);door_times(:,2);curt_times(:,2)]), nplace_bins);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Plot arm traversals
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                figure;
                plot(Data(x_pos{flepoch}),Data(y_pos{flepoch}),'y.')
                hold on
                plot(Data(Mask(x_pos{flepoch},door_times)),Data(Mask(y_pos{flepoch},door_times)),'r')
                plot(Data(Mask(x_pos{flepoch},curt_times)),Data(Mask(y_pos{flepoch},curt_times)),'g')
                plot(Data(Mask(x_pos{flepoch},base_times)),Data(Mask(y_pos{flepoch},base_times)),'b')
                title([ name ' EPOCH: ' num2str(flepoch)])
                figure;
                
                plot(Data(x_pos{flepoch}),Range(x_pos{flepoch},'ts'),'y')
                hold on
                plot(Data(Restrict(x_pos{flepoch},curt_times(:,1),curt_times(:,2))),Range(Restrict(x_pos{flepoch},curt_times(:,1),curt_times(:,2)),'ts'),'r')
                plot(Data(Restrict(x_pos{flepoch},door_times(:,1),door_times(:,2))),Range(Restrict(x_pos{flepoch},door_times(:,1),door_times(:,2)),'ts'),'g')
                plot(Data(Restrict(y_pos{flepoch},base_times(:,1),base_times(:,2))),Range(Restrict(x_pos{flepoch},base_times(:,1),base_times(:,2)),'ts'),'b')
                title([ name ' EPOCH: ' num2str(flepoch)])
                [SFx SFy] = ScatterFields(ctsa_spikes{flepoch}, x_pos{flepoch},y_pos{flepoch});
                figure;
                plot3(Data(x_pos{flepoch}),Data(y_pos{flepoch}),Range(x_pos{flepoch},'ts'),'k:')
                hold on
                s = get_symbols;
                the_cells = [3 21];
                cnt = 1
                for cellid = the_cells
                    plot3(Data(SFx{cellid}),Data(SFy{cellid}),Range(SFx{cellid},'ts'),s{cellid})
                    leg{cnt} = num2str(cellid);
                    cnt = cnt + 1;
                end
                legend(leg)
                if 0
                    figure;
                    plot(Data(Mask(x_pos{flepoch},door_times)),Range(Mask(x_pos{flepoch},door_times),'sec'),'r.')
                    hold on;
                    plot(Data(Mask(x_pos{flepoch},curt_times)),Range(Mask(x_pos{flepoch},curt_times),'sec'),'g.')
                    plot(Data(Mask(x_pos{flepoch},base_times)),Range(Mask(x_pos{flepoch},base_times),'sec'),'b.')
                    figure
                    plot(Data(Mask(y_pos{flepoch},door_times)),Range(Mask(y_pos{flepoch},door_times),'sec'),'r.')
                    hold on;
                    plot(Data(Mask(y_pos{flepoch},curt_times)),Range(Mask(y_pos{flepoch},curt_times),'sec'),'g.')
                    plot(Data(Mask(y_pos{flepoch},base_times)),Range(Mask(y_pos{flepoch},base_times),'sec'),'b.')
                    
                end
                
                if 0
                    figure;
                    
                    for cellid = 1:ncells
                        subplot(ncells/4,4,cellid)
                        [p,hist_data] = PETH(ctsa_spikes{flepoch}{cellid}, pre_feed_tone_door_times,3000, 10);
                        plot(hist_data);
                        title(num2str(cellid))
                    end
                    subplot(ncells/4,4,1)
                    title(['PETH around DOOR TONE TIMES, EPOCH ' num2str(flepoch)])
                end
            end % Maze epochs
        end % PLOTIT
        
    case 'ripple_times'    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Ripple times. Assumes epoch_times has been loaded.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if fopen(fullfile(Ses(dsn).data_dir,'riptimes.ascii'))~=-1
            all_riptimes = load(fullfile(Ses(dsn).data_dir,'riptimes.ascii'));
        elseif fopen(fullfile(Ses(dsn).data_dir,'riptimes.txt'))~=-1
            all_riptimes = load(fullfile(Ses(dsn).data_dir,'riptimes.txt'));
        else
            disp('WARNING: NO ripple times for this data set.')
            all_riptimes = [];
        end
        
        for flepoch = epochs_to_load
            if ~isempty(all_riptimes)
                riptimes{flepoch} = all_riptimes(find(all_riptimes(:,1)<epoch_times(flepoch,2)&all_riptimes(:,1)>epoch_times(flepoch,1)),:);
                mean_rip_dur(flepoch) = mean(riptimes{flepoch}(:,2)-riptimes{flepoch}(:,1));
                std_rip_dur(flepoch)  = std(riptimes{flepoch}(:,2)-riptimes{flepoch}(:,1));
                nrips(flepoch) = Rows(riptimes{flepoch});
                riprate(flepoch) = nrips(flepoch)/((epoch_times(flepoch,2) - epoch_times(flepoch,1))/10000);

            end
        end
        
    case 'spindle_times'    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Spindle times
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if fopen(fullfile(Ses(dsn).data_dir,'spindles.txt'))~=-1
            all_spindle_times = load(fullfile(Ses(dsn).data_dir,'spindles.txt'));
        else
            all_spindle_times = [];
        end
        for flepoch = epochs_to_load
            if ~isempty(all_spindle_times)
                spindle_times{flepoch} = all_spindle_times(find(all_spindle_times(:,1)<epoch_times(flepoch,2)&all_spindle_times(:,1)>epoch_times(flepoch,1)),:);
                mean_spindle_dur(flepoch) = mean(spindle_times{flepoch}(:,2)-spindle_times{flepoch}(:,1));
                std_spindle_dur(flepoch)  = std(spindle_times{flepoch}(:,2)-spindle_times{flepoch}(:,1));
                nspindles(flepoch) = Rows(spindle_times{flepoch});
            end
        end
    case 'rem_times'    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % REM times
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if fopen(fullfile(Ses(dsn).data_dir,'remtimes.txt'))~=-1
            all_REM_times = load(fullfile(Ses(dsn).data_dir,'remtimes.txt'));
        else
            all_REM_times = [];
        end
        
        % Get rid of bad REM times
        idx = [];
        if ~isempty(all_REM_times)
            idx = find((all_REM_times(:,2) - all_REM_times(:,1))<=0);
            all_REM_times(idx,:) = [];
        end
        
        if ~isempty(idx)
            msgbox([num2str(dsn) ' Had BAD REM TIMES ' ])
        end
        
        for flepoch = epochs_to_load
            if ~isempty(all_REM_times)
                remtimes{flepoch} = all_REM_times(find(all_REM_times(:,1)<epoch_times(flepoch,2)&all_REM_times(:,1)>epoch_times(flepoch,1)),:);
                mean_REM_dur(flepoch) = mean(remtimes{flepoch}(:,2)-remtimes{flepoch}(:,1));
                std_REM_dur(flepoch)  = std(remtimes{flepoch}(:,2)-remtimes{flepoch}(:,1));
                nREMs(flepoch) = Rows(remtimes{flepoch});
            else
                remtimes{flepoch} = [];
            end
        end

    case 'pf_start_and_end_ts'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % PF enter and exit times.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if fopen(fullfile(Ses(dsn).data_dir,'PF_start_and_end_ts.mat'))~=-1
            load(fullfile(Ses(dsn).data_dir,'PF_start_and_end_ts'));
        else
            PF_start_and_end_ts = [];
        end
        for ii = 1:length(PF_start_and_end_ts)
            cellid = clean_PF_start_and_end(PF_start_and_end_ts{ii});
            fprintf('dsn %d cell %d epoch %d.\n', dsn, cellid,ii)
            if ~isempty(cellid)
                error('Bad PF_start and ent time file')
            end
            
        end
    otherwise
        error('incorrect parameter.');
    end
end


