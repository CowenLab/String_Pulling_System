% Real-time Color-based object recognition and tracking system.
%
% Writing this again with OpenCV is probably not a bad idea
% Guts of the processing loop heavily based on "How to detect and track red, green and
% blue objects in Live Video" v 1.07 example by Arindam Bose


function AVT_Video_Acquisition()
% Initialize Camera
imaqreset;
vid = videoinput('gige', 1, 'RGB8Packed'); 
src = getselectedsource(vid);
initialize_camera();

controlWindow = figure('Toolbar','none',...
    'Menubar', 'none',...
    'NumberTitle','Off',...
    'Name','Acquisition Control',...
    'Resize','off',...
    'Units','normalized', ...
    'CloseRequestFcn', @(~,~) closeControlWindow,...
    'Position', [.2 .5 .15 .2]);

vidControlHandle = uicontrol('String', 'Open Camera',...
    'Callback',@(~,~) startVid(),...
    'Units','normalized', ...
    'Enable','on',...
    'Position',[0 .75 .6 .25]);

recControlHandle = uicontrol('String', 'Start Recording',...
    'Callback',@(~,~) startRec(),...
    'Units','normalized',...
    'Enable','off',...
    'Position',[0 .5 .6 .25]);

saveBaseHandle = uicontrol('String', 'Set Base Filename...',...
    'Callback',@(~,~) setFilename,...
    'Units','normalized', ...
    'Position',[0 .25 .6 .25]);

filetextbox = uicontrol('String', '',...
    'Style','edit',...
    'Units','normalized', ...
    'Enable','off',...
    'Position',[0 .15 .6 .1]);

avictl = uicontrol('String', 'Save Video File',...
    'Callback',@(~,~) savevidupdate,...
    'Style','checkbox',...
    'Units','normalized', ...
    'Position',[0 .05 .6 .1]);

uicontrol('String','Thresholds:',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Style','text',...
    'Units','normalized', ...
    'Position',[.65 .85 .35 .1]);

redSquare = uicontrol('BackgroundColor',[1 0 0],...
    'Style','text',...
    'Units','normalized', ...
    'Position',[.85 .7 .1 .1]);

redCheck = uicontrol('String', 'Red',...
    'Callback',@enableColorChannel,...
    'Style','checkbox',...
    'Units','normalized', ...
    'Position',[.65 .8 .35 .1]);

redSlider = uicontrol('Style','slider',...
    'Callback',@updateThresh,...
    'Units','normalized', ...
    'Position',[.65 .7 .075 .1]);

redEdit = uicontrol('Style','edit',...
    'Callback',@updateThresh,...
    'Units','normalized', ...
    'Position',[.725 .7 .12 .1]);

greenSquare = uicontrol('BackgroundColor',[0 1 0],...
    'Style','text',...
    'Units','normalized', ...
    'Position',[.85 .5 .1 .1]);

greenCheck = uicontrol('String', 'Green',...
    'Callback',@enableColorChannel,...
    'Style','checkbox',...
    'Units','normalized', ...
    'Position',[.65 .6 .35 .1]);

greenSlider = uicontrol('Style','slider',...
    'Callback',@updateThresh,...
    'Units','normalized', ...
    'Position',[.65 .5 .075 .1]);

greenEdit = uicontrol('Style','edit',...
    'Callback',@updateThresh,...
    'Units','normalized', ...
    'Position',[.725 .5 .12 .1]);

blueSquare = uicontrol('BackgroundColor',[0 0 1],...
    'Style','text',...
    'Units','normalized', ...
    'Position',[.85 .3 .1 .1]);

blueCheck = uicontrol('String', 'Blue',...
    'Callback',@enableColorChannel,...
    'Style','checkbox',...
    'Units','normalized', ...
    'Position',[.65 .4 .35 .1]);

blueSlider = uicontrol('Style','slider',...
    'Callback',@updateThresh,...
    'Units','normalized', ...
    'Position',[.65 .3 .075 .1]);

blueEdit = uicontrol('Style','edit',...
    'Callback',@updateThresh,...
    'Units','normalized', ...
    'Position',[.725 .3 .12 .1]);

uicontrol('String', 'Close',...
    'Callback',@(~,~) closeControlWindow,...
    'Units','normalized',...
    'Position',[.6 0 .4 .25]);

%Set default tracking channels (values applied after threshold defaults
%initialized)
trackEnabled{1} = 'on'; %Red channel tracking enabled
trackEnabled{2} = 'off'; %Green channel tracking enabled
trackEnabled{3} = 'on'; %Blue channel tracking enabled

redListener = addlistener(redSlider,'ContinuousValueChange',@updateThresh);
setappdata(redSlider,'sliderListener',redListener);

greenListener = addlistener(greenSlider,'ContinuousValueChange',@updateThresh);
setappdata(greenSlider,'sliderListener',greenListener);

blueListener = addlistener(blueSlider,'ContinuousValueChange',@updateThresh);
setappdata(blueSlider,'sliderListener',blueListener);

basename = 0;
recstate = 0; %Various callbacks can modify this number to alter the camera display/processing loop.
savevid = false; %Only initialized here. Callback from the "Save Video File" checkbox alters this.
deletecleanup = false; %Only initialized here. tells the processing loop to release the camera when it's done because we're going to close the program.

TRACKEXT = '.pos';
VIDEXT = '.avi';
path = [pwd '\'];
tracknamepath = [];
vidnamepath = [];

red = uint8([255 0 0]);
green = uint8([0 255 0]);
blue = uint8([0 0 255]);
yellow = uint8([255 255 0]);

%for UI, not detection
grey = [.75 .75 .75]; 
black = [0 0 0];

%Detection threshold Settings

DEFAULT_THRESH(1) = 0.24; % Default threshold for red detection
DEFAULT_THRESH(2) = 0.05; % Default threshold for green detection
DEFAULT_THRESH(3) = 0.35; % Default threshold for blue detection

for i = 1:3
    thresh(i) = DEFAULT_THRESH(i);
end

initializeTrackingParams();

warning('off','vision:transition:usesOldCoordinates');

hblob = vision.BlobAnalysis('AreaOutputPort', false, ... % Set blob analysis handling
    'CentroidOutputPort', true, ...
    'BoundingBoxOutputPort', true', ...
    'MinimumBlobArea', 10, ...
    'MaximumBlobArea', 3000, ...
    'MaximumCount', 1);
hshapeinsRedBox = vision.ShapeInserter('BorderColor', 'Custom', ... % Set Red box handling
    'CustomBorderColor', red, ...
    'Fill', true, ...
    'FillColor', 'Custom', ...
    'CustomFillColor', red, ...
    'Opacity', 0.4);
hshapeinsGreenBox = vision.ShapeInserter('BorderColor', 'Custom', ... % Set Green box handling
    'CustomBorderColor', green, ...
    'Fill', true, ...
    'FillColor', 'Custom', ...
    'CustomFillColor', green, ...
    'Opacity', 0.4);
hshapeinsBlueBox = vision.ShapeInserter('BorderColor', 'Custom', ... % Set Blue box handling
    'CustomBorderColor', blue, ...
    'Fill', true, ...
    'FillColor', 'Custom', ...
    'CustomFillColor', blue, ...
    'Opacity', 0.4);

% Apparently this is no longer working in post 2016 versions of matlab.

 htextinsCent = vision.TextInserter('Text', '+ X:%4d, Y:%4d', ... % set text for centroid
     'LocationSource', 'Input port', ...
     'Color', yellow, ...
     'Font', 'Courier New', ...
     'FontSize', 14);

    function initialize_camera()
        triggerconfig(vid, 'hardware', 'DeviceSpecific', 'DeviceSpecific'); % This and the following all need to be set to on.
        vid.FramesPerTrigger = 1;
        vid.TriggerRepeat = Inf;
         src.FrameStartTriggerMode = 'On';
        src.AcquisitionRecordTriggerMode = 'On';
        src.AcquisitionStartTriggerMode = 'On';
        src.FrameStartTriggerSource = 'Line1';
        src.AcquisitionRecordTriggerSource = 'Line1';
        src.AcquisitionStartTriggerSource = 'Line1';
        src.SyncOut1SyncOutSource = 'GPO'; %Outputs nothing (unless someone were to muck with camera EEPROM). Set to this so it stays quiet until recording begins.
        src.SyncOut2SyncOutSource = 'GPO';  %Outputs nothing, but can flip "off is low" to "off is high" to flag recording if uncommented below
        src.SyncOut2SyncOutPolarity = 'Normal';%Set "off is low"
        src.Gain = 15;
        src.GainAuto = 'Off';
        src.BalanceWhiteAuto = 'Continuous';
        src.ExposureAuto = 'Off';
        src.ExposureMode = 'Timed';
        src.ExposureTimeAbs = 8123; % needs to be smaller for the fast framerate. The default is far too long.
    end

    function startVid()
        set(vidControlHandle,'string','Close Camera','Callback',@(~,~) stopVid());
                
        if (basename ~= 0)
            set(recControlHandle,'Enable','on');
        else
            set(recControlHandle,'Enable','off');
        end    
        hvpc = vision.DeployableVideoPlayer('Name','Video Window','FrameRate',40);
        
        fprintf('\n');
        disp('Camera ready for acquisition...');
        fprintf('\n');       
        newNum = 0;
        oldNum = 0;
        skipped = [];
        
        start(vid);
        while(isrunning(vid))
            if (recstate == 1)
                stop(vid)
                % Switch First TTL output to mirror external trigger--will now appear on video synch output
                src.SyncOut1SyncOutSource = 'Exposing';
                % Switch Second TTL output to signal that recording is in
                % progress--Arduino will recognize that this means the
                % camera software is recording
                %src.SyncOut2SyncOutPolarity = 'Invert'; %Switch "off is low" to "off is high" on an always-off internal camera signal.
                
                %Reset missed counter
                newNum = 0;
                oldNum = 0;
                skipped = [];
                recstate = 2;
                set(avictl,'Enable','off')
                
                %Get unique timestamp for outputfiles.
                timename = strcat(basename,'_', datestr(now,'yymmdd-HHMMSS'));
                
                if(savevid)
                    %Set up logging to disk. Doing this like this so we can
                    %insert a timestamp onto each frame.
                    vidnamepath = strcat(path,timename, VIDEXT);
                    vidOut = vision.VideoFileWriter(vidnamepath,'FrameRate',36.588,'VideoCompressor','DV Video Encoder');
                end
                
                %Set up real-time tracking position filename
                tracknamepath = strcat(path,timename, TRACKEXT);
                fileID = fopen(tracknamepath,'w');
                fprintf(fileID,'%2s\t%2s\t%2s\t%2s\t%2s\t%2s\t%8s\r\n','Rx','Ry','Gx','Gy', 'Bx','By','Time (s)');
                
                %Start video again.
                disp(['Acquisition Started ' datestr(now,'HH:MM:SS:FFF')])
                fprintf('\n');
                start(vid)
            end
            if (recstate == -1)
                    stop(vid);
                    src.SyncOut1SyncOutSource = 'GPO';
                    %src.SyncOut2SyncOutPolarity = 'Normal';
                    recordingstopped();
                    recstate = 0;
                    start(vid);
            end                        
            while get(vid,'FramesAvailable')<1
                %Wait until at least 1 frame is available
            end
            if (get(vid,'FramesAvailable') > 100) %Clears the Buffer <---------------
                flushdata(vid,'triggers') % Deletes frame(s) from memory associated with oldest trigger
            end
            
            [rgbFrame, elapsedtime , events]=getdata(vid,1,'uint8'); %actually get a frame
            
            newNum = events.TriggerIndex;
            
            if (oldNum + 1 ~= newNum)
                skipped = [skipped oldNum+1:newNum-1];
                if recstate == 2
                    disp('Padding Missed Frame.')
                    fprintf(fileID,'%d\t%d\t%d\t%d\t%d\t%d\t%f',[],[],[],[],[],[],[]);
                    fprintf(fileID,'\r\n'); %Add empty data in the position file in the highly unlikely event we can't keep up with the camera
                    if savevid
                        step(vidOut,rgbFrame*0); %Add an empty frame in the video file in the highly unlikely event we can't keep up with the camera
                    end
                end
            end
            oldNum = newNum;
            
            diffFrameRed = imsubtract(rgbFrame(:,:,1), rgb2gray(rgbFrame)); % Get red component of the image
            diffFrameRed = medfilt2(diffFrameRed, [3 3]); % Filter out the noise by using median filter
            binFrameRed = im2bw(diffFrameRed, thresh(1)); % Convert the image into binary image with the red objects as white
            
            diffFrameGreen = imsubtract(rgbFrame(:,:,2), rgb2gray(rgbFrame)); % Get green component of the image
            diffFrameGreen = medfilt2(diffFrameGreen, [3 3]); % Filter out the noise by using median filter
            binFrameGreen = im2bw(diffFrameGreen, thresh(2)); % Convert the image into binary image with the green objects as white
            
            diffFrameBlue = imsubtract(rgbFrame(:,:,3), rgb2gray(rgbFrame)); % Get blue component of the image
            diffFrameBlue = medfilt2(diffFrameBlue, [3 3]); % Filter out the noise by using median filter
            binFrameBlue = im2bw(diffFrameBlue, thresh(3)); % Convert the image into binary image with the blue objects as white
            
            [centroidRed, bboxRed] = step(hblob, binFrameRed); % Get the centroids and bounding boxes of the red blobs
            centroidRed = uint16(centroidRed); % Convert the centroids into Integer for further steps
            
            [centroidGreen, bboxGreen] = step(hblob, binFrameGreen); % Get the centroids and bounding boxes of the green blobs
            centroidGreen = uint16(centroidGreen); % Convert the centroids into Integer for further steps
            
            [centroidBlue, bboxBlue] = step(hblob, binFrameBlue); % Get the centroids and bounding boxes of the blue blobs
            centroidBlue = uint16(centroidBlue); % Convert the centroids into Integer for further steps
            
            if savevid && recstate == 2
                step(vidOut,rgbFrame);
            end
            
            %^^^^At this point, you now have the coordinates for each color
            % channel. Here would be a good place to add other processing
            % stuff like "if the blue is inside some predefined box then do
            % a thing" etc.
            
            vidIn = step(hshapeinsRedBox, rgbFrame, bboxRed); % Insert red box
            vidIn = step(hshapeinsGreenBox, vidIn, bboxGreen); % Insert green box
            vidIn = step(hshapeinsBlueBox, vidIn, bboxBlue); % Insert blue box
            
            centXRed = [];
            centYRed = [];
            if length(centroidRed)>0;
                centXRed = centroidRed(1,1); centYRed = centroidRed(1,2);
                vidIn = step(htextinsCent, vidIn, [centXRed centYRed], [centXRed-6 centYRed-9]);
            end
            
            centXGreen = [];
            centYGreen = [];
            if length(centroidGreen)>0;
                centXGreen = centroidGreen(1,1); centYGreen = centroidGreen(1,2);
                vidIn = step(htextinsCent, vidIn, [centXGreen centYGreen], [centXGreen-6 centYGreen-9]);
            end
            
            centXBlue = [];
            centYBlue = [];            
            if length(centroidBlue)>0;
                centXBlue = centroidBlue(1,1); centYBlue = centroidBlue(1,2);
                vidIn = step(htextinsCent, vidIn, [centXBlue centYBlue], [centXBlue-6 centYBlue-9]);
            end
            
            if (recstate == 2)
                fprintf(fileID,'%d\t%d\t%d\t%d\t%d\t%d\t%f',centXRed,centYRed,centXGreen,centYGreen,centXBlue,centYBlue,elapsedtime);
                fprintf(fileID,'\r\n');
            end
            step(hvpc,vidIn); %steps the image that the user sees -----------------------------
            %Stop the camera if somebody closed the video window.
            if isempty(findall(0,'Tag', get(hvpc,'figureID'))) %A listener would be better but we're already in the loop before this thing has figure axes. Catch 22
                stopVid();
            end
        end
        
        release(hvpc);
        
        if (recstate == 2)
            recordingstopped();
            recstate = 0;
        end
        
        if (deletecleanup)
            delete(vid)
            imaqreset;
        end
                
        function recordingstopped()
            %Enable changing filenames again
            if (~deletecleanup)
                set(saveBaseHandle,'Enable','on');
                set(avictl,'Enable','on');
            end
            
            %Close Open Files
            fclose(fileID);
            if savevid
                release(vidOut);
            end
            
            disp(['Acquisition Stopped ' datestr(now,'HH:MM:SS:FFF')])
            fprintf('\n');
            
            %Reveal our shame :[
            if ~isempty(skipped)
                disp(['Frames Missed: ' num2str(skipped)]);
                fprintf('\n')
            end
        end
    end

    function stopVid()
        set(vidControlHandle,'string','Open Camera','Callback',@(~,~) startVid());
        set(recControlHandle,'Enable','off','string','Start Recording','Callback',@(~,~) startRec());
        stop(vid);
    end

    function startRec()
            set(recControlHandle,'string','Stop Recording','Callback',@(~,~) stopRec());
            set(saveBaseHandle,'Enable','off');
            recstate = 1; %Stop the preview and switch to recording mode (recstate 2)
    end

    function stopRec()
        recstate = -1; %Stop the recording and return to preview mode (recstate 0)
        set(recControlHandle,'string','Start Recording','Callback',@(~,~) startRec());
    end

    function setFilename()
        [basename,path] = uiputfile(['*' TRACKEXT],'Set Base Save Filename...');
        if (basename ~= 0)
            basename = basename(1:(end-length(TRACKEXT))); %Take the extension off so we can muck with the filename and add it back on later.
            set(filetextbox,'String',basename);
            if (isrunning(vid))
                set(recControlHandle,'Enable','on');
            end
        else
            set(recControlHandle,'Enable','off');
            set(filetextbox,'String','');
        end
    end

    function savevidupdate()
        savevid = get(avictl, 'Value');
    end

    function enableColorChannel(src,~)
        [ind,square,slider,edit,check] = colorFromSrc(src);
        color = [0 0 0];
        switch get(check,'Value')
            case true
                set(check,'ForegroundColor',black);
                trackEnabled{ind} = 'on';
                thresh(ind) = get(slider,'Value'); %Slider will "remember" the set threshold while disabled.
                color(ind) = 1 - thresh(ind);
            case false
                set(check,'ForegroundColor',grey);
                trackEnabled{ind} = 'off';
                thresh(ind) = 1;
                color = grey;
        end
        set(slider,'Enable',trackEnabled{ind});
        set(edit,'Enable',trackEnabled{ind});
        set(square,'BackgroundColor',color);
    end

    function updateThresh(src,~)
       
        [ind,square,slider,edit,~] = colorFromSrc(src);
        color = [0 0 0];       
        %Find what kind of src we are so we can set the other, too.
        switch get(src,'Style')
            case 'edit'
                str=get(src,'String');
                if goodnum(str)
                    value = str2num(str);
                    value = round(value*100)/100;
                    thresh(ind) = value;
                    set(edit,'string',value);
                    set(slider,'Value',value);
                    
                    color(ind) = 1-value;
                    set(square,'BackgroundColor',color);
                else
                    set(src,'string',num2str(thresh(ind)));
                end
            case 'slider'
                value = get(src,'Value');
                thresh(ind) = value;
                set(edit,'String',num2str(value));
                color(ind) = 1-value;
                set(square,'BackgroundColor',color);
        end
        
        
        function bln = goodnum(checkstr)
            num = str2num(checkstr);
            bln = false;
            if ~isempty(num) && num <= 1 && num >=0
                bln = true;
            end
        end
    end

    function [ind,square,slider,edit,check] = colorFromSrc(source)
        %Goddamn callback functions and arguments and stuff...
        if source == redEdit || source == redSlider || source == redCheck
            ind = 1;
            slider = redSlider;
            edit = redEdit;
            check = redCheck;
            square = redSquare;
        elseif source == greenEdit || source == greenSlider || source == greenCheck
            ind = 2;
            slider = greenSlider;
            edit = greenEdit;
            check = greenCheck;
            square = greenSquare;
        elseif source == blueEdit || source == blueSlider || source == blueCheck
            ind = 3;
            slider = blueSlider;
            edit = blueEdit;
            check = blueCheck;
            square = blueSquare;
        end
    end

    function initializeTrackingParams()
        set(redSlider,'Value',thresh(1),'Enable',trackEnabled{1});
        set(redEdit,'String',num2str(thresh(1)),'Enable',trackEnabled{1});
        if (strcmp(trackEnabled{1},'on'))
            set(redCheck,'Value',true);
            set(redSquare,'BackgroundColor',[1-thresh(1) 0 0]);
        else
            thresh(1) = 1;
            set(redCheck,'ForegroundColor',grey);
            set(greenSquare,'BackgroundColor',grey);
        end
        
        set(greenSlider,'Value',thresh(2),'Enable',trackEnabled{2});
        set(greenEdit,'String',num2str(thresh(2)),'Enable',trackEnabled{2});
        if (strcmp(trackEnabled{2},'on'))
            set(greenCheck,'Value',true);
            set(greenSquare,'BackgroundColor',[0 1-thresh(2) 0]);
        else
            thresh(2) = 1;
            set(greenCheck,'ForegroundColor',grey);
            set(greenSquare,'BackgroundColor',grey);
        end
        
        set(blueSlider,'Value',thresh(3),'Enable',trackEnabled{3});
        set(blueEdit,'String',num2str(thresh(3)),'Enable',trackEnabled{3});
        if (strcmp(trackEnabled{3},'on'))
            set(blueCheck,'Value',true);
            set(blueSquare,'BackgroundColor',[0 0 1-thresh(3)]);
        else
            thresh(3) = 1;
            set(blueCheck,'ForegroundColor',grey);
            set(blueSquare,'BackgroundColor',grey);
        end
    end


    function closeControlWindow()
        if (isrunning(vid))
            deletecleanup = true;
            stopVid();
        else
            imaqreset;
        end
        % Close the figure window
        clearvars -global;
        delete(controlWindow);
    end

end