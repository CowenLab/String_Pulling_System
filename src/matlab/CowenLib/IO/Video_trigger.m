function Video_trigger()
% Triggers the video camera and acquires video.
% Assumes that you have the DAQ toolbox and the video acquisition toolobox.
%%
%imaqtool
% YOU NEED: (for GigE cameras) a Matlab toolbox.
% http://www.alliedvisiontec.com/us/products/software/3rd-party-solutions/mathworks.html
% AVTMatlabAdaptor_2_0_0.dll
% Find the camera
all_adapters = imaqhwinfo;
vid = videoinput('gige', 1, 'RGB8Packed');
src.FrameStartTriggerSource = 'Line1';
src = getselectedsource(vid);
src.ExposureTimeAbs = 8123; % needs to be smaller for the fast framerate. The default is far too long.
vid.LoggingMode = 'disk';
diskLogger = VideoWriter('G:\temp\xxxx.mp4', 'MPEG-4'); % It does keep each frame. 
vid.DiskLogger = diskLogger;
triggerconfig(vid, 'hardware', 'DeviceSpecific', 'DeviceSpecific');
vid.TriggerRepeat = Inf;
src.FrameStartTriggerMode = 'on'; % Needs to be set to on.
start(vid);
% When done, do this... stop(vid);
pause(10.0)
stop(vid);


%% Trigger pin.

devices = daq.getDevices;
s_out = daq.createSession('ni');
addDigitalChannel(s_out,'Dev1','port1/line0','OutputOnly')
outputSingleScan (s_out,1) % inverted for opto-isolator.

%s.addAnalogOutputChannel('Dev1', 0, 'Voltage');
%%
off_delay_s = 0.014; %0.014
on_delay_s = 0.0001;  %0.0001
tic
for ii = 1:1500
    outputSingleScan (s_out,1) % inverted for opto-isolator.
    pause(off_delay_s) % results in an effective frame rate of about 30fps.
    outputSingleScan (s_out,0)
    pause(on_delay_s)
    %fprintf('%d.\n',ii)
end
outputSingleScan (s_out,1) % inverted for opto-isolator.
toc
%% Read the videeo
xyloObj = VideoReader('G:\temp\x_0004.mp4');
lastFrame = read(xyloObj, inf);
xyloObj.NumberOfFrames
vidFrames = read(xyloObj);

imagesc(vidFrames(:,:,:,end))
%%
% Analog input
s_in = daq.createSession('ni');
addAnalogInputChannel(s_in,'Dev1', 'ai0', 'Voltage');
s_in.DurationInSeconds = 2.0;
data = startForeground(s_in);
plot(data)
% Analog output.
% What about digital????
%s.Rate = 10;
%s.queueOutputData(repmat([data0, data1, data2], 5, 1));
%s.startBackground();
% out_sig = zeros(10,1);
% out_sig(5:6) = 5;

for ii = 1:1000
s.queueOutputData(out_sig) % Queuing the data for output
s.startForeground();
fprintf('./n')
end