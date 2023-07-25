function [seq, original_size_bytes, compressed_size_bytes] = Spikes_to_sequence(spike_ca)
% INPUT: cell array of spike times where each element is a different cell.
%   if 2 outputs are entered, the second is the file size of the compressed
%   data sequence.
% OUTPUT: a sequence where each cell is identified by a single number (i.e.
%   1 12 1 1 3 23 2...
%
for ii = 1:length(spike_ca)
    if isa(spike_ca{ii},'ts')
        spike_ca{ii} = Data(spike_ca{ii});
    end
end

seq = [];
for ii = 1:length(spike_ca)
    seq = [seq; spike_ca{ii}(:) ones(length(spike_ca{ii}(:)),1)*ii];
end
seq = sortrows(seq);

if nargout >= 2
    [original_size_bytes, compressed_size_bytes ] = GenCompress(seq(:,2));
end