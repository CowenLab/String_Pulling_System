function [ctsa_spikes, times ,tet_id, cell_no] = Load_neurons(data_dir,epochs_to_load,threshold,use_unsorted)
%
% Load data loads in the spike data and filters the Q matrix for
% interneurons and non-spiking neurons. It is utterly dependent on the 
% variables set from the calling script.
%
% Do some fancy footwork to avoid creating a use_unsorted variable in all
% of my data.
if nargin <4
  use_unsorted = 0;
end
if nargin <3
  % Threshold to eliminate high firing neurons. If 0, nothing will be eliminated.
  threshold = 999;
end
tfilelist = Tfile_list_array(data_dir,use_unsorted);    % Load in the tfile names for the data.
% Main routine
disp(['Using ' data_dir ]);   

% Get times in timestamps
times = Load_times(fullfile(data_dir,'epoch_times.ascii'));
interneurons = []; 
for epoch = epochs_to_load
  % Load in the ctsd data
  disp(['Loading tfiles from ' tfilelist{epoch} ]);
  dset = ReadFileList(tfilelist{epoch});
  % Change directories if Windows.
  if strcmp(computer,'PCWIN')
    for ii = 1:length(dset)
      dset{ii} = strrep(dset{ii},'/home/Data/2/hyper5/',[Data_dir filesep]);
      dset{ii} = strrep(dset{ii},'/','\');
    end
  end
  % Assigh a tetrode number to each cell.
  [tet_id, cell_no] = Assign_tet_numbers(dset);
  ctsa_spikes{epoch} = LoadSpikes(dset); % Create the ctsds
  disp(['Restricting times to ' Time_string(times(epoch,1)), ' to ', ...
      Time_string(times(epoch,2))]);
  for ii = 1:length(ctsa_spikes{epoch})
    ctsa_spikes{epoch}{ii} = Restrict(ctsa_spikes{epoch}{ii}, times(epoch,1), times(epoch,2));
  end
  % Filter out high spiking interneurons and non-spiking cells
  F = Frequency( ctsa_spikes{epoch});
  interneurons = [interneurons find(F>threshold)];
end

% Wipe out all interneurons and non-spiking neurons in all epochs.
%disp('Eliminating the following neurons from analysis(no spikes in maze or interneurons)')
%the_damned
for epoch = epochs_to_load
  ctsa_spikes{epoch} = Remove_cells(ctsa_spikes{epoch},unique(interneurons));
end
tet_id(interneurons) = [];
cell_no(interneurons) = [];


