%% Demo to illustrate how front-camera data and its output from deeplabcut can be...
% smoothed.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data_dir = 'D:\Data\Marmoset_String_Pulling\Example Data Dec.2023';
cd(data_dir)
dlc_csv_file = 'GX010318cropped_output_fragment_2DLC_resnet50_Nov14_refinedNov14shuffle2_600000.csv'; % Assumes the dlc csv file is in this directory. Change if you change the directory
[TBL, TBL_info] = DLC_read_DLC_csv_file(dlc_csv_file);
frame_rate = Rows(TBL)/5; % this is a guess. Says the video is 5sec long so...
TBL.time_sec = TBL.bodyparts_coords/frame_rate;
ker = hanning(10)/sum(hanning(10));

TBL.Nose_sm_x = movmedian(TBL.Nose_x,6,'omitmissing');
TBL.Nose_sm_y = movmedian(TBL.Nose_y,6,'omitmissing');
TBL.Nose_sm_x = conv(TBL.Nose_sm_x,ker,'same');
TBL.Nose_sm_y = conv(TBL.Nose_sm_y,ker,'same');


figure
subplot(1,2,1)
plot(TBL.Nose_x, TBL.Nose_y,'.')
hold on
plot(TBL.Nose_sm_x, TBL.Nose_sm_y,'.')

subplot(1,2,2)
plot(TBL.time_sec, TBL.Nose_x,'.')
hold on
plot(TBL.time_sec, TBL.Nose_y,'.')

plot(TBL.time_sec, TBL.Nose_sm_x,'.')
plot(TBL.time_sec, TBL.Nose_sm_y,'.')


%% %%%%%%%%%%%%%%%%% Part 2

data_dir = 'D:\Data\Marmoset_String_Pulling\';
cd(data_dir)
med_win = 12;
ker_size = 10;
dlc_csv_file = 'data1.csv'; 
[TBL, TBL_info] = DLC_read_DLC_csv_file(dlc_csv_file);
frame_rate = 60; % random guess. Replace with the correct rate.
TBL.time_sec = TBL.bodyparts_coords/frame_rate;
ker = hanning(ker_size)/sum(hanning(ker_size));

TBL.Nose_x(TBL.Nose_x > 850) = nan;
TBL.Nose_y(TBL.Nose_y > 850) = nan;

TBL.Nose_sm_x = movmedian(TBL.Nose_x,med_win,'omitmissing');
TBL.Nose_sm_y = movmedian(TBL.Nose_y,med_win,'omitmissing');
TBL.Nose_sm_x = conv(TBL.Nose_sm_x,ker,'same');
TBL.Nose_sm_y = conv(TBL.Nose_sm_y,ker,'same');


figure
subplot(1,2,1)
plot(TBL.Nose_x, TBL.Nose_y,'.')
hold on
plot(TBL.Nose_sm_x, TBL.Nose_sm_y,'.')

subplot(1,2,2)
plot(TBL.time_sec, TBL.Nose_x,'.')
hold on
plot(TBL.time_sec, TBL.Nose_y,'.')

plot(TBL.time_sec, TBL.Nose_sm_x,'.')
plot(TBL.time_sec, TBL.Nose_sm_y,'.')


