function Sync_timestamps_and_sync_codes(Data_to_sync,Sync_and_timestamps) 
% INPUT: 
%   Data_to_sync: col1 - unique code for each point of data.
%   Sync_and_timestamp - a unique sync code  (col1) followed by a
%                        timestmamp (col2).
%
% OUTPUT: 
%   A matrix with the best guess interpolated timestamps in col 1 (from col2 of
%   Sync_and_timestamp) for each row in Data_to_sync. All the rest of the
%   cols are the same.
%
% cowen 2013
if 0
    Data_to_sync = [(1:1000)' sin(linspace(1,100*2*pi,1000))'];
    % Insert some jitter in the data.
    Sync_and_timestamps = [(1:5:1000)' (1:5:1000)'*100];
end
%%
Sync_and_timestamps = Sync_and_timestamps(Sync_and_timestamps(:,2)>0,:);
% % The interval between signals. The IMU sends out ?? signals per pulse. 
% %imu_pulse_interval_usec = median(diff(Sync_and_timestamps(:,1)));
% 
% ampx_codes = [Sync_and_timestamps(:,2)*1e7 + Sync_and_timestamps(:,3) NeuralTime_Count_SyncCode(:,1)];
% imu_codes = D.MAG_PROC_XY(:,1)*1e7 + D.MAG_PROC_XY(:,2);

%[1:Rows(D.MAG_PROC_XY)]' 
Imu_Synccode_Data = [imu_codes [1:Rows(D.MAG_PROC_XY)]' D.MAG_PROC_XY(:,[4 5 6])];
%%
%
%
% The strategy is to go through each of the imu codes - 
% 0. determine the best guess of the sample rate of the imu data by
% comparing aginst the ampx times.
% 1. for the first good imu code, find the match in the ampx times. (if no match, skip) 
% 2. using the next imu code, find the next match in the amx times.
% 3. interpolate between these points to get an ampx time for each imu
% time. IFF the time between these adjacent points is reasonable (within
% 1.5 of the estimated interval bewteen points). If not (e.g. skipped
% records), ignore this point and go to the next pair of adjacent records.
[isct, ia_imu, ib_ampx] = intersect(Imu_Synccode_Data(:,1),ampx_codes(:,1));
% I would think that the above would produced indices that would increase
% linearly, BUT THEY DONT, indicating that there may be multiple matches
% for the sync codes OR something else is messed up.
% Get the best guessed timestamps for each point in the text imu file.

% Let's reduce the data to just the points of intersection.
ampx_codes = ampx_codes(ib_ampx,:);
ampx_codes= sortrows(ampx_codes,2);
%Imu_Synccode_Data = Imu_Synccode_Data(ia_imu,:);
%Imu_Synccode_Data = sortrows(Imu_Synccode_Data,2);
%%

last_ampx = 0;



M = [NeuralTime_Count_SyncCode(ia,1) Count_Synccode_Data(ib,:)];
M = sortrows(M,2);
%%
figure
subplot(3,1,1)
plot(Count_Synccode_Data(:,4))
subplot(3,1,2)
plot(M(:,4))
