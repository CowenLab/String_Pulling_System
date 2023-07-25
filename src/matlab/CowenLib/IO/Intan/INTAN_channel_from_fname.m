function ch = INTAN_channel_from_fname(file_ca)
ch = nan(length(file_ca),1);
for ii = 1:length(file_ca)
    [~,n] = fileparts(file_ca{ii});
    ch(ii) = str2double(n(end-2:end));
end