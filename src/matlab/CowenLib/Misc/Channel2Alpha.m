function  c = Channel2Alpha(num)
% Converts a Warp144 channel number into a character string like L12
f = floor((num-1)/12);
v = num-f*12;
c = [char(f+65) num2str(v)];
