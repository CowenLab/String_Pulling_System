function [POS, POS_info] = INTAN_Sync_DeepLabCut_csv_to_Intan(dlc_csv_file_path, intan_sync_times, camera_name, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function OUT = INTAN_Sync_DeepLabCut_csv_to_Intan(dlc_csv_file_path,
%                 intan_sync_times, camera_name, varargin)
%
% The frame events will be displayed and the user will be asked to verify
% that the timestamps look OK. If not, then it will attempt to fix things
% by identifying the largest contiguous block. If there are multiple good
% blocks, then the code will NOT WORK.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
%   full path to the dlc file
%   list of sync timestamps (IN uS) recorded on the intan system. There should be a
%     one-to-one relationship between these timestamps and the rows (records)
%     in the .csv file. In practice, there can be a few missing frames.
%   camera_name = text string (no spaces) with the name of the camera (e.g., 'Top_Camera')
%
% OUTPUT:
%   a new table with the first column indicating the timestamp of each
%   frame in uS.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine variable names.
PLOT_IT = true;
% this is the thresh for determining disgcontiguous time blocks.
thresh_uS = 1e6/20; % let's say 1/20th of a second. Should cover the
% resolution of the front and top camera.
Extract_varargin;

updated_frame_times_uS = [];
all_OK = false;
dlc_dir = fileparts(dlc_csv_file_path);

[TBL, TBL_info] = DLC_read_DLC_csv_file(dlc_csv_file_path);

if PLOT_IT
    bad_ix = find(diff(intan_sync_times)>thresh_uS);
    
    figure
    subplot(2,3,1:3)
    plot(intan_sync_times/60e6,zeros(size(intan_sync_times)),'.','MarkerSize',1)
    hold on
    plot(intan_sync_times(bad_ix)/60e6,zeros(size(bad_ix)),'ro')
    
    xlabel('minutes')
    subplot(2,3,4)
    plot(TBL.Nose_x,TBL.Nose_y,'.','MarkerSize',1)
    subplot(2,3,5)
    histogram(diff(intan_sync_times)/1000)
    xlabel('intan inter-pulse ms')
    answer = questdlg('Do the timestamps look correct?','Answer', 'Yes','No','No');
    % Handle response
    switch answer
        case 'Yes'
            all_OK = true;
        case 'No'
            all_OK = false;
    end
    if ~all_OK
        answer = inputdlg({'How many good blocks are there?'},'Input',[1 35], {'1'});
        answer = str2double(answer{1});
                        
        figure
        plot(intan_sync_times,zeros(size(intan_sync_times)),'.','MarkerSize',5)
        hold on
        plot(intan_sync_times(bad_ix),zeros(size(bad_ix)),'ro')
        
        title('Click somewhere WITHIN each good block. Will backtrack to start.')
        x = ginput(answer);
        x = x(:,1);
        %%%%%%%%%%
        diffs = [thresh_uS*.9 diff(intan_sync_times(:))'];
        first_last_ix = nan(length(x),2);
        good_ix = [];

        for ii = 1:length(x)
            ix_first = find(diffs(:) > thresh_uS & intan_sync_times(:)<x(ii),1,'last');
            if isempty(ix_first)
                ix_first = 1;
            end
            ix_last = find(diffs(:) > thresh_uS & intan_sync_times(:)>x(ii),1,'first');
            if isempty(ix_last)
                ix_last = length(intan_sync_times);
            else
                ix_last = ix_last - 1; % trust me, you need this.
            end
            first_last_ix(ii,:) = [ix_first ix_last];
            good_ix = [good_ix ix_first:ix_last];
        end
  
        disp('First and last timestamps are ')
        disp(first_last_ix)
        updated_frame_times_uS = intan_sync_times(good_ix);
        plot(updated_frame_times_uS,zeros(size(updated_frame_times_uS)),'g.','MarkerSize',2)
        
    end
    
end

if ~isempty(updated_frame_times_uS)
    intan_sync_times = updated_frame_times_uS;
end

IPIms = diff(intan_sync_times)/1000;
sprintf('n vid recs: %d, n ttl pulses %d, min IPI %f, max IPI %f',size(TBL,1),length(intan_sync_times), ...
    min(IPIms),max(IPIms))
d = length(TBL.Nose_x) - length(intan_sync_times);

if d~=0
    disp(['WARNING: Discrepancy of ' num2str(d) ' recs. pos means more in DLC, neg means more TTLs'])
end
% Goint to assume that the first record is correct.
min_ix = min([Rows(TBL) length(intan_sync_times)]);
Intan_uS = nan(size(TBL,1),1);
Intan_uS(1:min_ix) = intan_sync_times(1:min_ix);

POS = addvars(TBL,Intan_uS,'Before',1);
POS_info = DLC_extract_body_parts_and_coordinates_from_tbl(POS.Properties.VariableNames);
% Identify epochs as periods when the inter-pulse interval was > 1 minute.
d = diff(Intan_uS/60e6);
epoch_ix = find(d > 1); % assume epochs have a delay of at least one minute.
est_epoch_time_uS = [Intan_uS(1); Intan_uS(epoch_ix); Intan_uS(end)];
% Save important information
POS_info.est_epoch_time_uS = est_epoch_time_uS;
POS_info.camera_name = camera_name;
POS_info.dlc_csv_file_path = dlc_csv_file_path;
POS_info.updated_frame_times_uS = updated_frame_times_uS;
POS_info.POS_file_path = fullfile(dlc_dir,[camera_name '_Pos.mat']);
% Save the 'workhorse' position data file.
save(POS_info.POS_file_path,'POS', 'POS_info')
sprintf('Saved POS data in %s',POS_info.POS_file_path)

clrs = lines(10);
if PLOT_IT
    head(POS)
    u_body = unique(POS_info.body_part);
    figure
    for ii = 1:length(est_epoch_time_uS)-1
        IX = POS.Intan_uS >= est_epoch_time_uS(ii) & POS.Intan_uS<est_epoch_time_uS(ii+1);
        subplot(1,length(est_epoch_time_uS)-1,ii)
        for iB = 1:length(u_body)
            plot(POS.([u_body{iB} '_x'])(IX),POS.([u_body{iB} '_y'])(IX),'.','MarkerSize',1,'Color',clrs(iB,:))
            hold on
        end
        if ii == 1
            legend(u_body)
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%