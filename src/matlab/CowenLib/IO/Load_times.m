function T = Load_times(a_dir)
%function T = Load_times(fname)
%
% Load in a file of the format HH:MM:SS HH:MM:SS where each row
% represents an epoch and column 1 is the startime and col 2 is the
% end time.
%
% INPUT: file to read in
% OUTPUT: T = nX2 matrix of start and end times.

% cowen Mon Apr 12 13:37:59 1999
if nargin == 0
    a_dir = pwd;
end

T = zeros(5,2)*nan;

% If bower data, just run their script and return
if findstr('bower',lower(a_dir))
    % Use the file loader for bower data.
    [seqevents, T] = read_events_bower(fullfile(a_dir,'events.dat.txt'));
    T = T/100;
    % Add some dummy times to the end 
    T = [T;0 0;0 0];
    return
end
if findstr('moser',lower(a_dir))
    % Use the file loader for bower data.\
    T  = load(fullfile(a_dir,'epoch_times.txt'));
    T = [T;0 0;0 0];
    return
end


fids = fopen(fullfile(a_dir,'Scores.txt'),'r') ;
fidss = fopen(fullfile(a_dir,'Sleep_scores.txt'),'r') ;
fidet = fopen(fullfile(a_dir,'epoch_times.ascii'),'r');
if fids~= -1;
    fname = fullfile(a_dir,'Scores.txt');
    file_type = 'new_format';
elseif fidss~= -1;
    fname = fullfile(a_dir,'Sleep_scores.txt');
    file_type = 'new_format';
elseif fidet ~= -1;
    fname = fullfile(a_dir,'epoch_times.ascii');
    file_type = 'old_format';
else
    error('Unknown epoch times file.')
end

switch file_type
case 'old_format'
    start_time = 1;
    counter = 1;
        while(~feof(fidet))
        [R msg] = fscanf(fidet, '%d:%d:%f',3);
        
        if isempty(R)
            break
        end
        
        if start_time
            Ts{counter} =  HMS_to_timestamp(R(1), R(2), R(3));
            start_time = 0;
        else
            Te{counter} =  HMS_to_timestamp(R(1), R(2), R(3));
            counter = counter + 1;
            start_time = 1;
        end
        
    end
    
    %T = fscanf(fid, '%s\n',1)
    for ii = 1:length(Te)
        T(ii, 1) = Ts{ii};
        T(ii, 2) = Te{ii};
    end
    
    fclose(fidet);
case 'new_format'
    [ss_timestamps ss_HMS ss_events] = textread(fname,'%n%q%q','delimiter',',');
    for ii = 1:length(ss_events)
        switch ss_events{ii}
        case {'M1Start' 'Rest1Start'}
            T(1,1) = ss_timestamps(ii);
        case {'Rest1End' 'S1End'}
            T(1,2) = ss_timestamps(ii);
        case {'Behavior1Start' 'M1Start'}
            T(2,1) = ss_timestamps(ii);
        case {'Behavior1End' 'M1End'}
            T(2,2) = ss_timestamps(ii);
        case {'Rest2Start' 'S2Start'}
            T(3,1) = ss_timestamps(ii);
        case {'Rest2End' 'S2End'}
            T(3,2) = ss_timestamps(ii);
        case {'Behavior2Start' 'M2Start'}
            T(4,1) = ss_timestamps(ii);
        case {'Behavior2End' 'M2End'}
            T(4,2) = ss_timestamps(ii);
        case {'Rest3Start' 'S3Start'}
            T(5,1) = ss_timestamps(ii);
        case {'Rest3End' 'S3End'}
            T(5,2) = ss_timestamps(ii);
        end
    end
    % The new cheetah system has greater resolution bring it back to .1 ms
    T = floor(T / 100);
otherwise
    error('barf')
end
idx = find(isnan(T(:,2)));
T(idx,:) = [];
