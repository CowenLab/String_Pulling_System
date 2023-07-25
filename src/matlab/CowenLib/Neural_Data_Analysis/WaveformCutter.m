function WaveformCutter(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WaveformCutter(arg 1, arg 2)
%
% INPUTS
%    arg 1: waveform data 3D matrix (sample x n channels x 32)
%    arg 2: good channels = which channels are good.
%  OR
%    arg 1: a filename -- a Neuralynx waveform file (SE, TT, ST). Must have SE, TT, or ST in the name.
%    arg 2: (optional) a list of timestamps to load.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 9/27/02 scowen@email.arizona.edu V1.0 Contact for suggestions, help, modifications, etc...
% to do:
%  Load in and create custom templates.
%  Allow cutting on distance to templates. Compare mahalanobis to distance to mean.
%  Use linear discriminant to allow users to separate the current set of
%  points from another.
%
%  Modified internally so that all timestamps are initially converted to seconds. it makes everything
%  later updates much easier.
%  UNDID THE ABOVE MODIFICATION: found that converting to decimal did
%  result in lost data. You wouldn't load all of the original spikes if you
%  converted from sec back to 10th of msec. REALLY! As a result, times are
%  now in usec.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% update the Z waveform cutter subdirectory
%
global GP SB
format long g

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
        [p,n,e] = fileparts(varargin{1});
        GP = [];
        GP.Params = [];
        GP.CurrentCluster = 1;

        if nargin == 1
            % LOAD THE WAVEFORMS
            FieldSelection = [1 0 0 1 1];
            ExtractHeader = 1; ExtractMode = 1;
            ModeArray = [ ]; % Get allrecords.
            [GP.spiketimes_usec , GP.Params, GP.wv, GP.header] =  Nlx2MatSpike( varargin{1}, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
            GP.Params = GP.Params';
            if (~isempty(findstr(n,'SE')) | strcmp(e,'.nse'))
                %[GP.spiketimes_usec , GP.Params, GP.wv, GP.header] = nlx2matSE(varargin{1},1,0,0,1,1,0);
                ch = [1 0 0 0 ];
                GP.wv = permute(GP.wv,[3 1 2]);
                GP.wv = reshape(GP.wv,size(GP.wv,1),1,size(GP.wv,2));
            elseif (~isempty(findstr(n,'TT'))| strcmp(e,'.ntt'))
                %    [GP.spiketimes_usec , GP.wv] = nlx2matTT(varargin{1},1,0,0,0,1,0);
                GP.wv = permute(GP.wv,[3 2 1]);
                ch = [1 1 1 1 ];
            elseif (~isempty(findstr(n,'ST'))| strcmp(e,'.nst'))
                %   [GP.spiketimes_usec , GP.wv] = nlx2matST(varargin{1},1,0,0,0,1,0);
                GP.wv = permute(GP.wv,[3 2 1]);
                ch = [1 1 0 0 ];
            else
                error('Could not identify type of electrode file (should have a SE,TT,or ST in the filename.)');
            end
        else
            if length(varargin{2}) == 1
                % LOAD THE TIMESTAMPS
                FieldSelection = [1 0 0 0 0];
                ExtractHeader = 1; ExtractMode = 1;
                ModeArray = [ ]; % Get allrecords.
                [times_to_load, GP.header] =  Nlx2MatSpike( varargin{1}, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
                nspikes_to_load = varargin{2};
                %times_to_load = nlx2matSE(varargin{1},1,0,0,0,0,0);
                r = randperm(length(times_to_load));
                times_to_load = unique(times_to_load(r(1:nspikes_to_load)));
            else
                times_to_load = varargin{2};
            end
            disp(['Loading in a subsample of ' num2str(length(times_to_load)) ' points'])
            % LOAD IN A SUBSAMPLE OF THE SPIKES
            FieldSelection = [1 0 0 1 1];
            ExtractHeader = 0; ExtractMode = 5;
            %[GP.spiketimes_usec, GP.Params, GP.wv]=  Nlx2MatSpike( varargin{1}, FieldSelection, ExtractHeader, ExtractMode, times_to_load );
            [GP.spiketimes_usec, GP.Params, GP.wv,GP.header]=  Nlx2MatSE( varargin{1}, 1,0,0,1,1,1, times_to_load );
            %
            clear times_to_load
            GP.Params = GP.Params';

            if (~isempty(findstr(n,'SE')) | strcmp(e,'.nse'))
                %[GP.spiketimes_usec , GP.Params, GP.wv] = nlx2matSE(varargin{1},1,0,0,1,1,0,times_to_load);
                %GP.Params = GP.Params';
                GP.wv = permute(GP.wv,[3 1 2]);
                GP.wv = reshape(GP.wv,size(GP.wv,1),1,size(GP.wv,2));
                ch = [1 0 0 0 ];
            elseif (~isempty(findstr(n,'TT'))| strcmp(e,'.ntt'))
                %[GP.spiketimes_usec , GP.wv] = nlx2matTT(varargin{1},1,0,0,0,1,0,times_to_load);
                GP.wv = permute(GP.wv,[3 2 1]);
                ch = [1 1 1 1 ];
            elseif (~isempty(findstr(n,'ST'))| strcmp(e,'.nst'))
                %[GP.spiketimes_usec , GP.wv] = nlx2matST(varargin{1},1,0,0,0,1,0,times_to_load);
                GP.wv = permute(GP.wv,[3 2 1]);
                ch = [1 1 0 0 ];
            else
                error('Could not identify type of electrode file (should have a SE,TT,or ST in the filename.)');
            end
        end
        if isempty(GP.wv)
            error('File is empty or could not load.')
        end
        % If there is a file of Coincidence timestamps in the same
        % directory, load it and filter these timestamps out of the main file.
        cfile = fullfile(p,['Coincident_' n '.tstxt']);
        if exist(cfile)
            coincident_ts = load(cfile);
            [goodtimes,goodidx] = setdiff(GP.spiketimes_usec,coincident_ts);
            GP.spiketimes_usec = GP.spiketimes_usec(goodidx);
            GP.Params = GP.Params(goodidx,:);
            GP.wv  = GP.wv(goodidx,:,:);
            disp (['deleted ' num2str(length(coincident_ts)) ' coincident spikes'])
            clear coincident_ts goodtimes goodidx;
            pack
        end

        nfile = fullfile(p,['Noise_' n '.tstxt']);
        if exist(nfile)
            out=questdlg('Would you like to remove template matched noise waveforms?', ...
                'Noise', ...
                'Yes','No','Yes');
            if strcmp(out,'Yes')
                noise_ts = load(nfile);
                [goodtimes,goodidx] = setdiff(GP.spiketimes_usec,noise_ts);
                GP.spiketimes_usec = GP.spiketimes_usec(goodidx);
                GP.Params = GP.Params(goodidx,:);
                GP.wv  = GP.wv(goodidx,:,:);
                disp (['deleted ' num2str(length(noise_ts)) ' noise spikes'])
                clear noise_ts goodtimes goodidx;
                pack
            end
        end

        GP.header_struct = Read_nlx_header(GP.header);
        try
            GP.sFreq = GP.header_struct.SamplingFrequency;
        catch
            GP.sFreq = GP.header_struct.SCRate;
        end
        GP.WaveFile = varargin{1};
        GP.ClustNum = [];
        GP.TemplateFilename = [];
        GP.IdxToMaster = [];
        GP.GoodChannels = find(ch == 1);
        for ch = GP.GoodChannels
            GP.limits{GP.CurrentCluster}{ch} = [];
        end
        % GP.wv = GP.wv .* GP.header_struct.ADBitVolts * 1e6; % Convert to uVolts.
        WaveformCutter; % Convert times to seconds.

        return

    case 'Init'
        % First time the function is called, init stuff

        if nargin == 0 % Called internally (user specified a file to load.)
            disp('Called from command line')
        else % Called from MClust
            GP = [];
            GP.CurrentCluster = 1;
            GP.spiketimes_usec = varargin{1}*100;
            GP.WaveFile = [];
            GP.Params = [];
            GP.header = [];
            GP.header_struct = [];
            FieldSelection = [0 0 0 0 0];
            ExtractHeader = 1; ExtractMode = 1;
            ModeArray = [ ]; % Get allrecords.
            try
                global MClust_TTfn
                [GP.header] =  Nlx2MatSpike( ['../' MClust_TTfn], FieldSelection, ExtractHeader, ExtractMode, ModeArray );
                GP.header_struct = Read_nlx_header(GP.header);
                try
                    GP.sFreq = GP.header_struct.SamplingFrequency;
                catch
                    GP.sFreq = GP.header_struct.SCRate;
                end
                disp(['Sampling at : ' num2str(GP.sFreq)])
            catch
                disp('Could not load the header from the tt file.')
                GP.sFreq = 32000; 
            end
            % Unknown sampling frequency. Try reading the header. If not,
            % presume 32000.
            
            GP.TemplateFilename = [];
            GP.wv = varargin{2};
            GP.ClustNum = varargin{4};
            GP.IdxToMaster = varargin{5};
            GP.GoodChannels = find(varargin{3} == 1);
            for ch = GP.GoodChannels
                GP.limits{GP.CurrentCluster}{ch} = [];
            end
        end

        GP.Colors = {'b' 'g' 'r' 'w' 'm' 'c' 'y'};
        GP.nClusters = 1;
        GP.pts = 4:26; % These are the points on the waveform to consider.
        GP.tmp = []; % A spare global.
        GP.ShowSD = 0;
        GP.ShowClust = 0;
        GP.ShowShadow = 0;
        GP.ShowMClustAvgWV = 0;
        GP.transform_methods = {'Raw values','sin(x)/x','x^2', 'Z','subtract mean','stdPC 1','stdPC 2','stdPC 3'};
        GP.drawtype_str = {'line','randomized points','interpolated','interpoints'};
        GP.read_file_type_str = {'t','ntt/nse/nst/dat','tstxt','nts','Event .tstxt', 'Limits .lim','Template'};
        GP.write_file_type_str = {'t','txt','SE','TT','Limits .lim','Template'};
        GP.Dimension_string = {'PC1','PC2','PC3','Energy','Width','pt on wave','template','parameter'};
        GP.eval_str = 'draw_wv = squeeze(GP.wv(GP.DrawIdx,GP.CurrentChannel,:));';
        GP.DrawWaveformType = 'line';
        GP.EventTimestamps_sec = [];
        GP.GoodIdx{GP.CurrentCluster} = 1:size(GP.wv,1);
        GP.PrevGoodIdx{GP.CurrentCluster}  = [];
        GP.nPoints     = 500;
        GP.CurrentChannel = GP.GoodChannels(1);
        GP.Linear_discriminant_wt{1} = [];
        GP.time_fg = [];
        GP.cut_time_fg = [];
        GP.fg = figure;
        % r = randperm(length(GP.GoodIdx{GP.CurrentCluster}));
        % nPoints = min([GP.nPoints length(r)]);
        GP.DrawIdx = []; %r(1:nPoints);
        % Load in the templates, if they exist.
        SB = Spike_DB('normalize_by_sFreq', GP.sFreq);
        if ~isempty(SB)
            disp(['Found ' num2str(length(SB.ID)) ' saved templates'])
        end

        set(GP.fg,'Position',[180 160 800 550]);
        GP.figHandle = Init_form(GP.GoodChannels);
        disp('Clearing and packing')
        clear varargin;
        pack

        WaveformCutter('DrawWaveforms')

    case 'AddCluster'
        GP.nClusters = GP.nClusters + 1;
        GP.GoodIdx{GP.nClusters}= GP.GoodIdx{GP.CurrentCluster};
        for ch = GP.GoodChannels
            GP.limits{GP.nClusters}{ch} = GP.limits{GP.CurrentCluster}{ch};
        end
        GP.PrevGoodIdx{GP.nClusters} = [];
    case 'Cluster'
        % % % % % % % % % % % % % % % % % % % %
        if GP.CurrentCluster < GP.nClusters
            GP.CurrentCluster = GP.CurrentCluster + 1;
        else
            GP.CurrentCluster = 1 ;
        end

        set(gcbo,'String',[ 'Clst ' num2str(GP.CurrentCluster) '/' num2str(GP.nClusters)]);

        WaveformCutter('DrawWaveforms')

    case 'Channel'
        idx = find(GP.GoodChannels == GP.CurrentChannel);
        if idx == length(GP.GoodChannels)
            GP.CurrentChannel = GP.GoodChannels(1);
        else
            GP.CurrentChannel = GP.GoodChannels(idx + 1);
        end

        set(gcbo,'String',num2str(GP.CurrentChannel));
        WaveformCutter('DrawWaveforms')
    case 'DrawWaveformType'
        GP.DrawWaveformType = GP.drawtype_str{get(gcbo,'Value')};
        WaveformCutter('DrawWaveforms')
    case 'ShowSD'
        GP.ShowSD = get(findobj(GP.figHandle,'Tag','ShowSD'),'Value');
        WaveformCutter('DrawWaveforms')
    case 'ShowClust'
        GP.ShowClust = get(findobj(GP.figHandle,'Tag','ShowClust'),'Value');
        WaveformCutter('DrawWaveforms')
    case 'ShowShadow'
        GP.ShowShadow = get(findobj(GP.figHandle,'Tag','ShowShadow'),'Value');
        WaveformCutter('DrawWaveforms')
    case 'DrawWaveforms'
        figure(GP.fg);
        clf
        r = randperm(length(GP.GoodIdx{GP.CurrentCluster}));
        GP.DrawIdx = sort(GP.GoodIdx{GP.CurrentCluster}(r(1:min([GP.nPoints length(r)]))));
        % Eval creates the draw_wv variable from the transform.
        eval(GP.eval_str);
        if isempty(draw_wv)
            msgbox('Nothing to draw!')
            return
        end

        if GP.ShowShadow
            badidx = setxor(GP.GoodIdx{GP.CurrentCluster},1:length(GP.spiketimes_usec));
            if ~isempty(badidx)
                r = randperm(length(badidx));
                npts = min([200 length(badidx)]);
                plot(1:32,squeeze(GP.wv(r(1:npts),GP.CurrentChannel,:)),'Color',[.1 .1 .1])
                hold on
            end
        end

        if GP.ShowClust
            for ii = 1:length(GP.GoodIdx)
                if ii ~= GP.CurrentCluster
                    pidx = randperm(length(GP.GoodIdx{ii}));
                    pidx = pidx(1:min([200 length(pidx)]));
                    if ~isempty(pidx)
                        plot(1:32,squeeze(GP.wv(GP.GoodIdx{ii}(pidx),GP.CurrentChannel,:)),GP.Colors{ii})
                    end
                    hold on
                    % Plot overlapping points in white.
                    overlapping_idx = intersect(GP.GoodIdx{GP.CurrentCluster},GP.GoodIdx{ii});
                    overlapping_idx = overlapping_idx(1:min([100 length(overlapping_idx)]));
                    if ~isempty(overlapping_idx)
                        plot(1:32,squeeze(GP.wv(overlapping_idx,GP.CurrentChannel,:)),'w')
                    end
                end
            end
        end

        switch GP.DrawWaveformType
            case 'line'
                plot(draw_wv')

            case 'randomized points'
                plot([repmat(1:32,length(GP.DrawIdx),1)+rand(length(GP.DrawIdx),32)-.5]' ,draw_wv','g.','MarkerSize',1)

            case 'interpolated'
                xlim = 512;
                wvi = interp1([1:32]',draw_wv',linspace(1,32,xlim),'spline')';
                plot(linspace(1,32,xlim),wvi')

            case 'interpoints'
                xlim = 512;
                wvi = interp1([1:32]',draw_wv',linspace(1,32,xlim),'spline')';
                plot(linspace(1,32,xlim),wvi','g.','MarkerSize',1)

        end
        a = axis;

        %prc = prctile(squeeze(GP.original_wv(:,GP.CurrentChannel,:),ones(1,32)*90);
        if GP.ShowSD
            sd = std(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:)));
            mn = mean(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:)));
            hold on
            plot(1:32,mn + 2*sd,':g','LineWidth',2)
            plot(1:32,mn - 2*sd,':g','LineWidth',2)
            % Percentiles are better but slower to calculate.
            %plot(1:32,prctile(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:)),95),':g','LineWidth',2)
            %plot(1:32,prctile(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:)),5),':g','LineWidth',2)
            plot(1:32,mn,'-g','LineWidth',3)
        end
        if GP.ShowMClustAvgWV
            global MClust_Colors
            hold on
            for ii = 1:length(GP.mWV)
                if ~isempty(GP.mWV{ii})
                    plot( GP.mWV{ii}(GP.CurrentChannel,:),'LineWidth',4, 'Color', MClust_Colors(ii + 1,:));
                    %plot( GP.mWV{ii}(GP.CurrentChannel,:),'LineWidth',4, 'Color', MClust_Colors(ii + 1,:));
                    %errorbar(GP.mWV{ii}(GP.CurrentChannel,:),GP.sWV{ii}(GP.CurrentChannel,:)) %,'blue');
                end
            end
        end

        set(gca,'Color',[0 0 0])
        set(gca,'YColor','b')
        set(gca,'XColor','b')
        axis([1 32  a(3) a(4)])
        set(gca,'Position',[0.08 0.05 0.90 0.85]) % [0.13 0.11 0.775 0.815]
        if ~isempty(GP.limits{GP.CurrentCluster}{GP.CurrentChannel})
            hold on

            h = line(GP.limits{GP.CurrentCluster}{GP.CurrentChannel}(:,[1 1])',GP.limits{GP.CurrentCluster}{GP.CurrentChannel}(:,[2 3])');
            set(h,'LineStyle',':')
            set(h,'Color','w')
            %for ii = 1:size(GP.limits{GP.CurrentCluster}{GP.CurrentChannel},1)
            %    h = line(GP.limits{GP.CurrentCluster}{GP.CurrentChannel}(ii,[1 1]),GP.limits{GP.CurrentCluster}{GP.CurrentChannel}(ii,[2 3]));
            %    set(h,'LineStyle',':')
            %    set(h,'Color','w')
            %end
            hold off
        end
        zoom on
        title([GP.WaveFile ' ' num2str(length(GP.DrawIdx)) ' of ' num2str(length(GP.GoodIdx{GP.CurrentCluster})) ' Waveforms displayed, ' num2str(size(GP.wv,1)) ' Original Waveforms'])
    case 'ShowAllChannels'

        f = figure;
        set(f,'Position', [710 180 150 550])

        mx = max(max(max(GP.wv(GP.DrawIdx,:,:))));
        mn = min(min(min(GP.wv(GP.DrawIdx,:,:))));
        for ii = 1:length(GP.GoodChannels)
            subplot(length(GP.GoodChannels),1,ii)
            h=plot(squeeze(GP.wv(GP.DrawIdx,GP.GoodChannels(ii),:))');
            axis tight
            a = axis;
            axis([a(1) a(2) mn mx])
            set(gca,'Color','k')
            set(gca,'FontSize',8)
            title(['Ch' num2str(GP.GoodChannels(ii))])

        end

    case 'ShowMClustAvgWV'
        global MClust_TTData MClust_Clusters MClust_FeatureData
        global MClust_Colors


        GP.ShowMClustAvgWV = get(findobj(GP.figHandle,'Tag','ShowMClustAvgWV'),'Value');

        run_avg_waveform = 1;
        for ii = 1:length(MClust_Clusters)

            f = FindInCluster(MClust_Clusters{ii}, MClust_FeatureData);

            if length(f) > 0
                if run_avg_waveform
                    clustTT = ExtractCluster(MClust_TTData, f);
                    [GP.mWV{ii} GP.sWV{ii}] = AverageWaveform(clustTT);
                end
            else
                GP.mWV{ii} = [];
                GP.sWV{ii} = [];
            end
        end
        WaveformCutter('DrawWaveforms')

    case 'DrawTime'
        if isempty(GP.time_fg)
            GP.time_fg = figure;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            set (GP.time_fg,'Position',[20 50 1100 120]);
        else
            figure(GP.time_fg);
        end
        plot(GP.spiketimes_usec/1e6, squeeze(GP.wv(:,GP.CurrentChannel,8)), 'y.', 'MarkerSize', 2)
        hold on
        plot(GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster})/1e6, squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,8)), 'b.', 'MarkerSize', 2)
        plot(GP.spiketimes_usec(GP.DrawIdx)/1e6, squeeze(GP.wv(GP.DrawIdx,GP.CurrentChannel,8)), 'r.', 'MarkerSize', 2)
        axis tight
        a = axis;
        a(3) = 0;
        ylabel('Peak')
        xlabel('Time (sec)')
        legend('All','InCluster','Displayed')
        axis(a);

        figure(GP.fg);

    case 'CutOnTimeAndPeak'
        if isempty(GP.cut_time_fg)
            GP.cut_time_fg = figure;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            set (GP.cut_time_fg,'Position',[20 50 1100 300]);
        else
            figure(GP.cut_time_fg);
            clf
        end
        PeakVals = squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,8));
        PeakTimes = GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster})/1e6;
        plot(GP.spiketimes_usec/1e6, squeeze(GP.wv(:,GP.CurrentChannel,8)), 'b.', 'MarkerSize', 2)
        hold on
        plot(PeakTimes, PeakVals, 'g.', 'MarkerSize', 2)
        plot(GP.spiketimes_usec(GP.DrawIdx)/1e6, squeeze(GP.wv(GP.DrawIdx,GP.CurrentChannel,8)), 'r.', 'MarkerSize', 2)
        axis tight
        ylabel('Peak')
        xlabel('Time (sec)')
        title('Click on points that specify the BOTTOM of the cluster and press ENTER')
        [xB,yB] = ginput;
        % Add the first and last timestamped point to these data.
        xB = [PeakTimes(1); xB ;PeakTimes(end)];
        yB = [yB(1); yB ;yB(end)];

        [x,idx] = sort(xB);
        plot(xB(idx),yB(idx),'b','LineWidth',4)
        title('Click on points that specify the TOP of the cluster and press ENTER')
        [xT,yT] = ginput;
        xT = [PeakTimes(1); xT; PeakTimes(end)];
        yT = [yT(1); yT; yT(end)];

        [x,idx] = sort(xT);
        plot(xT(idx),yT(idx),'m','LineWidth',4)
        % Limit the points to be within these boundaries.
        yiB = interp1(xB,yB,PeakTimes);
        yiT = interp1(xT,yT,PeakTimes);
        plot(PeakTimes,yiB,'b:','LineWidth',5)
        plot(PeakTimes,yiT,'m:','LineWidth',5)

        GP.PrevGoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster};

        GP.GoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster}(find(PeakVals(:) >= yiB(:) & PeakVals(:) <= yiT(:)));
        plot( GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster})/1e6, squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,8)), 'm.' )
        WaveformCutter('DrawWaveforms')
    case 'CutXY'
        dim_str = [];
        dim_str{1} = GP.Dimension_string{get(findobj(GP.figHandle,'Tag','XDim'),'Value')};
        dim_str{2} = GP.Dimension_string{get(findobj(GP.figHandle,'Tag','YDim'),'Value')};
        for ii = 1:2
            lab_str{ii} = dim_str{ii};
            switch(lower(dim_str{ii}))
                case 'pc1'
                    %w{ii} = stdPC(1)'*squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:))';
                    w{ii} = stdPC(1)'*e_norm(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:)))';
                case 'pc2'
                  %  w{ii} = stdPC(2)'*enorm(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:)))';
                    w{ii} = stdPC(2)'*e_norm(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:)))';
                case 'pc3'
                    %w{ii} = stdPC(3)'*squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:))';
                    w{ii} = stdPC(3)'*e_norm(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:)))';
                case 'energy'
                    w{ii} = sqrt(sum(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:))'.^2))';
                case 'pt on wave'
                    answer=inputdlg({'Which point on the waveform?'},'Dimension Selection',1,{'8'});
                    if ~isempty(answer)
                        pt = str2num(answer{1});
                        if pt < 33
                            w{ii} = GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,pt);
                        else
                            msgbox('Invalid range, using defualt of 8')
                            w{ii} = GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,8);
                        end
                        lab_str{ii} = [dim_str{ii} ' ' num2str(pt)];
                    end
                case 'parameter'
                    answer=inputdlg({'Which parameter(1-8)?'},'Dimension Selection',1,{'1'});
                    pt = str2num(answer{1});
                    if pt >8 & pt < 1
                        msgbox('Parameters must be between 1 and 8, defaulting to 1')
                        pt = 1;
                    end
                    w{ii} = GP.Params(GP.GoodIdx{GP.CurrentCluster},pt);
                    lab_str{ii} = [dim_str{ii} ' ' num2str(pt)];
                case 'template'
                    answer=inputdlg({'Which template?'},'Dimension Selection',1,{'1'});
                    val = str2num(answer{1});
                    wv = squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:));
                    % Energy normalized.
                    if isempty(SB)
                        msgbox('No templates are available. See Spike_DB.m for help.')
                    else
                        %if isnan(squeeze(SB.cov_wv(1,1,val)))
                        % Calculate the dot product.
                        w{ii} =  e_norm(wv)*SB.mean_wv(val,:)';
                        lab_str{ii} = [dim_str{ii} ' ' num2str(val)];
                        % else
                        % Calculate the mahal distance
                        %    w{ii} = mahaldist(wv./(repmat(energy,1,32)), [],squeeze(SB.cov_wv(:,:,ii)));
                        %    lab_str{ii} = [dim_str{ii} ' ' num2str(pt)];
                        %end
                    end
                case 'width'
                    [mn idx_mn] = min(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,9:25))');
                    idx_mn = idx_mn + 8;
                    [mx idx_mx] = max(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,5:9 ))');
                    idx_mx = idx_mx + 4;

                    w{ii} = idx_mx - idx_mn + rand(size(idx_mx));
                    clear mx mn idx_mn idx_mx;
                otherwise
                    error('Unknown dimension')
            end
        end
        GP.cutXYfh = figure;
        uicontrol('Parent', GP.cutXYfh, ...
            'Units', 'Normalized', 'Position', [0 0 .2 .05], ...
            'Style', 'pushbutton', 'Tag', 'CutXYConvexHull', 'String', 'Convex Hull', 'Callback', 'WaveformCutter(''CutXYMakeConvexHull'')', ...
            'TooltipString', 'Make Convex Hull');
        uicontrol('Parent', GP.cutXYfh, ...
            'Units', 'Normalized', 'Position', [.2 0 .2 .05], ...
            'Style', 'pushbutton', 'Tag', 'CutXYDensityPlot', 'String', 'Density', 'Callback', 'WaveformCutter(''CutXYDensityPlot'')', ...
            'TooltipString', 'Make a density plot');
        plot(w{1},w{2},'.','MarkerSize',.1)
        GP.figDataHandle = get(gca,'Children');
        set(GP.figDataHandle,'ZData',GP.GoodIdx{GP.CurrentCluster})
        xlabel (lab_str{1})
        ylabel (lab_str{2})
        zoom on
        % Save memory
        clear w
        pack
    case 'CutXYMakeConvexHull'
        figure(GP.cutXYfh)
        [x,y]=draw_hull;
        h = line([x(1:end-1)';x(2:end)'],[y(1:end-1)';y(2:end)']);
        set(h,'LineWidth',4)
        set(h,'Color',GP.Colors{GP.CurrentCluster})
        f = find(InPolygon(get( GP.figDataHandle,'XData'), get( GP.figDataHandle,'YData'), x, y));
        idx = get( GP.figDataHandle,'ZData');
        % You have to do the line plot afterwards, otherwise the lines add data to the plot.
        GP.PrevGoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster};
        GP.GoodIdx{GP.CurrentCluster}     = idx(f);
        WaveformCutter('DrawWaveforms')

    case 'CutXYDensityPlot'
        figure(GP.cutXYfh)
        mins = [min(get(gca,'Xlim')) min(get(gca,'Ylim')) ];
        maxs = [max(get(gca,'Xlim')) max(get(gca,'Ylim')) ];
        xpts = 150;
        ypts = 150;
        H = ndhist([get(GP.figDataHandle,'XData'); get(GP.figDataHandle,'YData')],[xpts ypts]',mins',maxs');
        H = log(H);
        mn = min(H(find(H>-100)));
        H(find(H < -100)) = mn;
        GP.XYDensity = figure;
        xticks = linspace(mins(1), maxs(1),xpts);
        yticks = linspace(mins(2), maxs(2),ypts);
        imagesc(xticks,yticks,smooth2D(H)');
        axis xy
        % Trying to cut on the density plot. First attempt.
        uicontrol('Parent', GP.XYDensity, ...
            'Units', 'Normalized', 'Position', [0 0 .2 .05], ...
            'Style', 'pushbutton', 'Tag', 'CutXYDensityConvexHull', 'String', 'Convex Hull', 'Callback', 'WaveformCutter(''CutXYMakeConvexHullDensity'')', ...
            'TooltipString', 'Make Convex Hull');

    case 'CutXYMakeConvexHullDensity'
        figure(GP.XYDensity)
        [x,y]=draw_hull;
        h = line([x(1:end-1)';x(2:end)'],[y(1:end-1)';y(2:end)']);
        set(h,'LineWidth',4)
        set(h,'Color',GP.Colors{GP.CurrentCluster})
        f = find(InPolygon(get( GP.figDataHandle,'XData'), get( GP.figDataHandle,'YData'), x, y));
        idx = get( GP.figDataHandle,'ZData');
        % You have to do the line plot afterwards, otherwise the lines add data to the plot.
        GP.PrevGoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster};
        GP.GoodIdx{GP.CurrentCluster}     = idx(f);
        WaveformCutter('DrawWaveforms')

        %axis off
    case 'HistISI'
        figure
        subplot(2,2,1)
        ISI_histogram(GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster})/100);
        %    figure
        %    d_msec = diff(GP.spiketimes_sec(GP.GoodIdx{GP.CurrentCluster})*1e3);
        %    [b,x]=histc(diff(GP.spiketimes_sec(GP.GoodIdx{GP.CurrentCluster})*1e3),0:.5:max(d_msec));
        %    semilogx(log(0:.5:max(d_msec)),b)
        %    bar(0:.5:max(d_msec),b,'histc')
        n_neg = length(find(diff(GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster}))<0));
        n_out = length(find(diff(GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster})/1000)<2));
        n_tot = length(GP.GoodIdx{GP.CurrentCluster});
        ylabel('Count')
        title(['ISI Hist ' num2str(100*n_out/n_tot) '% Spikes < 2ms (' num2str(n_out) '/' num2str(n_tot) '), ' num2str(n_neg) ' neg vals'],'FontSize',10)
        % Something strange is going on with Hist ISI. I see only a couple spikes < 2 but there should be hundreds less than 2.
        % Somehow the plot does not really show the number of spikes in the small range.
        subplot(2,2,2)
        acorr_window_msec = str2num(get(findobj(GP.figHandle,'Tag','ACorrWindowMsec'),'String'));
        acorr_bin_size_msec = str2num(get(findobj(GP.figHandle,'Tag','ACorrBinSizeMsec'),'String'));
        nbins = round(acorr_window_msec/acorr_bin_size_msec);
        [Y, xdim] = CrossCorr(GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster})/100, GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster})/100, acorr_bin_size_msec, nbins);
        Y(find(Y==max(Y)))=nan;
        h = barp(xdim-.5*acorr_bin_size_msec,Y); % subtract .5binsize so that bins are centered on the xlabels
        set(h,'FaceColor','k')
        set(h,'EdgeColor','k')
        a = axis;
        a(3) = min(Y);
        axis(a)
        xlabel('msec')
        ylabel('Rate (Hz)')
        title(['ACorr dt ' num2str(acorr_bin_size_msec) 'msec'],'FontSize',10);
        % Tiem and also plot out the about of overlap with other clusters.
        plot_str = ['overlaps ' ]
        for ii = 1:GP.nClusters
            if ii ~= GP.CurrentCluster
                ninter = length(intersect(GP.GoodIdx{GP.CurrentCluster}, GP.GoodIdx{ii}));
                plot_str = [plot_str num2str(ninter) ' with C' num2str(ii) '  '];
            end
        end
        subplot(2,2,3:4)
        plot(GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster})/1e6, squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,8)), 'b.', 'MarkerSize', 2)
        hold on
        plot(GP.spiketimes_usec(GP.DrawIdx)/1e6, squeeze(GP.wv(GP.DrawIdx,GP.CurrentChannel,8)), 'r.', 'MarkerSize', 2)
        axis tight
        a = axis;
        a(3) = 0;
        ylabel('Peak')
        xlabel('Time (sec)')
        legend('InCluster','Displayed',0)
        title(plot_str)
        axis(a);

    case 'WaveSeries'
        figure
        imagesc(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:))')
        xlabel('Waveform count')

    case 'PETH'
        if isempty(GP.EventTimestamps_sec)
            msgbox('Cannot comply. No event timestamps loaded')
        else
            prompt={'Enter the bin size (msec):','Enter the time before (msec):','Enter the time after (msec):'};
            def={'20','2000','2000'};
            dlgTitle='Input for the PETH plot.';
            lineNo=1;
            answer=inputdlg(prompt,dlgTitle,lineNo,def);
            figure
            PETH_raster(GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster})/1e6,GP.EventTimestamps_sec,str2num(answer{1}),str2num(answer{2}),str2num(answer{3}),3);
            title('Units are in seconds')
        end

    case 'FeaturePlot'
        hvals{1} = [];
        other_hvals{1} = [];
        hvals_range{1} = [];
        other_hvals_range{1} = [];
        labels = [];
        count = 1;
        count2 = 1;
        wv =squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:));

        for pt = [6 8 10 12 15 17 19];
            vals = wv(:,pt);
            [hvals{count}, hvals_range{count}] = hist(vals,150);
            if GP.nClusters > 1 & GP.ShowClust == 1
                for jj = setdiff(1:GP.nClusters,GP.CurrentCluster)
                    vals = squeeze(GP.wv(GP.GoodIdx{jj},GP.CurrentChannel,pt));
                    [other_hvals{count}, other_hvals_range{count}] = hist(vals,150);
                end
            end

            labels{count} = ['Point ' num2str(pt)];
            count = count + 1;
        end
        if ~isempty(GP.Params)
            for pa = [1:size(GP.Params,2)];
                vals = GP.Params(GP.GoodIdx{GP.CurrentCluster},pa);
                [hvals{count}, hvals_range{count}] = hist(vals,150);

                if GP.nClusters > 1 & GP.ShowClust == 1
                    for jj = setdiff(1:GP.nClusters,GP.CurrentCluster)
                        vals = GP.Params(GP.GoodIdx{jj},pa);
                        [other_hvals{count}, other_hvals_range{count}] = hist(vals,150);
                    end
                end

                labels{count} = ['Param ' num2str(pa)];

                count = count + 1;
            end
        end
        %
        % Plot energy and the std pc's
        %
        for ii = 1:3
            [hvals{count}, hvals_range{count}] = hist(stdPC(ii)'*wv',150);
            labels{count} = ['stdPC' num2str(ii)];
            if GP.nClusters > 1 & GP.ShowClust == 1
                for jj = setdiff(1:GP.nClusters,GP.CurrentCluster)
                    % normalize to the unit vector - energy normalization
                    other_wv = squeeze(GP.wv(GP.GoodIdx{jj},GP.CurrentChannel,:));
                    [other_hvals{count}, other_hvals_range{count}] = hist(stdPC(ii)'*e_norm(other_wv)',150);
                end
            end
            % Plot out the pca
            wt{count} = stdPC(ii);
            count = count + 1;
        end
        [hvals{count}, hvals_range{count}] = hist(sqrt(sum(wv'.^2)),150);
        labels{count} = ['Energy'];
        if GP.nClusters > 1 & GP.ShowClust == 1
            for jj = setdiff(1:GP.nClusters,GP.CurrentCluster)
                other_wv = squeeze(GP.wv(GP.GoodIdx{jj},GP.CurrentChannel,:));

                [other_hvals{count}, other_hvals_range{count}] = hist(sqrt(sum(other_wv'.^2)),150);
            end
        end
        % Draw the LD versus all of the non-clustered points.
        count = count + 1;
        if GP.nClusters > 1
            for ii = setdiff(1:GP.nClusters,GP.CurrentCluster)
                other_wv = e_norm(squeeze(GP.wv(GP.GoodIdx{ii},GP.CurrentChannel,:)));
                ewv = e_norm(wv);
                sw			  = cov(ewv) + cov(other_wv);
                GP.Linear_discriminant_wt{count2}  = inv(sw)*(mean(ewv)-mean(other_wv))';
                vals          = GP.Linear_discriminant_wt{count2}'*ewv';
                vals2         = GP.Linear_discriminant_wt{count2}'*other_wv';
                [hvals{count}, hvals_range{count}] = hist(vals,150);
                [other_hvals{count}, other_hvals_range{count}]  = hist(vals2,150);

                wt{count} = GP.Linear_discriminant_wt{count2};
                labels{count} = ['LD ' num2str(count2) ];
                count = count + 1;
                count2 = count2 + 1;
            end
            clear ewv
            pack
        end

        if ~isempty(SB)
            % Stored in SB.mean_wv.
            % Changed all of the above conversions to one line -- saved a LOT of
            ewv = e_norm(wv);
            e_mean_wv = e_norm(SB.mean_wv);
            dot_prod = ewv * e_mean_wv';

            for tcnt = 1:length(SB.ID)
                if ~any(isnan(SB.cov_wv_e_norm(:,:,tcnt)))
                    sw = cov(ewv) + squeeze(SB.cov_wv_e_norm(:,:,tcnt));
                    GP.Linear_discriminant_wt{count2}  = inv(sw)*(mean(ewv)-e_mean_wv(tcnt,:))';
               else
                    GP.Linear_discriminant_wt{count2} = zeros(size(dot_prod(:,tcnt)));
                end
                %vals = GP.Linear_discriminant_wt{count2}'*wv';
                vals = dot_prod(:,tcnt);
                %vals = mahalanobis(wv,other_wv,95);
                [hvals{count}, hvals_range{count}] = hist(vals,150);
                if GP.nClusters > 1 & GP.ShowClust == 1
                    for ii = setdiff(1:GP.nClusters,GP.CurrentCluster)
                        other_wv =e_norm(squeeze(GP.wv(GP.GoodIdx{ii},GP.CurrentChannel,:)));
                        dot_prod_other = other_wv* e_mean_wv';
                    end
                    [other_hvals{count}, other_hvals_range{count}] = hist(dot_prod_other(:,tcnt),150);
                end
                wt{count} = e_mean_wv(tcnt,:);
                labels{count} = ['tplt ' num2str(tcnt) ' type ' num2str(SB.data_type_codes{SB.data_type(tcnt)})];
                count = count + 1;
                count2 = count2 + 1;
            end

            if 0
                if GP.nClusters > 1 & GP.ShowClust == 1
                    for ii = setdiff(1:GP.nClusters,GP.CurrentCluster)
                        other_wv =squeeze(GP.wv(GP.GoodIdx{ii},GP.CurrentChannel,:));
                        GP.Linear_discriminant_wt{count2}  = inv(sw)*(mean(wv)-mean(other_wv))';
                        count2 = count2 + 1;
                        vals2 = mahalanobis(wv,other_wv,95);
                        vals4 = mahalanobis(wv,[wv; other_wv],95);
                        vals3 = mahalanobis(other_wv,wv,95);
                        %spcs = [stdPC(1) stdPC(2) stdPC(3)];
                        %vals3 = mahalanobis([spcs'*wv']',[spcs'*squeeze(GP.wv(GP.GoodIdx{ii},GP.CurrentChannel,:))']',95,0);
                        % My version of mahalanobis works better than
                        % mahal. I don't know why.
                        %vals2 = mahal(wv,squeeze(GP.wv(GP.GoodIdx{ii},GP.CurrentChannel,:)));
                        the_range = linspace(min([vals2(:);vals3(:)]),max([vals2(:);vals3(:)]),150)
                        figure
                        [h1 x1] = histc(vals2,the_range);
                        [h2 x2] = histc(vals3,the_range);
                        [h3 x3] = histc(vals4,the_range);
                        plot(the_range,h1,'b')
                        hold on
                        plot(the_range,h2,'r')
                        plot(the_range,h3,'k')
                        title([' Mahal between clusters of current to PCs' num2str(ii)])
                    end
                end
            end
        end


        wt{count} = [];

        figure
        nrows = 4;
        ncols = ceil((count-1)/nrows);
        for ii = 1:(count-1)
            subplot(nrows,ncols,ii)
            plot(hvals_range{ii},hvals{ii}/sum(hvals{ii}),'b')
            hold on
            if length(other_hvals) >= ii
                if ~isempty(other_hvals{ii})
                    plot(other_hvals_range{ii},other_hvals{ii}/sum(other_hvals{ii}),'g')
                end
            end
            axis tight
            a = axis;
            if ~isempty(wt{ii})
                % Rescale so you can plot on the same plot.
                wt{ii} = wt{ii} + abs(min(wt{ii}));
                wt{ii} = wt{ii}/max(wt{ii});
                wt{ii} = wt{ii}*a(4);

                plot(linspace(a(1),a(2),32),wt{ii},'r:')
            end
            axis off
            title(labels{ii})
        end
    case 'CheckCluster'
        figure
        title('Nope, not implemented yet.')

    case 'Lissajous'
        %figure
        Lissajous(GP.wv(GP.GoodIdx{GP.CurrentCluster},:,:));

    case 'AddLimit'
        figure(GP.fg)
        [x,y] = ginput(2);
        x = round(x(1));
        if min(y)~=max(y) & (min(x) >= 1 | max(x) <= 32)
            GP.limits{GP.CurrentCluster}{GP.CurrentChannel} = [GP.limits{GP.CurrentCluster}{GP.CurrentChannel};x min(y) max(y)]; % Add a limit.
            GP.PrevGoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster};
            GP.GoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster}(find(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,x) < max(y) & GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,x) >= min(y)));
            WaveformCutter('DrawWaveforms')
        else
            msgbox('Upper and lower bounds are equal or out of range (less than 1 or greater than 32). Ignoring.')
        end
    case 'RapidAddLimit'
        figure(GP.fg)
        [x,y] = ginput(2);
        x = round(x(1));
        while(x >= 1 & x <= 32)
            if min(y)~=max(y)
                GP.limits{GP.CurrentCluster}{GP.CurrentChannel} = [GP.limits{GP.CurrentCluster}{GP.CurrentChannel};x min(y) max(y)]; % Add a limit.
                GP.PrevGoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster};
                GP.GoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster}(find(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,x) < max(y) & GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,x) >= min(y)));
                WaveformCutter('DrawWaveforms')
            else
                disp('Out of range. Ingnored point')
            end
            xlabel('Click to right or left of figure to end')
            ylabel('Click to right or left of figure to end')
            [x,y] = ginput(2);
            x = round(x(1));
        end
    case 'UndoAllLimits'
        for ch = GP.GoodChannels
            GP.limits{GP.CurrentCluster}{ch} = [];
        end
        GP.GoodIdx{GP.CurrentCluster} = 1:size(GP.wv,1);
        GP.PrevGoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster};
        WaveformCutter('DrawWaveforms')

    case 'Undo'
        GP.limits{GP.CurrentCluster}{GP.CurrentChannel} = GP.limits{GP.CurrentCluster}{GP.CurrentChannel}(1:(end-1),:);
        if isempty(GP.PrevGoodIdx{GP.CurrentCluster})
            disp('Recalculating all window discriminator limits. Other limits are ignored.')
            Recalculate_all_limits;
        else
            GP.GoodIdx{GP.CurrentCluster} = GP.PrevGoodIdx{GP.CurrentCluster};
            GP.PrevGoodIdx{GP.CurrentCluster} = [];
            % This is dumb, but it's the only way to really delete the last element of a cell array.
        end
        WaveformCutter('DrawWaveforms')

    case 'Remove'
        tmp.GoodIdx = GP.GoodIdx;
        tmp.limits = GP.limits;
        tmp.PrevGoodIdx = GP.PrevGoodIdx;
        GP.GoodIdx = [];
        GP.limits =[];
        GP.PrevGoodIdx = [];
        count = 1;
        for ii = 1:length(tmp.limits)
            if ii ~= GP.CurrentCluster
                GP.GoodIdx{count} = tmp.GoodIdx{ii}
                GP.PrevGoodIdx{count} = tmp.PrevGoodIdx{ii}
                GP.Limits{count} = tmp.limits{ii}
                count = count + 1;
            end
        end
        GP.nClusters = GP.nClusters -1;
        WaveformCutter('DrawWaveforms')
    case 'CleanWaveforms'
        % Clean out the waveforms that diverge from a set of known
        % templates. Essentially, all this does is compare the
        % waveforms to each member of the cananoical waveform library and
        % discards those that matched most closely to one of the noise
        % templates versus the waveform templates. This is nice as it
        % doesn't involve setting some arbitrary threshold. Of course it is
        % only as good as your library.

        % Stored in SB.mean_wv.
        % Changed all of the above conversions to one line -- saved a LOT of
        % memoryGP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:)
        good_waves = GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:);
        if isempty(SB)
            msgbox('No templates loaded')
            return
        end
        noise_idx = find(SB.data_type == 2);

        [fDmax,fPeak,fValley,ml2norms,fData] = ASTemplateMatch(SB.median_wv',good_waves);
        clear tmpdata fDmax fPeak fValley ml2norms;
        pack
        GP.PrevGoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster};
        [mx,idx] = 	max(fData');
        a = ismember(idx,noise_idx);
        GP.GoodIdx{GP.CurrentCluster} = find(a==0);
        figure
        Waveform_density(good_waves(find(a == 1),:));
        title('Noise')
        figure
        Waveform_density(good_waves(find(a == 0),:));
        title('Signal')

        WaveformCutter('DrawWaveforms')

    case 'DensityPlot'
        GP.cutDensityfh = figure;
        subsampled = 0;
        n_to_subsample = 8000;
        if length(GP.GoodIdx{GP.CurrentCluster}) > n_to_subsample
            subsampled = 1;
            r = randperm(length(GP.GoodIdx{GP.CurrentCluster}));
            idx = r(1:n_to_subsample);
        else
            idx = 1:length(GP.GoodIdx{GP.CurrentCluster});
        end
        figure
        Waveform_density(e_norm(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster}(idx),GP.CurrentChannel,:))),1,2000,1);
        title('Energy normalized')
        figure(GP.cutDensityfh)

        Waveform_density(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster}(idx),GP.CurrentChannel,:)),1,2000,1);
        hold on
        if subsampled
            title(['Subsampled ' num2str(length(idx)) ' of ' num2str(length(GP.GoodIdx{GP.CurrentCluster})) ' waveforms'])
        end
        uicontrol('Parent', GP.cutDensityfh, ...
            'Units', 'Normalized', 'Position', [0 0 .2 .05], ...
            'Style', 'pushbutton', 'Tag', 'CutDensityWaveform', 'String', 'Add Limits', 'Callback', 'WaveformCutter(''CutDensityWaveform'')', ...
            'TooltipString', 'Make window discriminators around waveform.');
    case 'CutDensityWaveform'
        figure(GP.cutDensityfh)
        [x,y] = ginput(2);
        x = round(x(1));
        while(x >= 1 & x <= 32)
            if min(y)~=max(y)
                GP.limits{GP.CurrentCluster}{GP.CurrentChannel} = [GP.limits{GP.CurrentCluster}{GP.CurrentChannel};x min(y) max(y)]; % Add a limit.
                GP.PrevGoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster};
                GP.GoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster}(find(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,x) < max(y) & GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,x) >= min(y)));
                plot([x x],y,'k:','LineWidth',3)
                %WaveformCutter('DrawWaveforms')
            else
                disp('Out of range. Ingnored point')
            end

            xlabel('Click to right or left of figure to end')
            ylabel('Click to right or left of figure to end')
            [x,y] = ginput(2);
            x = round(x(1));
        end
        WaveformCutter('DrawWaveforms')

    case 'nWavesToDraw'
        GP.nPoints = str2num(get(gcbo,'String'));
        WaveformCutter('DrawWaveforms')

    case 'CutOnLinearDiscriminant'
        val = str2num(get(gcbo,'String'));

        if ~isempty(GP.Linear_discriminant_wt{val})
            % The linear discriminant should be performed ONLY on the
            % energy normalized data. We are interested in mostly
            % discriminating the waveform shape with this discriminator. We
            % can always compare it with energy in an XY plot.

            wv = e_norm(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:)));
            %energy = sqrt(sum(wv.* wv,2));
            % Energy normalized???
            GP.tmp = GP.Linear_discriminant_wt{val}'*wv';
            [h1,r] = hist(GP.tmp,150);
            figure
            d = mean(diff(r));
            plot(r+d/2,h1);
            ylabel('Count')
            title(['Histogram of Linear Discriminant ' num2str(val)])
            xlabel('--> Closer')
            clear wv
            pack
        end

        uicontrol('Parent', gcf, ...
            'Units', 'Normalized', 'Position', [0 0 .2 .05], ...
            'Style', 'pushbutton', 'Tag', 'CutOnFullHistLD', 'String', 'Add Limit', 'Callback', 'WaveformCutter(''CutOnFullHistLD'')', ...
            'TooltipString', 'Add limit');

    case 'CutOnTemplate'
        val = str2num(get(gcbo,'String'));

        if ~isempty(SB)
            % Stored in SB.mean_wv.
            % Changed all of the above conversions to one line -- saved a LOT of
            wv = squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:));
            energy = sqrt(sum(wv.* wv,2));
            % Energy normalized.
            GP.tmp = wv./(repmat(energy,1,32))*SB.mean_wv(val,:)';
            [h1,r] = hist(GP.tmp,150);
            figure
            d = mean(diff(r));
            plot(r+d/2,h1);
            ylabel('Count')
            title(['Histogram of Template ' num2str(val)])
            xlabel('--> Closer')
        end

        uicontrol('Parent', gcf, ...
            'Units', 'Normalized', 'Position', [0 0 .2 .05], ...
            'Style', 'pushbutton', 'Tag', 'CutOnFullHistTemplate', 'String', 'Add Limit', 'Callback', 'WaveformCutter(''CutOnFullHistTemplate'')', ...
            'TooltipString', 'Add limit');

    case 'CutOnWaveformParameter'
        val = str2num(get(gcbo,'String'));
        if val == -9
            % My secret dimension. Curve around the peak. Take
            % The n points around the peak, make a vec, normalize it and then calc the energy.
            w = squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,6:10));
            curvness = sum((w - repmat(mean(w')',1,size(w,2)))'.^2);
            clear w
            pack
            [h1,r] = hist(curvness,150);
            axis
            xlabel('<- less curvy   more curvy ->')
        else
            [h1,r] = hist(squeeze(GP.Params(GP.GoodIdx{GP.CurrentCluster},val)),150);
        end
        figure
        d = mean(diff(r));
        plot(r+d/2,h1);
        ylabel('Count')
        title(['Histogram of Parameter ' num2str(val)])
        xlabel('')

        uicontrol('Parent', gcf, ...
            'Units', 'Normalized', 'Position', [0 0 .2 .05], ...
            'Style', 'pushbutton', 'Tag', 'CutOnFullHistParameter', 'String', 'Add Limit', 'Callback', 'WaveformCutter(''CutOnFullHistParameter'')', ...
            'TooltipString', 'Add limit');

    case 'CutOnWaveformPoint'
        val = str2num(get(gcbo,'String'));
        if val >= 0 & val <= 32
            [h1,r] = hist(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,val)),150);
            d = mean(diff(r));
            figure
            plot(r+d/2,h1);
            ylabel('Count')
            title(['Histogram of voltage values of all waveforms at point ' num2str(val)])
            xlabel('voltage')
        else
            msgbox('The specified point is out of range (-8 to 32).')
        end
        uicontrol('Parent', gcf, ...
            'Units', 'Normalized', 'Position', [0 0 .2 .05], ...
            'Style', 'pushbutton', 'Tag', 'CutOnFullHistPt', 'String', 'Add Limit', 'Callback', 'WaveformCutter(''CutOnFullHistPt'')', ...
            'TooltipString', 'Add limit');

    case {'CutOnFullHistPt' 'CutOnFullHistTemplate' 'CutOnFullHistParameter'  'CutOnFullHistLD' }
        title('Enter limits')
        [x,y] = ginput(2);
        GP.PrevGoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster};
        switch action
            case 'CutOnFullHistPt'
                val = str2num(get(findobj(GP.figHandle,'Tag','CutOnWaveformPoint'),'String'));
                GP.GoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster}(find(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,val) < max(x) & GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,val) >= min(x)));
            case 'CutOnFullHistParameter'
                val = str2num(get(findobj(GP.figHandle,'Tag','CutOnWaveformParameter'),'String'));
                GP.GoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster}(find(GP.Params(GP.GoodIdx{GP.CurrentCluster},val) < max(x) & GP.Params(GP.GoodIdx{GP.CurrentCluster},val) >= min(x)));
                val = -val;
            case {'CutOnFullHistTemplate' }
                val = str2num(get(findobj(GP.figHandle,'Tag','CutOnTemplate'),'String'));
                GP.GoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster}(find(GP.tmp < max(x) & GP.tmp >= min(x)));
                val = val - 10; % ID for a template is a negative value less that -10
            case {'CutOnFullHistLD'}
                val = str2num(get(findobj(GP.figHandle,'Tag','CutOnLinearDiscriminant'),'String'));
                GP.GoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster}(find(GP.tmp < max(x) & GP.tmp >= min(x)));
                val = val - 100; % ID for a template is a negative value less that -10
        end

        hold on
        a = axis
        a_color = rand(1,3);
        plot([min(x) min(x)],[a(3) a(4)],'Color',a_color)
        plot([max(x) max(x)],[a(3) a(4)],'Color',a_color)
        GP.limits{GP.CurrentCluster}{GP.CurrentChannel} = [GP.limits{GP.CurrentCluster}{GP.CurrentChannel} ; val min(x) max(x)];
        WaveformCutter('DrawWaveforms')

    case 'TransformData'

        % Change the way the data looks.
        % I use eval strings to avoid actually saving the values -- to save space.
        %  as waveforms take up a lot of memory.
        switch GP.transform_methods{get(gcbo,'Value')}
            case 'Raw values'
                GP.eval_str = 'draw_wv = squeeze(GP.wv(GP.DrawIdx,GP.CurrentChannel,:));';
            case 'sin(x)/x'

                %mx = max(GP.original_wv(:));
                %mn = min(GP.original_wv(:));
                % Tranform to be between 0 and 1.
                %GP.wv = sin((GP.original_wv+mn)/(mx+mn));%./(GP.original_wv+mn)/(mx+mn);
                GP.eval_str = 'mx = max(GP.wv(:));  mn = min(GP.wv(:));draw_wv = sin((squeeze(GP.wv(GP.DrawIdx,GP.CurrentChannel,:))+mn)/(mx+mn));';

            case 'x^2'
                %GP.wv = GP.original_wv.^2;
                GP.eval_str = 'draw_wv = squeeze(GP.wv(GP.DrawIdx,GP.CurrentChannel,:)).^2;';

            case 'Z' % Not implemented
            case 'subtract mean'
                GP.eval_str = 'mn = mean(squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:)));draw_wv = squeeze(GP.wv(GP.DrawIdx,GP.CurrentChannel,:))- repmat(mn,length(GP.DrawIdx),1);';
                %mn = mean(GP.original_wv,3);
                %for ii = 1:length(size(GP.wv,2));
                %    GP.wv(:,ii,:) = repmat(mn(:,ii),1,32);
                %end

                %GP.wv = GP.original_wv - GP.wv;
            case 'norm'

            case 'stdPC 1'
                GP.eval_str = 'draw_wv = squeeze(GP.wv(GP.DrawIdx,GP.CurrentChannel,:)).*repmat(GP.stdPC.pc(:,1)'',length(GP.DrawIdx),1);';
            case 'stdPC 2'
                GP.eval_str = 'draw_wv = squeeze(GP.wv(GP.DrawIdx,GP.CurrentChannel,:)).*repmat(GP.stdPC.pc(:,2)'',length(GP.DrawIdx),1);';
            case 'stdPC 3'
                GP.eval_str = 'draw_wv = squeeze(GP.wv(GP.DrawIdx,GP.CurrentChannel,:)).*repmat(GP.stdPC.pc(:,3)'',length(GP.DrawIdx),1);';
        end

        WaveformCutter('DrawWaveforms')

    case 'UpdateClusterInMClust'
        global MClust_Clusters
        global MClust_Cluster_ModFlag   % array with 0 or 1 for every cluster
        % a 1 means cluster will have to be
        % recomputed before drawing.  A 0 means no recompute
        % needed.  Used by graphing routine.
        try
            % Provide MClust with a list of 'forbidden' points. These points will not be allowed
            % in the clusters.
            MClust_Clusters{GP.ClustNum} = Restrict_Points( MClust_Clusters{GP.ClustNum},setdiff(GP.IdxToMaster,GP.IdxToMaster(GP.GoodIdx{GP.CurrentCluster})) );
            MClust_Cluster_ModFlag(GP.ClustNum) = 1;
            c = get(gcbo,'BackgroundColor')
            s = get(gcbo,'String')
            set(gcbo,'BackgroundColor','g')
            set(gcbo,'String','UPDATED')

            pause(.6)
            set(gcbo,'BackgroundColor',c)
            set(gcbo,'String',s)
        catch
            msgbox('Could not perform operation. Is MClust running?')
        end

    case 'New Random Set'
        r = randperm(length(GP.GoodIdx{GP.CurrentCluster}));
        nPoints = min([GP.nPoints length(r)]);
        GP.DrawIdx = r(1:nPoints);
        WaveformCutter('DrawWaveforms')

    case 'ReadFile'
        [p,n,e] = fileparts(GP.WaveFile);
        h = findobj(GP.figHandle,'Tag','ReadFileType');
        file_type = GP.read_file_type_str{get(h,'Value')};

        % filename = uiputfile({[n '*']},'Choose a filename. The extension will be added.');
        %GP.read_file_type_str = {'t','ntt/nse/nst/dat','tstxt','nts'};

        switch file_type
            case 't'
                [p,n,e] = fileparts(GP.WaveFile);
                [filename pathname] = uigetfile({['*' n '*.t']},'Choose a timestamp file');
                if filename~=0

                    % Load in the timestamp file.
                    tfp = fopen(fullfile(pathname,filename), 'rb','b');
                    if (tfp == -1)
                        warning([ 'Could not open tfile ' filename]);
                        return
                    end
                    ReadHeader(tfp);
                    t_to_get = fread(tfp,inf,'uint32');	%read as 32 bit ints
                    fclose(tfp);
                    t_to_get = floor(unique(t_to_get)); % Get rid of duplicates if there are any.
                    % Find the common timestamps.
                    [x, GP.GoodIdx{GP.CurrentCluster}] = intersect(floor(GP.spiketimes_usec/100), t_to_get);
                    if length(GP.GoodIdx{GP.CurrentCluster}) ~= length(t_to_get)
                        msgbox(['WARNING: Could not load ' num2str(length(t_to_get) - length(GP.GoodIdx{GP.CurrentCluster})) ' of the ' num2str(length(t_to_get)) ' spikes in the tfile.']);
                    end

                    if isempty(GP.GoodIdx{GP.CurrentCluster})
                        msgbox('No spikes from the .t file correspond to spike in the waveform data')

                    end

                    WaveformCutter('DrawWaveforms')
                end
            case 'ntt/nse/nst/dat'
                [filename pathname] = uigetfile({'*.dat', '*.n*'},'Choose a file to read.');
                GP = [];
                try
                    close(GP.figHandle);
                    close(GP.fg);
                    close(GP.time_fg);
                catch
                end

                WaveformCutter(fullfile(pathname, filename))

            case 'tstxt'
                [filename pathname] = uigetfile({'*.tstxt'},'Choose a timestamp file');
                if filename~=0
                    t_to_get = load(fullfile(pathname, filename));
                    % Find the common timestamps.
                    [x, GP.GoodIdx{GP.CurrentCluster}] = intersect(GP.spiketimes_usec, t_to_get);
                    WaveformCutter('DrawWaveforms')
                else
                    msgbox('No Such File')
                end

            case 'nts'
                [filename pathname] = uigetfile({'*.tstxt'},'Choose a timestamp file');
                if filename~=0
                    [t_to_get] = nlx2matnts(fullfile(pathname, filename),1,0,0,0,0,0);
                    [x, GP.GoodIdx{GP.CurrentCluster}] = intersect(GP.spiketimes_usec, t_to_get);
                    WaveformCutter('DrawWaveforms')
                else
                    msgbox('No Such File')
                end
            case 'Event .tstxt'
                %
                [filename pathname] = uigetfile({'*.tstxt'},'Choose a text event timestamp file.');
                GP.EventTimestamps_sec = load(fullfile(pathname, filename),'-ascii');
                GP.EventTimestamps_sec = GP.EventTimestamps_sec /1e6;
                disp('Events Loaded')
            case 'Limits .lim'
                % NOTE: THis does not work for tetrodes right now. There is not
                % place for tetrode number in the data file.
                [filename pathname] = uigetfile({'*.lim'},'Choose a limits file (contains window discriminator limits around waveform)');
                all_lines = textread(fullfile(pathname, filename),'%s','delimiter','');

                for ii = 1:length(all_lines)
                    [cl(ii) cl(ii) ftype{ii}] = strread(all_lines{ii},'%d%d%s%*[^\n]','delimiter',' ');
                    L = strread(all_lines{ii},'%s','delimiter',' ');
                    P = zeros((length(L)-3)/3,3);
                    limcount = 1;
                    for character_count = 4:3:length(L)
                        P(limcount,1) = str2num(L{character_count});
                        P(limcount,2) = str2num(L{character_count+1});
                        P(limcount,3) = str2num(L{character_count+2});
                        limcount = limcount + 1;
                    end

                    switch ftype{ii}{1}
                        case 'wv'
                            GP.limits{GP.CurrentCluster}{GP.CurrentChannel} = [GP.limits{GP.CurrentCluster}{GP.CurrentChannel};P];
                        case 'Params'
                            % param values are identified by negative values.
                            P(:,1) = -1*P(:,1);
                            GP.limits{GP.CurrentCluster}{GP.CurrentChannel} = [GP.limits{GP.CurrentCluster}{GP.CurrentChannel};P];
                        otherwise
                            error('Corrupted file.')
                    end
                    clear P;
                end

                Recalculate_all_limits
                WaveformCutter('DrawWaveforms')
            case 'Template'
                [filename pathname] = uigetfile({'*emplate*.mat'},'Choose a template file or put it in your home directory.');
                load(fullfile(pathname,filename));
            otherwise
                error('Wrong file type')
        end
        disp( filename)

    case 'WriteFile'
        [p,n,e] = fileparts(GP.WaveFile);
        filename = [];
        h = findobj(GP.figHandle,'Tag','FileType');
        file_type = GP.write_file_type_str{get(h,'Value')};

        switch file_type
            case 't'
                thename= ['*' n '*.t'];
                [filename pathname] = uiputfile({thename},'Choose a filename. The extension will be added.',[n '_c' num2str(GP.CurrentCluster) '.t']);
                [p,f,e] = fileparts(filename);

                if strcmp(e,'.t')
                    filename = fullfile(pathname,[filename]);
                else
                    filename = fullfile(pathname,[filename '.t']);
                end

                fp = fopen(filename, 'wb', 'b');
                if (fp == -1)
                    errordlg(['Could not open file"' filename '".']);
                else
                    WriteHeader(fp, 'T-file', 'Output from MClust''Time of spiking stored in timestamps -- units are whatever was passed in.', 'as unsigned integer');
                    tmst = floor(GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster})/100);
                    fwrite(fp, tmst, 'uint32');
                    fclose(fp);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Save a tstxt file as well.
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    [p,n,e] = fileparts(filename);

                    fp = fopen(fullfile(p,[n '.tstxt']),'w');
                    % The following header attachment is not working!
                    if ~isempty(GP.header)
                        for ii = 1:length(GP.header)
                            fprintf(fp,'%% %s\n',GP.header{ii});
                        end
                    end
                    fprintf(fp,'%.0f\n',GP.spiketimes_usec(sort(GP.GoodIdx{GP.CurrentCluster})));
                    fclose(fp);
                end
            case 'txt'
                thename= ['*' n '*.txt; ' '*' n '*.tstxt;'];
                [filename pathname] = uiputfile({thename},'Choose a filename. The extension will be added.', [n '.tstxt']);
                filename = fullfile(pathname,filename);
                fp = fopen(filename,'w');
                % The following header attachment is not working!
                if ~isempty(GP.header)
                    for ii = 1:length(GP.header)
                        fprintf(fp,'%% %s\n',GP.header{ii})
                    end
                end
                fprintf(fp,'%.0f\n',GP.spiketimes_usec(sort(GP.GoodIdx{GP.CurrentCluster})))
                fclose(fp)
            case 'TT'
                thename= ['*' n '*.ntt'];
                [filename pathname] = uiputfile({thename},'Choose a filename. The extension will be added.',[n '.tstxt']);
                filename = fullfile(pathname,filename);
                msgbox('Not implemented')

            case 'SE'
                thename= ['*' n '*.nse'];
                [filename pathname] = uiputfile({thename},'Choose a filename. The extension will be added.');
                filename = fullfile(pathname,filename);
                if ~isempty(GP.WaveFile)
                    [timestamps, ScNumbers, CellNumbers, Params, NlxHeader] = ...
                        Nlx2MatSE(GP.WaveFile ,1,1,1,1,0,1,GP.spiketimes_usec(GP.GoodIdx{GP.CurrentCluster}));
                    disp('Reloaded original file.')
                    if length(timestamps) ~= length(GP.GoodIdx{GP.CurrentCluster})
                        disp('WARNING: Could not retrieve all of the files.')
                    end
                    if filename ~= 0
                        % I have to create a new variable W. FOr some reason,
                        % Mat2nlxSE dies if I include permute in the command line.
                        % It also seems to die even when I do use W. Buggy.
                        pack
                        W = permute(GP.wv(GP.GoodIdx{GP.CurrentCluster},:,:),[3 2 1]);
                        Mat2NlxSE(filename, timestamps, ScNumbers, CellNumbers, Params, W, length(timestamps));
                    end
                else
                    disp('Could not write file.')
                end

            case 'Limits .lim'
                % Rethreshold the specified file by the currently chosen limits.
                % Create a limits variable to pass into Rethreshold_SENT
                % This only works for SE channels right now.
                do_it = 0;
                % Check to see if there actually are boundaries on some channels.
                for ii = 1:length(GP.limits)
                    if ~isempty(GP.limits{ii})
                        do_it = 1;
                    end
                end
                if do_it
                    [p, n, e] = fileparts(GP.WaveFile);
                    a = sscanf(n,'SE_%s');
                    defch = Alpha2Channel(a);
                    prompt={'Channel Number:','Cell Number:','Optional ID:'};
                    def={num2str(defch),'1',''};
                    dlgTitle='Cluster Info';
                    lineNo=1;
                    answer=inputdlg(prompt,dlgTitle,lineNo,def);
                    ch = str2num(answer{1});
                    cl = str2num(answer{2});
                    if ~isempty(answer{3})
                        id = ['_' answer{3}];
                    else
                        id = [];
                    end
                    newname = fullfile(p,[n '_' num2str(ch) '_' num2str(cl) '_online_cluster' id '.lim']);

                    fp = fopen(newname,'w');
                    if fp == -1
                        msgbox('Could not open file')
                    end

                    for limnum = 1:length(GP.limits)
                        lims = sortrows(round(GP.limits{limnum}));
                        % Remove redundant limits
                        [u,idx] = unique(lims(:,1));
                        newlims = zeros(length(idx),3)*nan;
                        fidx = 1;
                        for li = 1:length(idx)
                            llims = lims(fidx:idx(li),2);
                            ulims = lims(fidx:idx(li),3);
                            newlims(li,:) = [lims(idx(li),1) max(llims) min(ulims)];
                            fidx = idx(li)+1;
                        end
                        wv_lims = newlims(find(newlims(:,1)>0),:);
                        Params_lims = newlims(find(newlims(:,1) < 0 & newlims(:,1) >= -8),:);
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                        
                        % In an ideal world, I would restrict this list so that there
                        % are no duplicate channels. Not now.
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        if ~isempty(wv_lims)
                            fprintf(fp,'%g %g wv ', [ch cl]);
                            for jj = 1:size(wv_lims,1)
                                fprintf(fp,'%g ', wv_lims(jj, :));
                            end
                            fprintf(fp,'\n');
                        end

                        if ~isempty(Params_lims)
                            Params_lims(:,1) = abs(Params_lims(:,1));
                            fprintf(fp,'%g %g Params ', [ch cl]);
                            for jj = 1:size(Params_lims,1)
                                fprintf(fp,'%g ', Params_lims(jj, :));
                            end
                            fprintf(fp,'\n');
                        end
                    end
                    fclose(fp)
                    disp(['Saved file as ' newname '  Ch ' num2str(ch) '.'])
                else
                    msgbox('There are no limits. Aborting.')
                end

            case 'Template'
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Adds the current cell to a specified template database.
                % Ask the user if this is noise or if it is a cell.
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                [pth,fname,ext] = fileparts(GP.WaveFile);
                prompt={'Type (1 cell, 2 noise):', 'Samp. Frequency'};
                def={'1', num2str(GP.sFreq)};
                dlgTitle='Template information';
                lineNo = 1;
                answer=inputdlg(prompt,dlgTitle,lineNo,def);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Also save it to the master template database...
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                wv = squeeze(GP.wv(GP.GoodIdx{GP.CurrentCluster},GP.CurrentChannel,:));
                energy = sqrt(sum(wv.* wv,2));
                energy_normalized_wv = wv./(repmat(energy,1,32));
                switch answer{2}
                    case '1'
                        load('Z:\Matlab2\User_Specific\cowen\Databases\hipp_templates_cowen_25600.mat');
                        waveforms = [waveforms wv(:)'];
                        save('Z:\Matlab2\User_Specific\cowen\Databases\hipp_templates_cowen_25600.mat','waveforms');
                    case '2'
                        load('Z:\Matlab2\User_Specific\cowen\Databases\noise_templates_cowen_25600.mat')
                        noise_waveforms = [noise_waveforms wv(:)'];
                        save('Z:\Matlab2\User_Specific\cowen\Databases\noise_templates_cowen_25600.mat','noise_waveforms');
                end
                clear energy_normalized_wv energy SB
                pack
            otherwise
                error('Invalid type')
        end
        disp([filename ' written.'])
    case 'ApplyLimitsToFile'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Rethreshold the specified file by the currently chosen limits.
        % Create a limits variable to pass into Rethreshold_SENT
        % This only works for SE channels right now.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        do_it = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        % Check to see if there actually are boundaries on some channels.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for ch = 1:length(GP.limits)
            if ~isempty(GP.limits{GP.CurrentCluster}{ch})
                do_it = 1;
            end
        end
        if do_it
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
            % Rethresholding does not currently work on parameters-- just
            % on the waveform itself.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            good_idx = find(GP.limits{GP.CurrentCluster}{GP.CurrentChannel}(:,1) >0);
            %%ulim = ones(1,32)*2048;
            %llim = ones(1,32)*-2048;
            %llim(GP.limits{GP.CurrentCluster}{GP.CurrentChannel}(good_idx,1)) = GP.limits{GP.CurrentCluster}{GP.CurrentChannel}(good_idx,2);
            %ulim(GP.limits{GP.CurrentCluster}{GP.CurrentChannel}(good_idx,1)) = GP.limits{GP.CurrentCluster}{GP.CurrentChannel}(good_idx,3);
            [p, n, e] = fileparts(GP.WaveFile);
            newname = fullfile(p,[n '_rethresh' e]);
            a = GP.limits{GP.CurrentCluster}{GP.CurrentChannel}(good_idx,:)';
            a = a(:);
            %RethresholdSE_nt(GP.WaveFile, newname,llim,ulim,1);
            RethresholdSE_nt(GP.WaveFile, newname,a,1);
            disp(['Saved file as ' newname])
        else
            msgbox('There are no limits. Aborting.')
        end
    case 'FileType'
        % Do nothing.

    case 'Exit'
        % check if ok
        %ynClose = questdlg('Exiting WaveformClust.  Are you sure?', 'ExitQuestion', 'Yes', 'Cancel', 'Cancel');
        ynClose = 'Yes';
        if strcmp(ynClose,'Yes')
            try
                close(GP.figHandle);
            catch
            end
            try
                close(GP.fg);
            catch
            end
            try
                close(GP.time_fg);
            catch
            end
        end
        clear GP
        pack
    otherwise
        disp('Unknown command or could not find the file.')

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize the waveform screen.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figHandle = Init_form(channels)
%
global GP
global MClust_Clusters

for ch = 1:length(channels)
    ch_str{ch} = num2str(channels(ch));
end
uicHeight = 0.04;
uicWidth  = 0.9;
uicWidth0 = uicWidth/3;
uicWidth1 = uicWidth/2;
dX = 0.2;
XLocs = [0.05 .45 0.95];
dY = uicHeight;
YLocs = 0.9:-dY:0.05;
FrameBorder = 0.01;

%-------------------------------
% figure

figHandle = figure(...
    'Name', ['Waveform Cutting Control Window '],...
    'NumberTitle', 'off', ...
    'Tag', 'ClusterCutWindow', ...
    'HandleVisibility', 'Callback', ...
    'UserData', [], ...
    'Position', [10 180 150 550], 'WindowStyle', 'normal'); % Modal hangs things until you return.
%, ...
%    'CreateFcn', 'WaveformCutter');
% -------------------------------
% waveform cutter buttons
% -------------------------------
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) .95 uicWidth uicHeight], ...
    'Style', 'text', 'String', 'Waveform Cutter v1.0');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(1) uicWidth/4 uicHeight], ...
    'Style', 'text', 'String', 'Chnl');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth/4 YLocs(1) uicWidth/2 uicHeight], ...
    'Style', 'text', 'String', 'Line Type');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) + uicWidth*2/3  YLocs(1) uicWidth/4 uicHeight], ...
    'Style', 'text', 'String', 'clst ');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+1.5*uicWidth0*.8+uicWidth1  YLocs(1) uicWidth/4 uicHeight], ...
    'Style', 'checkbox','Value', 0, 'Tag', 'ShowClust', 'String', '', ...
    'Callback', 'WaveformCutter(''ShowClust'')', ...
    'TooltipString', 'Show the other clusters');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(2) uicWidth/4 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'Channel', 'String', num2str(GP.CurrentChannel), 'Callback', 'WaveformCutter(''Channel'')', ...
    'TooltipString', 'Press to cycle through the available channels.');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth/4  YLocs(2) uicWidth/3  uicHeight],...
    'Style', 'popupmenu', 'Tag', 'DrawWaveformType', 'String', GP.drawtype_str, ...
    'Callback', 'WaveformCutter(''DrawWaveformType'')', 'Value', 1, ...
    'TooltipString', 'DrawWaveformType');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) + uicWidth*2/3 YLocs(2) uicWidth/4 uicHeight], ...
    'Style', 'text', 'String', '2std ');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+1.5*uicWidth0*.8+uicWidth1 YLocs(2) uicWidth/4  uicHeight], ...
    'Style', 'checkbox','Value', 0, 'Tag', 'ShowSD', 'String', '', ...
    'Callback', 'WaveformCutter(''ShowSD'')', ...
    'TooltipString', 'ShowSD');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(3) uicWidth*1/3 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'Cluster', 'String', ['Clst ' num2str(GP.CurrentCluster)], 'Callback', 'WaveformCutter(''Cluster'')', ...
    'TooltipString', 'Press to cycle through the available clusters.');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth*1/3 YLocs(3) uicWidth*1/3 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'DrawWaveforms', 'String', 'Redraw', 'Callback', 'WaveformCutter(''DrawWaveforms'')', ...
    'TooltipString', 'Resample and draw the waveforms.');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) + uicWidth*2/3  YLocs(3) uicWidth/4 uicHeight], ...
    'Style', 'text', 'String', 'Sdw');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+1.5*uicWidth0*.8+uicWidth1 YLocs(3) uicWidth1 uicHeight], ...
    'Style', 'checkbox','Value', 0, 'Tag', 'ShowShadow', 'String', '', ...
    'Callback', 'WaveformCutter(''ShowShadow'')', ...
    'TooltipString', 'Show the shadow of eliminated waveforms.');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(4) uicWidth*1/3 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'AddCluster', 'String', 'Add clst', 'Callback', 'WaveformCutter(''AddCluster'')', ...
    'TooltipString', 'Add cluster');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) + uicWidth*1/3 YLocs(4) uicWidth*1/3 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'AddLimit', 'String', 'Add lim', 'Callback', 'WaveformCutter(''AddLimit'')', ...
    'TooltipString', 'Add a new limit');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth*2/3 YLocs(4) uicWidth*1/3 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'RapidAddLimit', 'String', 'Rapid', 'Callback', 'WaveformCutter(''RapidAddLimit'')', ...
    'TooltipString', 'Cut until out of bounds.');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(5) uicWidth/2 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'CutOnTimeAndPeak', 'String', 'Cut On Time', 'Callback', 'WaveformCutter(''CutOnTimeAndPeak'')', ...
    'TooltipString', 'CUT on the time and the peak with a non-convex hull limit (curvy).');

if length(GP.GoodChannels) > 1
    uicontrol('Parent', figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth/2 YLocs(5) uicWidth/2 uicHeight], ...
        'Style', 'pushbutton', 'Tag', 'ShowAllChannels', 'String', 'Show Chnls', 'Callback', 'WaveformCutter(''ShowAllChannels'')', ...
        'TooltipString', 'Show all of the channels.');
end
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(6) uicWidth1/3 uicHeight], ...
    'Style', 'text', 'Tag', 'CutOnLinearDiscriminantString', 'String', 'LD');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth1/3 YLocs(6) uicWidth1/3 uicHeight], ...
    'Style', 'edit', 'String', num2str(1), 'Tag', 'CutOnLinearDiscriminant', ...
    'Callback', 'WaveformCutter(''CutOnLinearDiscriminant'')', ...
    'TooltipString', 'Draws a histogram at using the linear discrimant calculted between 2 existing clusters.');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) + 2*uicWidth1/3 YLocs(6) uicWidth1 uicHeight], ...
    'Style', 'text', 'Tag', 'PointsToDraw', 'String', 'nWaves  ');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) + 4*uicWidth1/3 YLocs(6) uicWidth1*.8 uicHeight], ...
    'Style', 'edit', 'String', num2str(GP.nPoints), 'Tag', 'nWavesToDraw', ...
    'Callback', 'WaveformCutter(''nWavesToDraw'')', ...
    'TooltipString', 'Waves to plot on the display at once.');
% Point
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(7) uicWidth1/3 uicHeight], ...
    'Style', 'text', 'Tag', 'CutOnWaveformPointString', 'String', 'Pt');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth1/3 YLocs(7) uicWidth1/3 uicHeight], ...
    'Style', 'edit', 'String', num2str(8), 'Tag', 'CutOnWaveformPoint', ...
    'Callback', 'WaveformCutter(''CutOnWaveformPoint'')', ...
    'TooltipString', 'Draws a histogram at the specifed point and lets you cut on the histogram.');
% Parameter
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+2*uicWidth1/3 YLocs(7) uicWidth1/3 uicHeight], ...
    'Style', 'text', 'Tag', 'CutOnWaveformParameterString', 'String', 'Prm');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+3*uicWidth1/3 YLocs(7) uicWidth1/3 uicHeight], ...
    'Style', 'edit', 'String', num2str(1), 'Tag', 'CutOnWaveformParameter', ...
    'Callback', 'WaveformCutter(''CutOnWaveformParameter'')', ...
    'TooltipString', 'Draws a histogram at the specifed point and lets you cut on the histogram.');
% Template
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+4*uicWidth1/3 YLocs(7) uicWidth1/3 uicHeight], ...
    'Style', 'text', 'Tag', 'CutOnTemplateString', 'String', 'Tp');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+5*uicWidth1/3 YLocs(7) uicWidth1/3 uicHeight], ...
    'Style', 'edit', 'String', num2str(1), 'Tag', 'CutOnTemplate', ...
    'Callback', 'WaveformCutter(''CutOnTemplate'')', ...
    'TooltipString', 'Draws a histogram at the specifed point and lets you cut on the histogram.');

%%%%%%%%%%%%
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(8) uicWidth0 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'UndoCut', 'String', 'XY cut', 'Callback', 'WaveformCutter(''CutXY'')', ...
    'TooltipString', 'Cut on the xy dimensions of your choice.');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth0 YLocs(8) uicWidth0 uicHeight],...
    'Style', 'popupmenu', 'Tag', 'XDim', 'Value', 1,'String', GP.Dimension_string, ...
    'TooltipString', 'Select a dimension to cut on.');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+2*uicWidth0 YLocs(8) uicWidth0 uicHeight],...
    'Style', 'popupmenu', 'Tag', 'YDim','Value', 4, 'String', GP.Dimension_string, ...
    'TooltipString', 'Select a dimension to cut on.');


uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(9) uicWidth0 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'UndoCut', 'String', 'Undo', 'Callback', 'WaveformCutter(''Undo'')', ...
    'TooltipString', 'Undo the most recent limit.');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth0 YLocs(9) uicWidth0 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'UndoAllLimits', 'String', 'Un-all', 'Callback', 'WaveformCutter(''UndoAllLimits'')', ...
    'TooltipString', 'Undo all limits.');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(10) uicWidth0 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'CleanWaveforms', 'String', 'Clean', 'Callback', 'WaveformCutter(''CleanWaveforms'')', ...
    'TooltipString', 'Clean by matching waveforms to templates.');

if ~isempty(MClust_Clusters)
    uicontrol('Parent', figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1) YLocs(11) uicWidth1*2 uicHeight], ...
        'Style', 'checkbox','Value', 0, 'Tag', 'ShowMClustAvgWV', 'String', 'Mclust Cluster Avgs', ...
        'Callback', 'WaveformCutter(''ShowMClustAvgWV'')', ...
        'TooltipString', 'Show the average waveforms from the other mclust clusters.');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(12) uicWidth/3 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'DensityPlot', 'String', 'Density', 'Callback', 'WaveformCutter(''DensityPlot'')', ...
    'TooltipString', 'Density plot');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth/3 YLocs(12) uicWidth/3 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'DrawTime', 'String', 'Time', 'Callback', 'WaveformCutter(''DrawTime'')', ...
    'TooltipString', 'Time Plot');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+2*uicWidth/3 YLocs(12) uicWidth/3 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'HistISI', 'String', 'HistISI', 'Callback', 'WaveformCutter(''HistISI'')', ...
    'TooltipString', 'Draw HistISI');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)  YLocs(13) uicWidth/2 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'WaveSeries', 'String', 'WaveSeries', 'Callback', 'WaveformCutter(''WaveSeries'')', ...
    'TooltipString', 'Draw WaveSeries');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth/2 YLocs(13) uicWidth/2 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'FeaturePlot', 'String', 'Features', 'Callback', 'WaveformCutter(''FeaturePlot'')', ...
    'TooltipString', 'Summarize all of the features.');


uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(14) uicWidth/3 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'ACorr', 'String', 'ACorr', 'Callback', 'WaveformCutter(''ACorr'')', ...
    'TooltipString', 'Draw an autocorrelation plot.');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+ uicWidth/3 YLocs(14) uicWidth/3 uicHeight], ...
    'Style', 'edit', 'String', num2str(1000), 'Tag', 'ACorrWindowMsec', ...
    'TooltipString', 'Window size of the acorr.');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+ uicWidth*2/3 YLocs(14) uicWidth/3 uicHeight], ...
    'Style', 'edit', 'String', num2str(5), 'Tag', 'ACorrBinSizeMsec', ...
    'TooltipString', 'ACorrBinSizeMsec size of the acorr.');



%uicontrol('Parent', figHandle, ...
%    'Units', 'Normalized', 'Position', [XLocs(2) YLocs(15) uicWidth/2 uicHeight], ...
%    'Style', 'pushbutton', 'Tag', 'PETH', 'String', 'PETH', 'Callback', 'WaveformCutter(''PETH'')', ...
%    'TooltipString', 'Draw a PETH around loaded event timestamps.');

%uicontrol('Parent', figHandle, ...
%    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(13) uicWidth uicHeight], ...
%    'Style', 'pushbutton', 'Tag', 'CheckCluster', 'String', 'CheckCluster', 'Callback', 'WaveformCutter(''CheckCluster'')', ...
%    'TooltipString', 'CheckCluster');

% Lissajous is not terribly useful-- at least at this stage.
%if length(GP.GoodChannels) > 1
%    uicontrol('Parent', figHandle, ...
%        'Units', 'Normalized', 'Position', [XLocs(1) YLocs(15) uicWidth uicHeight], ...
%        'Style', 'pushbutton', 'Tag', 'Lissajous', 'String', 'Lissajous', 'Callback', 'WaveformCutter(''Lissajous'')', ...
%        'TooltipString', 'Draw Lissajous');
%end

if ~isempty(MClust_Clusters)
    uicontrol('Parent', figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1) YLocs(16) uicWidth uicHeight], ...
        'Style', 'pushbutton', 'Tag', 'UpdateClusterInMClust', 'String', 'Update In MClust', 'Callback', 'WaveformCutter(''UpdateClusterInMClust'')', ...
        'TooltipString', 'Export the modified cluster to MClust. These waveforms must have come from a running MClust.');
end

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(17) uicWidth1 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'WriteFile', 'String', 'Write file', 'Callback', 'WaveformCutter(''WriteFile'')', ...
    'TooltipString', 'Save a file of a particular type.');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth1 YLocs(17) uicWidth1 uicHeight],...
    'Style', 'popupmenu', 'Tag', 'FileType', 'String', GP.write_file_type_str, ...
    'Value', 1, ...
    'TooltipString', 'Select a file type for saving the data.');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(18) uicWidth1 uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'ReadFile', 'String', 'Open file', 'Callback', 'WaveformCutter(''ReadFile'')', ...
    'TooltipString', 'Open a file.');

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth1 YLocs(18) uicWidth1 uicHeight],...
    'Style', 'popupmenu', 'Tag', 'ReadFileType', 'String', GP.read_file_type_str, ...
    'Value', 1, ...
    'TooltipString', 'Select a file type for loading.');

if isempty(MClust_Clusters)
    % The user loaded the data from a file.
    uicontrol('Parent', figHandle, ...
        'Units', 'Normalized', 'Position', [XLocs(1)+uicWidth1 YLocs(19) uicWidth1 uicHeight], ...
        'Style', 'pushbutton', 'Tag', 'ApplyBounds', 'String', 'Apply Lims', 'Callback', 'WaveformCutter(''ApplyLimitsToFile'')', ...
        'TooltipString', 'Apply boundaries to a file. Currently only works for SE files.');
end

uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) YLocs(end-1) uicWidth uicHeight], ...
    'Style', 'pushbutton', 'Tag', 'Exit', 'String', 'Exit', 'Callback', 'WaveformCutter(''Exit'')', ...
    'TooltipString', 'Exit and return the good indices to the calling program.');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) .03+uicHeight/2 uicWidth uicHeight], ...
    'Style', 'text', 'String', 'Author: Stephen Cowen');
uicontrol('Parent', figHandle, ...
    'Units', 'Normalized', 'Position', [XLocs(1) .03 uicWidth uicHeight], ...
    'Style', 'text', 'String', 'scowen@email.arizona.edu');

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Other functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function v = stdPC(compnum)
% Returns one of the component eigenvectors.
global GP
in_sFreq = 32000;

PC = [  -0.101603310563578        -0.302038768882227        -0.134999782551374         0.100455447894825
    -0.0969550531997733        -0.265446644119049        -0.177226103975703           0.1830819009125
    -0.08013581941174        -0.219982612489545        -0.206405704891508         0.292994874475142
    -0.0538127432800189        -0.192058261871491        -0.197722052271033         0.393409147406964
    -0.0323802216086312        -0.187379105020446        -0.146771173664729         0.411211737015741
    -0.0510768399269461        -0.208365988657253       -0.0662977743384306         0.290653026628815
    -0.139146799485996        -0.203271167812469         0.042853852345076       0.00713006669561438
    -0.168200054677463        -0.181022057299047        0.0789122607838353        -0.136235101504785
    -0.103131936568902        -0.261956367067023        0.0576793763323289        -0.207855880315806
    0.0588789695696713         -0.29480884761399       0.00930295617447492        -0.219922151220139
    0.145736405369188        -0.261667062383008      -0.00733996021556256        -0.186234745953618
    0.176175581575989         -0.24273877299157       0.00572943659045798        -0.156562134860347
    0.184708544234893        -0.237166798512539        0.0412001748328669        -0.129499391236956
    0.179983967937547         -0.23898531683293        0.0998078968750699        -0.100069291035815
    0.155698575034447        -0.243008061948977         0.189866178366479       -0.0622289978143391
    0.08972054463244         -0.23403416091957         0.312315488744882      -0.00680392961586991
    -0.030585518591472        -0.178238645382309         0.399750305112018        0.0631379693085804
    -0.138957231995049       -0.0932691193190371         0.373575017050137         0.101498323071889
    -0.195571988819766       -0.0313250226022533         0.301651472485377         0.104946203614395
    -0.22131405601712       0.00170871705732078         0.238291996304389        0.0939572809865108
    -0.234890780735254        0.0203016834379553         0.187984607851391        0.0753592491455925
    -0.243329366506386        0.0297608788385787         0.145885225094878        0.0515402589960945
    -0.249061526734862         0.033697973362857         0.107964692996774        0.0229530270859782
    -0.252532596713499        0.0332376282813229        0.0724003512379643       -0.0114478834223079
    -0.254062707351789        0.0287388007940888        0.0351417301256614       -0.0498641454082863
    -0.253045164767045        0.0197737196851074      -0.00518737784501941       -0.0904800381916432
    -0.248556284947701       0.00555215529639264       -0.0493352922975399        -0.131172471274954
    -0.240303121234003       -0.0146384473458195       -0.0953588556295308        -0.165676729199682
    -0.227329091464152       -0.0418211031843215        -0.139417726404501        -0.192721407506194
    -0.210456411202343       -0.0741569749162699        -0.179712374912356        -0.207156475871965
    -0.189025853443878        -0.113399563829999        -0.213342549469347        -0.209153099851499
    -0.164312236905545        -0.154091199619666        -0.235002796742001        -0.199671032774177];
v = PC(:,compnum);

if in_sFreq == GP.sFreq
    return
else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interpolate the output so that it reflects the same sampling frequency as the current record.
    % Make sure it's centered on 8th point as the 8th point needs to remain the peak.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    in_interval_usec = 1e6/in_sFreq;
    out_interval_usec = 1e6/GP.sFreq;
    out_x = [-7*out_interval_usec:out_interval_usec:out_interval_usec*24];
    in_x = [-7*in_interval_usec:in_interval_usec:in_interval_usec*24]';
    vo = interp1(in_x,v,out_x);
    [idxi, idxj] = find(isnan(vo));
    if ~isempty(idxi)
        for ii = 1:length(idxi)
            if idxi(ii) < 8
                vo(idxi(ii),idxj(ii)) = v(idxi(ii),1);
            else
                vo(idxi(ii),idxj(ii)) = v(idxi(ii),end);
            end
        end
    end
    v = vo;
end
return


function [x,y] = draw_hull()
% Draws a convex hull
[x,y] = ginput;
k = convexhull(x,y);
x = x(k);
y = y(k);
return

function Recalculate_all_limits;
global GP
GP.GoodIdx{GP.CurrentCluster} = 1:size(GP.wv,1);
for ch = 1:length(GP.limits{GP.CurrentCluster})
    for lim = 1:size(GP.limits{GP.CurrentCluster}{ch},1)
        if GP.limits{GP.CurrentCluster}{ch}(lim,1) > 0
            GP.GoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster}(find(GP.wv(GP.GoodIdx{GP.CurrentCluster},ch,GP.limits{GP.CurrentCluster}{ch}(lim,1)) < max(GP.limits{GP.CurrentCluster}{ch}(lim,2:3)) & GP.wv(GP.GoodIdx{GP.CurrentCluster},ch,GP.limits{GP.CurrentCluster}{ch}(lim,1)) >= min(GP.limits{GP.CurrentCluster}{ch}(lim,2:3))));
        else
            GP.GoodIdx{GP.CurrentCluster} = GP.GoodIdx{GP.CurrentCluster}(find(GP.Params(GP.GoodIdx{GP.CurrentCluster},abs(GP.limits{GP.CurrentCluster}{ch}(lim,1))) < max(GP.limits{GP.CurrentCluster}{ch}(lim,2:3)) & GP.Params(GP.GoodIdx{GP.CurrentCluster},abs(GP.limits{GP.CurrentCluster}{ch}(abs(lim),1))) >= min(GP.limits{GP.CurrentCluster}{ch}(abs(lim),2:3))));
        end
    end
end
return

function S = smooth2D(H)
% 2d smoothing by convolving with a function -- a narrow pointy one in this case.
%c = [ .5 .5 .5];
r = [ 0.0225158185871862    -2.80653567739121e-018  0.202642367284676  0.5         0.202642367284676    -2.80653567739121e-018  0.0225158185871862];
c = [ 0.0225158185871862    -2.80653567739121e-018  0.202642367284676  0.5         0.202642367284676    -2.80653567739121e-018  0.0225158185871862];
S = conv2(r,c,H,'same'); % very similar to the filter2 command.
%S = H;
return

function h = barp(A,B,C);
% a bar plot that plots bars with the patch call -- and no spaces or lines between them.
%   matlab's bar can sometimes crash and does wierd things. This routine gets around these problems.
%
%function h = barp(A,B,C)
%
% INPUT: Values for the bars.
%  if 1 arg is passed, it is assumed to be the bar heights (must be a vector)
%  if 2 arguments are passed, the first is assumed to be the xaxis.
%  if one of the arguments is 'offset', followed by a number, the xaxis if offset by that
%    number (useful if you want to align the bars on x_axis(offset = 0 (default)) or center them(offset = .5)
%  if three arguments are passed, first is xaxis, second is yaxis and third is offset. If the yaxis
%    is left empty, then it as assumed to be ordered from 1:length(yaxis)
%
% OUTPUT: A gorgeous plot and a figure handle to the patch objects of the plot.
%
% cowen 2002
offset = 0;
A = A(:)';

switch nargin
    case 1
        y = [zeros(1,length(A));A;A;zeros(1,length(A))];
        x = [offset:length(A)-1+offset; offset:length(A)-1+offset; (1+offset):length(A)+offset; (1+offset):length(A)+offset];
    case 2
        B = B(:)';
        x = [A(1:end)+offset;A(1:end)+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset];
        %x = [A(1:end)+offset;A(1:end)+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset];
        y = [zeros(1,length(B));B;B;zeros(1,length(B))];
    case 3
        B = B(:)';
        offset = C;
        y = [zeros(1,length(B));B;B;zeros(1,length(B))];
        if isempty(A)
            x = [offset:length(A)-1+offset; offset:length(A)-1+offset; (1+offset):length(A)+offset; (1+offset):length(A)+offset];
        else
            x = [A(1:end)+offset;A(1:end)+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset];
        end
    otherwise
        error('Invalid number of arguments')
end

h = patch(x,y,'b');
%set(h,'LineStyle','-')
% Get rid of the lines -- or create the illusion that the lines are gone.
fc = get(h,'FaceColor');
set(h,'EdgeColor',fc);
axis tight;
return

function en = e_norm(wv)
% energy normalizes the waveform (rows are individual 32 point waveforms, cols are
% points on the waveform.
energy = sqrt(sum(wv.*wv,2));
en = wv./repmat(energy,1,Cols(wv));
return