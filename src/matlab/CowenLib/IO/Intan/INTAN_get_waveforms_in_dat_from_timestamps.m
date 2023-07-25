function WV_long = INTAN_get_waveforms_in_dat_from_timestamps(dat_dir, intan_channels, ts_uS, window_ms_before_after, filter_type)
% You need to figure out which INTAN channels to load for each file from the
% channel_translation file.
if nargin < 4
    window_ms_before_after = [.5 1.4];
end
if nargin < 5
    filter_type = 'butter';
end
if nargin < 1
    % presume the user just passes in the dat_dir
    close all
%     if isempty(dat_dir)
%         dat_dir = 'F:\LID_Ketamine_Single_Unit_R56\Rat337\05\Recording_210629_100600';
%     end
    %Next three lines are specific to Abhi's data, i.e., the first
    %subfolder in the root dir is the folder containing raw .dat files
    dat_dir = pwd;
    dirinfo = dir(dat_dir);
    all_dir = dirinfo([dirinfo(:).isdir]);
    folder = all_dir(3).name;
    dat_dir = fullfile(dat_dir,folder);
    
    cd(dat_dir)
    
    load(fullfile(dat_dir,'..','AllSpikes.mat'))
    d = dir(fullfile(dat_dir,'..','..','*channel_translation_table*.xlsx'));
    XL = readtable(fullfile(d(1).folder,d(1).name));
    for iSP = 1:length(SP)
        ts_uS = SP(iSP).t_uS;
        % figure out the tetrode
        ix = strfind(SP(iSP).fname,'-TT');
        tet = str2double(SP(iSP).fname(ix+3:ix+4));
        intan_channels = XL.INTAN(XL.TT==tet);
        %     intan_channels = [31 30 29 28];
        WV_long =INTAN_get_waveforms_in_dat_from_timestamps(dat_dir, intan_channels, ts_uS);
        % Add a new field to SP...
        SP(iSP).WV_LONG = WV_long;
        SP(iSP).WV_LONG_filt = filter_type;
        title(SP(iSP).fname)
%         
% 
%         WV_long(iSP).fname = SP(iSP).fname;
%         WV_long(iSP).data_dir = dat_dir;
%         WV_long(iSP).t_uS = ts_uS;
%         WV_long(iSP).Tetrode = SP(iSP).Tetrode;
%         WV_long(iSP).Cluster = SP(iSP).Cluster;
%         WV_long(iSP).Quality = SP(iSP).Quality;
%         WV_long(iSP).WV = SP(iSP).WV;
%         WV_long(iSP).WV_long = SP(iSP).WV_LONG;
%         WV_long(iSP).WV_long_filter_type = filter_type;
        
        iSP
    end
    save(fullfile(dat_dir,'..',['AllSpikes_longWV_' filter_type '.mat']),'SP')
%     delete *.dat
    return
end
% Load the channels for this signal...
load(fullfile(dat_dir,'Meta_data.mat'))
WV_long = [];
window_samples_before_after = round((window_ms_before_after/1000)*META.sFreq_amp);
for iF = 1:length(intan_channels)
    fname = fullfile(dat_dir, sprintf('amp-*-%03d.dat*',intan_channels(iF)));
    
    d = dir(fname);
    if ~isempty(d) % If .dat file for a channel does not exist skip it and assign zeros for that channel wv
        new_fname = fullfile(d(1).folder,d(1).name);
        if strcmpi(new_fname(end-3:end),'.zip')
            unzip(new_fname,dat_dir)
            new_fname = new_fname(1:end-4);
        end
%         L = INTAN_Read_DAT_file(new_fname);
        L = LoadIntanRaw(new_fname); % This load function converts to microvolts
        switch filter_type
            case 'ellip'
                L = Filter_for_spikes(L,META.sFreq_amp);
            case 'butter'
                L = Filter_for_spikes(L,META.sFreq_amp, [600 6000], 'butter');
            otherwise
                error('wrong filter type')
        end
        
%         if iF==1
            % If it's the first pass, set up some variables that only need to be
            % initialized once.
            t_uS = linspace(0,(length(L)-1)/META.sFreq_amp,length(L))*1e6;
            ix = binsearch_vector(t_uS, ts_uS);
            % get rid of spikes that are right at the start or end of the record
            ix = ix(ix > window_samples_before_after(1) & ix < (length(L) - window_samples_before_after(2) ));
            WV = zeros(length(ix),sum(window_samples_before_after)+1,length(intan_channels),'single');
%         end
        %    length(ix) - length(ix_new)
        for ii = 1:length(ix)
            WV(ii,:,iF) = L((ix(ii) -window_samples_before_after(1)):((ix(ii) + window_samples_before_after(2))));
        end
        WV_long.mn(iF,:) = mean(squeeze(WV(:,:,iF)));
        WV_long.sd(iF,:) = std(squeeze(WV(:,:,iF)));
        WV_long.se(iF,:) = Sem(squeeze(WV(:,:,iF)));
    else 
        WV_long.mn(iF,:) = zeros(1,58);
        WV_long.sd(iF,:) = zeros(1,58);
        WV_long.se(iF,:) = zeros(1,58);
    end
end


% Plot stuff
% figure
% clr = lines(size(WV,3));
% for iF = 1:size(WV,3)
%     plot_confidence_intervals(1000*(0:size(WV,2)-1)/META.sFreq_amp,WV(:,:,iF),[],clr(iF,:));
%     xlabel('ms')
% end