% Spindle_detector_validation
% Runs our current spindle detector against a validation set...
% Cowen 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data_file{1} = 'E:\Data\LRRK2\GOOD_FOR_SPINDLES\L13Day3\check_spindles.mat';
data_file{2} = 'E:\Data\LRRK2\GOOD_FOR_SPINDLES\L26Day2\check_spindles.mat';
data_file{3} = 'E:\Data\LRRK2\GOOD_FOR_SPINDLES\L28Day2\check_spindles.mat';
data_file{4} = 'E:\Data\LRRK2\GOOD_FOR_SPINDLES\W53Day8\check_spindles.mat';


sFreq = 200;
for iF = 1:length(data_file)
    load(data_file{iF})
    sf = double(1/(median(diff(check_spindles.rerefed_lfp(:,1)))));
    sleep_intervals_s = [check_spindles.pre_sleep_times; check_spindles.post_sleep_times];
    % reduce the sampling rate to something sane.
    ts = check_spindles.rerefed_lfp(1,1):1/sf:check_spindles.rerefed_lfp(end,1);
    D = diff(check_spindles.rerefed_lfp(:,1)) <=0;
    size(check_spindles.rerefed_lfp)
    while any(D)
        check_spindles.rerefed_lfp(D,:) = [];
        D = diff(check_spindles.rerefed_lfp(:,1)) <=0;
    end
    size(check_spindles.rerefed_lfp)
    L = interp1(check_spindles.rerefed_lfp(:,1), check_spindles.rerefed_lfp(:,2), ts);
    newL = resample(double(L),sFreq,sf);
    newT = linspace(1/sFreq/2, check_spindles.rerefed_lfp(end,1)-1/sFreq/2,length(newL));
    % Spindle detection should really be a 2 part process. FIrst is
    % candidate detection, and second is a more stringent selection process
    % based on psds and such.
    [crown_start_end_times_s, P] = Spindle_detector_crown([newT; newL]',sFreq, sleep_intervals_s);
    [cowen_start_end_times_s, P] = Spindle_detector_cowen([newT; newL]',sFreq, sleep_intervals_s);
    [wamsley_start_end_times_s, P] = Spindle_detector_wamsley([newT; newL]',sFreq,sleep_intervals_s);
    [ferrarelli_start_end_times_s, P] = Spindle_detector_ferrarelli([newT; newL]',sFreq,sleep_intervals_s);
    
    
end
