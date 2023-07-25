function [burst, ttl, am] = toneburst(pitch, dur, tag, fs, risefall,type)
% toneburst  create a toneburst audio signal
%
% burst = toneburst(pitch, dur, tag, fs, risefall,type)
%
% [burst, ttl, am] = toneburst(pitch, dur, tag, fs, risefall,type)
%
% tag=[] or 0: no am modulation
% type = sine, square
%
% JRI 4/2/09

% there's a choice here: burst dur from 50% of rise/fall or from start
% start is simpler as far as duration & tagging, so use that

rfTrig = 0;
%rfTrig = 0.5;

if nargin==0,
  eval(['help ' mfilename])
  return
end

if nargin < 6,
  type = 'square';
end

%calc durations in samples
dur_p = round(dur * fs);
risefall_p = round(risefall*fs);
top_p = dur_p - 2*(1-rfTrig)*risefall_p;

%burst envelope
bramp_down = cos(0.5 * pi * [1:risefall_p]/risefall_p).^2;
bramp_up = bramp_down(end:-1:1);
top = ones(1, top_p); 
burstEnv = [bramp_up top bramp_down];

% carrier
pp = [0:length(burstEnv)-1];
tt = pp / fs;
switch type,
  case 'square',
    % a low-passed square wave
    N = 7; %uses first 3 non-zero harmonics
    carrier = square_series(2*pi*pitch*tt, N);
    carrier = square * (1/max(abs(square))); %normalize peak to 1
    headroom = 1;
  case 'sine'
    carrier = sin(2*pi*pitch*tt);
    headroom = 1;
end

% burst
burst = carrier .* burstEnv * headroom;

% ttl
ttl = ones(size(burst));
startFloorIdx = 1:floor(rfTrig*risefall_p);
minEndFloor = round(0.025 * fs); %need at least this length offset to enable onset
endFloor = max(minEndFloor, floor(rfTrig*risefall_p));
endFloorIdx = (length(burst)-endFloor+1):length(burst);
ttl(startFloorIdx) = 0;
ttl(endFloorIdx) = 0;

% tag
if ~isempty(tag),
  am = -cos(2*pi*tag*tt);
  %amdepth = 1;
  amdepth = 0.75;
  am = am*(amdepth/2) + (1 - amdepth/2);
  burst = burst .* am;
else
  am = [];
end






