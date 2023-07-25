function [nctsa, overlaps] = combine_ctsa(ctsa_array)
% Convert a ctsa array-- for instance, each element in the array couls
% be an epoch containing spikes-- and combine the elements into a single 
% ctsa cell array of ts objects. A big assumption is that there are equal numbers
% of cells in each ctsa.
% 
% INPUT: a ctsa array (an array of an array of ts objects)
% OUTPUT: a cell array of ts objects.
%         overlaps - a cell array of cells that contains the timestamps
%                    of the spikes that overlapped.

% cowen
n_cells = length(ctsa_array{1});

for cell_id = 1:n_cells
  tstamps{cell_id} = [];
  overlaps{cell_id} = [];
end

for epoch = 1:length(ctsa_array)
  if length(ctsa_array{epoch})~=n_cells
    error('Not an equal number of cells in each cell array')
  end
  
  for cell_id = 1:length(ctsa_array{epoch})
     tstamps{cell_id} = [tstamps{cell_id}; Data(ctsa_array{epoch}{cell_id})];
  end
end

% Check for overlapping spiketimes.
for cell_id = 1:n_cells
  u  = unique(tstamps{cell_id});
  t  = tstamps{cell_id};
  st = sort(t);
  d  = diff(st);
  if ~isempty(t)
    overlaps{cell_id} = st(find(d==0));
    if length(u) ~= length(t)
      disp(['WARNING: ' num2str(length(t) - length(u)) ' overlapping timestamps in cell ' num2str(cell_id)])
    end
    if sort(tstamps{cell_id}) ~= tstamps{cell_id}
      disp(['WARNING: timestamps in the ctsa are not ordered in cell ' num2str(cell_id)])
    end
  else
    overlaps{cell_id} = [];
  end
  nctsa{cell_id} = ts(tstamps{cell_id});
end
