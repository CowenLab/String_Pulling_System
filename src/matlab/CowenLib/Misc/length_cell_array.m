function [maxlen, all_len] = length_cell_array(A)
all_len = nan(length(A),1);
for ii = 1:length(A)
    all_len(ii) = length(A{ii});
end
maxlen = nanmax(all_len);