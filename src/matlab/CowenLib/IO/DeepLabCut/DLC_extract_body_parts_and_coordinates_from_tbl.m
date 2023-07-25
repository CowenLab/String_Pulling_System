function INFO = DLC_extract_body_parts_and_coordinates_from_tbl(vbls)
INFO.col_name = [];
INFO.body_part = [];
INFO.coordinate = [];
INFO.data_cols = [];
cnt = 1;
for ii = 1:length(vbls)
    if strcmpi(vbls{ii}(end-1:end),'_x')
        INFO.col_name{cnt} = vbls{ii};
        INFO.body_part{cnt} = vbls{ii}(1:end-2);
        INFO.coordinate{cnt} = 'x';
        INFO.data_cols(cnt) = ii;
        cnt = cnt + 1;
    end
    if strcmpi(vbls{ii}(end-1:end),'_y')
        INFO.col_name{cnt} = vbls{ii};
        INFO.body_part{cnt} = vbls{ii}(1:end-2);
        INFO.coordinate{cnt} = 'y';
        INFO.data_cols(cnt) = ii;
        cnt = cnt + 1;
    end
    if strcmpi(vbls{ii}(end-1:end),'_z')
        % future proofing
        INFO.col_name{cnt} = vbls{ii};
        INFO.body_part{cnt} = vbls{ii}(1:end-2);
        INFO.coordinate{cnt} = 'z';
        INFO.data_cols(cnt) = ii;
        cnt = cnt + 1;
    end
end