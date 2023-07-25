function O = Ts_array_to_vectors(ts_array)
for ii = 1:length(ts_array)
    O{ii} = Data(ts_array{ii});
end