function [start_and_end_timestamps,Td,Ed] = EMG_detector(emg_file,intervals_to_load, varargin)
%function [start_and_end_timestamps,T,Ed] = EMG_detector(emg_file,intervals_to_load, varargin)
%
% INPUT
% OUTPUT
threshold = .1;
hipass = 50;
lowpass = 450;
sFreq = 1000;
add_position = 1; % Add position information regarding motion to the EMG indicator to produce
% a more accurate measure of waking activity.
plotit = 0;
start_and_end_timestamps = [];
Td = [];
Ed = [];
Extract_varargin;

[T,E] = Read_CR_files(emg_file, sFreq ,intervals_to_load ,{'bandpass'}, {[hipass lowpass]});

Ed = decimate(abs(E),sFreq/2);  % reduce the EMG sampling down to only 2Hz.
Ed = Ed/max(Ed); % force to be
% rescale to be between 0 and 1.
Ed = Ed - min(Ed);
Ed = Ed/max(Ed); % 
%shift_sec = .5/(sFreq/50); % half niquidst.
shift_sec = 0;
Td = linspace(T(1)+shift_sec*1e6,T(end)-shift_sec*1e6,length(Ed));

if add_position
    [Txy,x,y]=textread('vtm1.pvd  ','%n%n%n%*[^\n]');
    ix = find(Txy > T(1) & Txy < T(end));
    Txy = Txy(ix); x = x(ix); y = y(ix);
    motion = abs(diff(x)) + abs(diff(y));
    motion(end+1) = motion(end);
    motion = motion - min(motion);
    motion = motion/max(motion); % 
    % Convert the same timescale as the decimated EMG data.
    Edm = Ed + interp1(Txy,motion,Td)';
    Edm = Edm - min(Edm);
    Edm = Edm/max(Edm); % 
end
starttime_idx = find(diff([0;Ed]>threshold) > 0)+1;
endtime_idx = find(diff([0;Ed]<threshold) > 0)+1;
if length(starttime_idx) > length(endtime_idx)
    endtime_idx(end+1) = length(Ed);
end
endtime_idx = endtime_idx(:);
%
d = endtime_idx - starttime_idx;
if sum(d<=0)>0
    disp('Strange start and end times.')
end

se_times = [Td(starttime_idx)' Td(endtime_idx)'];
count = 1;
rcount = 1;
se_times2 = [];
while (rcount < size(se_times,1))
    if (se_times(rcount+1,1)-se_times(rcount,2) < 2e6)
        % these two intervals should be merged
        start = se_times(rcount,1);
        rcount = rcount + 1;
        while (se_times(rcount+1,1)-se_times(rcount,2) < 2e6)
            rcount = rcount + 1;
        end
        se_times2(count,:) = [start se_times(rcount,2)];
        rcount = rcount + 1;
    else
        se_times2(count,:) = se_times(rcount,:);
        rcount = rcount + 1;
    end
    count = count + 1;
end

if (se_times2(end,2) ~= se_times(end,2))
    se_times2(end+1,:) = se_times(end,:);
end

if plotit == 1
    [Tcsc,Ecsc] = Read_CR_files('CSC1.ncs', 100 , intervals_to_load );
    [Thipp,Ehipp] = Read_CR_files('CSC15.ncs', 100 , intervals_to_load );
    figure
    plot(T,E/max(E));
    hold on
    plot(Txy,motion/max(motion)+1.5,'m')
    plot(Tcsc,Ecsc/max(Ecsc)+3,'c')
    plot(Thipp,Ehipp/max(Ehipp)+4.5,'k')
    plot(Td,Ed,'r');
    if add_position
        plot(Td,Edm,'k');
    end
    h = line(se_times2', ones(size(se_times2'))*1);
    set(h,'Color','r')
    set(h,'LineWidth',3)
    h = line(se_times', ones(size(se_times'))*2);
    set(h,'Color','b')
    set(h,'LineWidth',3)
    pause
    [spindle_start_end_ts ,y] = ginput(2);
    [control_start_end_ts ,y] = ginput(2);
    idx = find(Tcsc>spindle_start_end_ts(1) & Tcsc<spindle_start_end_ts(2));
    %    arsp  = lpc(Ecsc(idx),200);
    idx2 = find(Tcsc>control_start_end_ts(1) & Tcsc<control_start_end_ts(2));
    %    arctl = lpc(Ecsc(idx2),200);
    Psp   = pwelch(Ecsc(idx),60);
    Pctrl = pwelch(Ecsc(idx2),60);
    Bsp   = fir2(220,linspace(0,1,length(Psp)),Psp');
    Bctrl = fir2(220,linspace(0,1,length(Pctrl)),Pctrl');
    figure
    plot(filter(Bsp,1,Ecsc));
    hold on
    plot(filter(Bctrl,1,Ecsc)+1,'r');

    figure
    a = lpc(x,3);
    plot(filter([0 -arsp(2:end)],1,Ecsc));
    hold on
    plot(filter([0 -arctl(2:end)],1,Ecsc),'r');
    plot(Ecsc,'g');
    
end
if add_position
    Ed = Edm;
end