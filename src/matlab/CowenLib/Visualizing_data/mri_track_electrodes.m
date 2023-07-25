function mri_track_electrodes(option, parameters)
% MRI_EXPORTALL_RAW  read a raw mri file and creates graphic files for all frontal slices
%              this file is a script which you will need to edit with your filename and
%              data dimensions.  All edit-worthy parameters are in the first section of code
%              these files can then be imported into powerpoint, making a very nice slice-viewer
%              for browsing the brain.
%
%              Scaling of the image is a bit tricky.  The display routine expects values
%              between 0 (black) and 1 (white).  Because matlab uses only 64 luminance values
%              you will need to specify a 'montage_divisor' which is simply the number that your
%              data will be divided by before display.  This lets you fit your data so that the 
%              interesting features are in the dynamic range of matlab graphics.
%              For example, if your data range from 
%              0 to 240000, you might want to use a divisor of 20000. 
%              Values over 20000 will then be converted to values above 1 and will
%              all be displayed at the value of 1 (white).
%              It is helpful to run a histogram on your raw luminosity values
%              to determine this scaling factor (e.g., hist(raw_data))
%
% TO ADD: Preserve zoom when you press the hide;/show button.
%         Allow group delete and rename by convex hulls
%         Allow quick scrolling through sections.
%         Preserve the previous zoom on these slices.
% EDITTABLE PARAMETERS
global GP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constants:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==0
    option = 'initialize';
    parameters = [];
end
if nargin==1
    parameters = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch option
    case 'run'
        mri_track_electrodes('make_form');
    case 'load_ED'
        [filename, pathname] = uigetfile('Ele*.mat', 'Pick a data file');
        if ~isempty(filename) 
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Load the electrode data.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            tmp = load(filename);
            GP.ED = tmp.ED;
        end
        mri_track_electrodes('make_form');
    case 'initialize'
        GP.fh = figure
        GP.slice = 120;
        GP.plane = 'dv';
        GP.slice_plane = [num2str(GP.slice) GP.plane];
        GP.rand_num = rand(1,1)*1000;
        GP.show_hide = 1;
        GP.savefilename = ['Electrode_data' num2str(GP.rand_num) '.mat'];
        % GP.ED.good_range_ap = 16:243;
        % GP.ED.good_range_ml = 45:201; %
        % GP.ED.good_range_dv = 37:212;
        % Bregma location:
        GP.ED.bregma_slice_ap = 76; % somewhere between 72-78
        GP.ED.bregma_slice_dv = 0;
        GP.ED.bregma_slice_ml = 116;
        GP.ED.pixel_size_mm = 100/255;
        GP.ED.track_info_ap_ml_dv_ID_pl = [];
        disp('Loading the vol_data')
        GP.MRI_DATA = mri_load_data('2dseq');
        mri_track_electrodes('make_form');
    case 'calibrate'    
        x_or_y = questdlg('Calibration in x (horizontal) or y (vertical)?', ...
            'Genie Question', ...
            'x','y','...');
        
        title('Enter 2 points: Left and Right','Color','w')
        [x1,y1] = ginput(1)
        plot(x1,y1,'+k','MarkerSize',10)
        [x2,y2] = ginput(1)
        plot(x2,y2,'+k','MarkerSize',10)
        dist_mm = inputdlg('Enter the distance between the points (mm) ');
        dist_mm = str2num(dist_mm{1});
        switch x_or_y
            case 'x'
                GP.ED.pixel_size_mm = abs(x2 - x1)/dist_mm;
            case 'y'
                GP.ED.pixel_size_mm = abs(y2 - y1)/dist_mm;
        end
        
    case 'set_bregma'    
        title('Set Bregma','Color','w')
        [x,y] = ginput(1);
        switch GP.plane
            case 'ap'
                %GP.ED.bregma_slice_ap = slice; % somewhere between 72-78
                GP.ED.bregma_slice_ml = x;
            case 'ml'
                GP.ED.bregma_slice_ap = y; % somewhere between 72-78
            case 'dv'
                GP.ED.bregma_slice_ap = y; % somewhere between 72-78
                GP.ED.bregma_slice_ml = x;
        end
        mri_track_electrodes('make_form');
    case 'hide_show'
        GP.show_hide = GP.show_hide + 1;
        if GP.show_hide == 3
            GP.show_hide = 0
        end
        mri_track_electrodes('make_form');
        
    case 'change_plane'
        GP.slice_plane  = get(gcbo,'String');
        GP.slice = str2num(GP.slice_plane(1:end-2));
        GP.plane = GP.slice_plane(end-1:end);
        mri_track_electrodes('make_form');
        %draw_plane(GP.slice,GP.plane)
    case 'find_track'
        slice_count = 1;
        title([GP.slice_plane ' Enter electrode tracks. Click below image to quit.'],'Color','w')
        x = 10; y=10;
        [x,y] = ginput(1);
        a = axis;
        plot(x,y,'y*')
        hold on
        plot(x,y,'go')
        if ~isempty(GP.ED.track_info_ap_ml_dv_ID_pl)
            ID = inputdlg({['Electrode ID (max= ' num2str(max(GP.ED.track_info_ap_ml_dv_ID_pl(:,4))) ' )']},'TRACK INFO');
        else
            ID = inputdlg({'Electrode ID:'},'TRACK INFO');
        end
        h  = text(x,y,ID);
        ID = str2num(ID{1});
        set(h,'FontWeight','bold')
        set(h,'Color','w')
        set(h,'FontSize',14)
        switch GP.plane
            case 'ap'
                ap = GP.slice;
                dv = y;
                ml = x;
                pl = 1;
            case 'ml'
                ap = x;
                dv = y;
                ml = GP.slice;
                pl = 2;
            case 'dv'
                ap = y;
                dv = GP.slice;
                ml = x;
                pl = 3;
        end
        GP.ED.track_info_ap_ml_dv_ID_pl = [GP.ED.track_info_ap_ml_dv_ID_pl ; [ap ml dv ID pl]];
        title('Saving Files')
        ED = GP.ED;
        save(GP.savefilename, 'ED')
        title(GP.slice_plane)
    case 'rename_track'
        ID = inputdlg({['Former ID '] ['New ID']},'');
        idx = find(GP.ED.track_info_ap_ml_dv_ID_pl(:,4)== str2num(ID{1}));
        GP.ED.track_info_ap_ml_dv_ID_pl(idx,4) = str2num(ID{2});

    case 'make_form'
        
        uicHeight = 0.04;
        uicWidth  = 0.08;
        YLocs = [0.97];
        XLocs = 0.05:uicWidth:(0.95-uicWidth);
        figure(GP.fh)
        clf
        %-------------------------------
        draw_plane(GP.slice,GP.plane)
        title([GP.slice_plane ' CHOOSE AN OPTION TO START'],'Color','w')
        
        set(GP.fh,'Position', [333-331 83 1214-331 840]); % Modal hangs things until you return.
        % -------------------------------
        % waveform cutter buttons
        % -------------------------------
        uicontrol('Parent', GP.fh, ...
            'Units', 'Normalized', 'Position', [XLocs(1) 0.05 uicWidth uicHeight], ...
            'Style', 'pushbutton', 'Tag', 'Calibrate', 'String', 'Load Data', 'Callback', 'mri_track_electrodes(''load_ED'')', ...
            'TooltipString', 'Load previously saved data.');
        uicontrol('Parent', GP.fh, ...
            'Units', 'Normalized', 'Position', [XLocs(2) 0.05 uicWidth uicHeight], ...
            'Style', 'pushbutton', 'Tag', 'Calibrate', 'String', 'Calibrate', 'Callback', 'mri_track_electrodes(''calibrate'')', ...
            'TooltipString', 'Calibrate-- find the size of each pixel (Voxel).');
        uicontrol('Parent', GP.fh, ...
            'Units', 'Normalized', 'Position', [XLocs(3) 0.05 uicWidth uicHeight], ...
            'Style', 'pushbutton', 'Tag', 'set_bregma', 'String', 'Bregma', 'Callback', 'mri_track_electrodes(''set_bregma'')', ...
            'TooltipString', 'Find 0,0 Bregma');
        uicontrol('Parent', GP.fh, ...
            'Units', 'Normalized', 'Position', [XLocs(4) 0.05 uicWidth uicHeight], ...
            'Style', 'pushbutton', 'Tag', 'track_electrode', 'String', 'Track', 'Callback', 'mri_track_electrodes(''find_track'')', ...
            'TooltipString', 'Track the electrode tracks.');
        uicontrol('Parent', GP.fh, ...
            'Units', 'Normalized', 'Position', [XLocs(5) 0.05 uicWidth uicHeight], ...
            'Style', 'pushbutton', 'Tag', 'quit', 'String', 'Hide/Show', 'Callback', 'mri_track_electrodes(''hide_show'')', ...
            'TooltipString', '');      
        uicontrol('Parent', GP.fh, ...
            'Units', 'Normalized', 'Position', [XLocs(6) 0.05 uicWidth uicHeight], ...
            'Style', 'text', 'String', 'Change Plane:');
        uicontrol('Parent', GP.fh, ...
            'Units', 'Normalized', 'Position', [XLocs(7) 0.05 uicWidth uicHeight], ...
            'Style', 'edit', 'String', GP.slice_plane, 'Tag', 'change_plane', ...
            'Callback', 'mri_track_electrodes(''change_plane'')', ...
            'TooltipString', 'Change plane');
        uicontrol('Parent', GP.fh, ...
            'Units', 'Normalized', 'Position', [XLocs(8) 0.05 uicWidth uicHeight], ...
            'Style', 'pushbutton', 'Tag', 'quit', 'String', 'Rename Track', 'Callback', 'mri_track_electrodes(''rename_track'')', ...
            'TooltipString', '');      
        uicontrol('Parent', GP.fh, ...
            'Units', 'Normalized', 'Position', [XLocs(end) 0.05 uicWidth uicHeight], ...
            'Style', 'pushbutton', 'Tag', 'quit', 'String', 'quit', 'Callback', 'mri_track_electrodes(''quit'')', ...
            'TooltipString', '');

    case 'quit'    
        close(GP.fh)
    otherwise
        option
        error('Wrong option')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function draw_plane(slice,plane)
global GP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(GP.fh)
clf
switch plane
    case 'ap'
        cur_slice = squeeze(GP.MRI_DATA(:,slice,:));
        imagesc(cur_slice');
        hold on
        set(gca,'DataAspectRatio',[25 49.5 1])
        a = axis;
        plot([GP.ED.bregma_slice_ml GP.ED.bregma_slice_ml], [a(3) a(4)],'w:')
        % Plot the previous points.
        if (GP.show_hide > 0)
            for ii = 1:Rows(GP.ED.track_info_ap_ml_dv_ID_pl)
                
                h = text(GP.ED.track_info_ap_ml_dv_ID_pl(ii,2),GP.ED.track_info_ap_ml_dv_ID_pl(ii,3),num2str(GP.ED.track_info_ap_ml_dv_ID_pl(ii,4)));
                set(h,'FontWeight','bold')
                set(h, 'Color', 'w')
                if (GP.show_hide > 1)
                    if (GP.ED.track_info_ap_ml_dv_ID_pl(ii,1) == cur_slice)
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,2),GP.ED.track_info_ap_ml_dv_ID_pl(ii,3),'w*')
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,2),GP.ED.track_info_ap_ml_dv_ID_pl(ii,3),'go')
                    else
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,2),GP.ED.track_info_ap_ml_dv_ID_pl(ii,3),'yo')
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,2),GP.ED.track_info_ap_ml_dv_ID_pl(ii,3),'m+')
                    end
                end
            end
        end
    case 'ml'
        cur_slice = squeeze(GP.MRI_DATA(slice,:,:));
        imagesc(cur_slice');
        set(gca,'DataAspectRatio',[25 49.5 1])
        hold on
        a = axis;
        plot([GP.ED.bregma_slice_ap GP.ED.bregma_slice_ap], [a(3) a(4)],'w:')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Plot the previous points.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if (GP.show_hide > 0)
            for ii = 1:Rows(GP.ED.track_info_ap_ml_dv_ID_pl)
                h = text(GP.ED.track_info_ap_ml_dv_ID_pl(ii,1),GP.ED.track_info_ap_ml_dv_ID_pl(ii,3),num2str(GP.ED.track_info_ap_ml_dv_ID_pl(ii,4)))
                set(h,'FontWeight','bold')
                set(h, 'Color', 'w')
                if (GP.show_hide > 1)
                    if (GP.ED.track_info_ap_ml_dv_ID_pl(ii,2) == cur_slice)
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,1),GP.ED.track_info_ap_ml_dv_ID_pl(ii,3),'w*')
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,1),GP.ED.track_info_ap_ml_dv_ID_pl(ii,3),'go')
                    else
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,1),GP.ED.track_info_ap_ml_dv_ID_pl(ii,3),'yo')
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,1),GP.ED.track_info_ap_ml_dv_ID_pl(ii,3),'m+')
                    end
                end
            end
        end
    case 'dv'
        cur_slice = squeeze(GP.MRI_DATA (:,:,slice));
        imagesc(cur_slice');
        hold on
        a = axis;
        plot([GP.ED.bregma_slice_ml GP.ED.bregma_slice_ml], [a(3) a(4)],'w:')
        plot([a(3) a(4)],[GP.ED.bregma_slice_ap GP.ED.bregma_slice_ap] ,'y:')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % No re-interpolating necessary.
        % Plot the previous points.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if (GP.show_hide > 0)
            for ii = 1:Rows(GP.ED.track_info_ap_ml_dv_ID_pl)
                h = text(GP.ED.track_info_ap_ml_dv_ID_pl(ii,2),GP.ED.track_info_ap_ml_dv_ID_pl(ii,1),num2str(GP.ED.track_info_ap_ml_dv_ID_pl(ii,4)))
                set(h, 'Color', 'w')
                set(h,'FontWeight','bold')
                if (GP.show_hide > 1)
                    if (GP.ED.track_info_ap_ml_dv_ID_pl(ii,3) == cur_slice)
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,2),GP.ED.track_info_ap_ml_dv_ID_pl(ii,1),'w*')
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,2),GP.ED.track_info_ap_ml_dv_ID_pl(ii,1),'go')
                    else
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,2),GP.ED.track_info_ap_ml_dv_ID_pl(ii,1),'yo')
                        plot(GP.ED.track_info_ap_ml_dv_ID_pl(ii,2),GP.ED.track_info_ap_ml_dv_ID_pl(ii,1),'m+')
                    end
                end
            end
        end
    otherwise
        error('Incorrect plane')
       
end
c = caxis;
c(1) = 1000;
c(2) = min([c(2) 24000]);
caxis(c);
axis equal;
%axis off;
%colormap(gray);
set(gca, 'xcolor', 'w');
set(gca, 'ycolor', 'w');
set(gca, 'color', 'none'); 
set(gcf, 'color', 'k');
title(['slice: ' num2str(slice)],'Color','w')
%text(3,dim_dv-5,['slice: ' num2str(slice)], 'color', [1 1 1]);
return