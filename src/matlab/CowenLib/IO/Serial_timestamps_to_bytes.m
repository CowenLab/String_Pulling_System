function [bytes, byte_start_ts_sec] = Serial_timestamps_to_bytes(ts_sec,baud_rate, min_time_between_bytes_sec)
%function [bytes, byte_start_ts_sec] = Serial_timestamps_to_bytes(ts_sec,baud_rate)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Converts a series of timestamps sent in digital serial order to a
% sequence of bytes. The serial data is sent via the standard serial UART protocol
% (start bit, data bits, stop bit. I don't think that there is a parity
% bit).
%
% To get the serial timestamps from...
%   Plexon: [n, ts_sec, sv] = plx_event_ts('cowen_test1_040612002.plx', 257);
%   Nerualynx: [ts_usec, EventIDs, EventCodes] = Nlx2MatEV( 'Events.Nev', [1 1 1 0 0], 0, 1, [] );
%       ts_sec = ts_usec/1e6;
%
% In my data, there is a start bit, followed by a blank, followed by one bit, followed by 4
% bits, followed by a longer delay, followed by a longer delay, folllowed
% by a stop bit.
%
%                1  1  1 1 1 1  1 1 1 1   1
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
debug_mode = true;
ts_sec = ts_sec(:);
if nargin < 2
    baud_rate = 2400; % Ignore this for now - as it does not seem to correspond to the real data.
end
if nargin < 3
    min_time_between_bytes_sec = 0.01;
end
%
%inter_bit_interval = 1/baud_rate; % This is what it 'should' be but it's
%not what the data seems to show - which is about twice this (or baud of
%1200, not 2400). Perhaps we need to hook the output to an oscilliscope to
%verify the pattern of bits.
inter_bit_interval = 0.00083; % I found this by measuring the pulse manually.
d = [inf;diff(ts_sec)]; % inf ensures that the first pulse is identified.

if debug_mode
    % What is the distribution of intervals?
    dd = d;
    dd = dd(dd< 0.01);
    figure
    hist(dd*1000,100)
    xlabel('msec')
    %seems like .1 msec of jitter around the timestamp onset. I wonder
    %where that jitter is coming from. Arduino? the MAP system?
    % the most disturbing thing is that there are many bits at 1.25 msec
    % which is not a multiple of .83 msec. I don't know why.
end
% Find the start bit of each byte.
starts_ix = find(d > min_time_between_bytes_sec);
byte_start_ts_sec = ts_sec(starts_ix); % the start of each byte.

starts_ix = starts_ix + 1; % It seems like there is always a second pulse so I will treat this second pulse as the true start pulse.

%n_pulses = length(ts_sec);
bytes = zeros(length(starts_ix),1)*nan; %stores each byte.

rng = [0:inter_bit_interval:(inter_bit_interval*14)]';
%%
for iByte = 1:(length(starts_ix)-1)
    st_ix = starts_ix(iByte);
    ed_ix = st_ix + 12;
    h = hist(ts_sec(st_ix:ed_ix),rng + ts_sec(st_ix)); % Histogram to parse the bits for the byte.
    c = num2str(h); % because bin2dec requires a string.
    c = strrep(c,' ',''); % get rid of the pesky spaces.
    c = c([3:6 8:11]); % Because there is a strange space between the first and last 4 bits.
    %bytes(iByte) = bin2dec(c(end:-1:1)); % LSB is on the right for bin2dec but on the left in the serial signal.
    bytes(iByte) = bin2dec(c); % LSB is on the right for bin2dec but on the left in the serial signal.
    
    if debug_mode
        clf
        h(end) = 0; % the last bin value is junk

        bar(rng + ts_sec(st_ix) , h) % the observed bit pattern 
        hold on
        a = axis;
        plot(ts_sec(st_ix:ed_ix), ones(size(st_ix:ed_ix)),'k*') % the actual times of the pulses
        plot(rng + ts_sec(st_ix), ones(size(rng)),'r+') % the predicted intervals where pulses should occur
        axis(a)
        title([c '  ' num2str(bytes(iByte))])
        pause
    end
 
end
% I ignored the last byte.
%% %%%%%%%%%%%%%%%%%%%%%%
if debug_mode
    grd = ts_sec(1) + cumsum(repmat(inter_bit_interval,10000,1));
    
    
    figure(1)
    clf
    plot(grd,ones(size(grd)),'m+')
    hold on
    plot(ts_sec(starts_ix),ones(size(starts_ix)),'ro')
    
    plot(ts_sec,ones(size(ts_sec)),'k.')
    
end