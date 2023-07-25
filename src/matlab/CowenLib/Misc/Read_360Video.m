function O = Read_360Video(fname, type)
% Actually, it's the same as a normal video so nothing special here. You
% just need to know to stich the video using the Samsung 360 Action
% software (which is lame but works) and only use the stitched video.
%
if nargin < 2
    type = 'Gear360';
end
%%
fname = 'C:\Temp\Video1_6_29_2018.mp4';
fname = 'F:\temp\360_0121_Stitch_XHC.mp4';
v = VideoReader(fname);
count = 1;
while hasFrame(v)
    video = readFrame(v);
    count = count + 1;
    if count > 200
        break;
    end
end
% whos video
fclose all

videoFReader = vision.VideoFileReader(fname);
videoPlayer = vision.VideoPlayer;
while ~isDone(videoFReader)
  videoFrame = videoFReader();
  videoPlayer(videoFrame);
  pause(0.1)
end