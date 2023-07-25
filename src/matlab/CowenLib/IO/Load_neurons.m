function [ctsa_spikes, times ,tet_id, cell_no,n_original_cells, dset] = Load_neurons(data_dir,epochs_to_load,INthreshold,LOWthreshold,use_unsorted)
%
% Load data loads in the spike data and filters the Q matrix for
% interneurons and non-spiking neurons. It is utterly dependent on the 
% variables set from the calling script.
%
% Do some fancy footwork to avoid creating a use_unsorted variable in all
% of my data.
sleep1 = 1; maze1 = 2; sleep2 = 3; maze2 = 4; sleep3 = 5;

if length(epochs_to_load) == 3
    maze_epochs = [maze1];
    sleep_epochs = [sleep1 sleep2];
else
    maze_epochs = [maze1 maze2];
    sleep_epochs = [sleep1 sleep2 sleep3];
end


if nargin <5
  use_unsorted = 0;
end
if nargin <3
  % Threshold to eliminate high firing neurons. If 0, nothing will be eliminated.
  INthreshold = 999;
  LOWthreshold = 0;
end
if nargin <4
  % Threshold to eliminate high firing neurons. If 0, nothing will be eliminated.
  LOWthreshold = 0;
end
tfilelist = Hyper5_Tfile_list_array(data_dir,use_unsorted);    % Load in the tfile names for the data.
% Main routine
disp(['Using ' data_dir ]);   

low_fire_cells = [];

% Get times in timestamps
times = Load_times(data_dir);
cells_to_ax = []; 
for epoch = epochs_to_load
  % Load in the ctsd data
  disp(['Loading tfiles from ' tfilelist{epoch} ]);
  dset{epoch} = ReadFileList(tfilelist{epoch});
  % Change directories if Windows.
  if strcmp(computer,'PCWIN')
    for ii = 1:length(dset{epoch})
      dset{epoch}{ii} = strrep(dset{epoch}{ii},'/home/Data/2/hyper5/',[Data_dir filesep 'Hyper 5' filesep]);
      dset{epoch}{ii} = strrep(dset{epoch}{ii},'/','\');
    end
  end
  % Assigh a tetrode number to each cell.
  [tet_id, cell_no] = Assign_tet_numbers(dset{epoch});
  ctsa_spikes{epoch} = LoadSpikes(dset{epoch}); % Create the ctsds
  disp(['Restricting times to ' Time_string(times(epoch,1)), ' to ', ...
      Time_string(times(epoch,2))]);
  for ii = 1:length(ctsa_spikes{epoch})
    ctsa_spikes{epoch}{ii} = Restrict(ctsa_spikes{epoch}{ii}, times(epoch,1), times(epoch,2));
  end
  % Filter out high spiking interneurons and non-spiking cells
  F = Frequency( ctsa_spikes{epoch});
  disp([num2str(length(find(F>INthreshold))) ' High firing cells'])
  cells_to_ax = [cells_to_ax find(F > INthreshold)];
end
n_original_cells = length(ctsa_spikes{1});
[ctsa_spikes, tet_id, cell_no] = Remove_unwanted_cells(ctsa_spikes,maze_epochs,tet_id,cell_no,LOWthreshold,INthreshold);