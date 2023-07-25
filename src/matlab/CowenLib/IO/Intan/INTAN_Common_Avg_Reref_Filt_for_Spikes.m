function [INFO] = INTAN_Common_Avg_Reref_Filt_for_Spikes(list_of_dat_files, save_spike_dat_files, filter_for_spikes)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Performs common average rereferencing using the non-outlier channels for
% the common average. If desired, it will also subtract baseline to get rid
% of DC shifts, subtract the CAR, and then filter for spikes and save the
% new file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2019,2021 (added output INFO)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 0 || isempty(list_of_dat_files)
    list_of_dat_files = find_files('amp*.dat');
end
if nargin < 1
    save_spike_dat_files = false;
end
if nargin < 3
    % filter for spikes - if not, save the unfiltered data in the dat
    % files.
    filter_for_spikes = true;
end
samples_to_load = 30000*40; % Estimate based on the typical sampling rate. Should really take a random subsample of the entire session.
[pth] = fileparts(list_of_dat_files{1});
car_fname = fullfile(pth,'CAR.dat');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load a sample of each dat file and measure the variance.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
D = zeros(length(list_of_dat_files),samples_to_load);
for iF = 1:length(list_of_dat_files)
    fp = fopen(list_of_dat_files{iF},'rb');
    D(iF,:) = fread(fp,samples_to_load,'int16');
    fclose(fp);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Identify outliers and remove from file list.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sd = std(D,[],2);
tmn = trimmean(D',10);
mn = mean(D,2);
% hist(sd)
% max(sd)
p = prctile(sd,[5,90]);
GIX = sd > p(1) & sd < p(2);
good_files = find(GIX);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Aggregate the data from the good files.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%d/%d good files',length(good_files),length(list_of_dat_files))
for iF = 1:length(good_files)
    fp = fopen(list_of_dat_files{good_files(iF)},'rb');
    D = single(fread(fp,'int16'));
    D = D - tmn(good_files(iF));
    if iF == 1
        CAR = D;
    else
        CAR = CAR + D;
    end
    fclose(fp);
    fprintf('.')
end
CAR = CAR/length(good_files);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write the CAR file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fp = fopen(car_fname,'wb');
fwrite(fp,CAR,'int16');
fclose(fp);

disp('Created')
INFO.list_of_reref_dat_files = [];
INFO.list_of_dat_files = list_of_dat_files;
INFO.good_files = good_files;
INFO.std = sd;
INFO.note = 'assume using trimmed mean to subtract baseline from each channel. good_files are files that were used for the CAR.';
INFO.trimmed_mean = tmn;
INFO.mean = mn;

save(fullfile(pth,'CAR_params.mat'),'INFO')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If desired, now filter for spikes (optional) and save a new set of dat files for
% spike sorting. Note: need to be converted to singles and then back to
% ints given the need to filter.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if save_spike_dat_files
    rhd_file = dir(fullfile(pth,'*.rhd'));
    if isempty(rhd_file)
        sFreq = 30000; % assume this if no rhd file.
        disp('WARNING: NO RHD FILE FOUND, ASSUME 30000Hz')
    else
        try
            % this is the most recent version of the Intan RHD
            IF = read_Intan_RHD2000_file_cowen(pth,rhd_file(1).name);
            sFreq = IF.frequency_parameters.amplifier_sample_rate;
        catch
            % this is a legacy version. does not work on recent
            IF = INTAN_Read_RHD_file(fullfile(pth,rhd_file(1).name));
            sFreq = IF.frequency_parameters.board_adc_sample_rate;
        end
    end

    for iF = 1:length(list_of_dat_files)
        [pth,name,ext] = fileparts(list_of_dat_files{iF});
        if filter_for_spikes
            new_fname = fullfile(pth,['filt_CAR_' name  ext]);
        else
            new_fname = fullfile(pth,['CAR_' name  ext]);
        end
        INFO.list_of_reref_dat_files{iF} = new_fname;
        fp = fopen(list_of_dat_files{iF},'rb');
        D = single(fread(fp,'int16'));
        fclose(fp);
        INFO.sd_before_after(iF,1)= std(D(1:10000:end));
        D = D - tmn(iF) - CAR;
        INFO.sd_before_after(iF,2)= std(D(1:10000:end));
        if filter_for_spikes
            [D,INFO.filt_params] = Filter_for_spikes(D,sFreq);
        else
            INFO.filt_params = [];
        end
        D = int16(D);
        fp = fopen(new_fname,'wb');
        fwrite(fp,D,'int16');
        fclose(fp);
        fprintf('x')

    end
    fclose('all');
    figure
    bar(INFO.sd_before_after(:,2) - INFO.sd_before_after(:,1))
    xlabel('Ch')
    ylabel('Change in std after CAR')
    save(fullfile(pth,'CAR_params.mat'),'INFO')

end