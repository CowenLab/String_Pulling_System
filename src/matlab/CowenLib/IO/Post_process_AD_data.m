% Post-process AD system files. (Wilson recording system)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2008
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eeg_files = find_files('eeg*.ascii');
pos_file = find_files('*.pos.ascii');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save the eeg files as .mat files.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iF = 1:length(eeg_files)
    [p,n,e] = fileparts(eeg_files{iF});
    EEG = load(eeg_files{iF});
    n = strrep(n,'.','_');
    save([n '.mat'],'EEG')
    % No point in keeping the ascii files - they can always be regenerated.
    disp([n ' deleting ' eeg_files{iF}])
    delete(eeg_files{iF})
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculate the event times for things. EEG 7 stores the events.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load eeg_7.mat
EVT = Events_from_EEG_channel(EEG);
EVT_Codes = ER_Event_Codes(EVT);
save('Events.mat','EVT','EVT_Codes');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save the position file as a .mat file (OMG, like 30x faster to load).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
POS = load(pos_file{1});
POS(POS(:,2)==0,[2 3]) = nan;
[p,n,e] = fileparts(pos_file{1});
n = strrep(n,'.','_');
save([n '.mat'],'POS')
delete(pos_file{1})
