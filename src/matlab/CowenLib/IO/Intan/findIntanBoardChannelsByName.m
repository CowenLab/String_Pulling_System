function filename = findIntanBoardChannelsByName(name,IF,type)
%Goes Through metadata and finds board channel named as specified in input.

if nargin <3
    type = 'digital in';
end

if nargin <2
    IF = INTAN_Read_RHD_file();
end

filename = '';
index = findind(name);
if ~isempty(index)
    filename = findfile(index);
else
    disp(['Channel not Found!']);
end

    function ind = findind(searchname)
        ind = [];
        switch type
            case 'digital in'
                if isfield(IF,'board_dig_in_channels')
                    for i = 1:numel(IF.board_dig_in_channels)
                        if strcmpi(IF.board_dig_in_channels(i).custom_channel_name,searchname);
                            ind = i;
                        end
                    end
                end
            case 'digital out'
                if isfield(IF,'board_dig_out_channels')
                    for i = 1:numel(IF.board_dig_out_channels)
                        if strcmpi(IF.board_dig_out_channels(i).custom_channel_name,searchname);
                            ind = i;
                        end
                    end
                end
            case 'analog in'
                if isfield(IF,'board_adc_channels')
                    for i = 1:numel(IF.board_adc_channels)
                        if strcmpi(IF.board_adc_channels(i).custom_channel_name,searchname);
                            ind = i;
                        end
                    end
                end
            otherwise
                error('Unrecognized Input Type');
        end
    end

    function file = findfile(ix)
        switch type
            case 'digital in'
                file = strcat('board-',IF.board_dig_in_channels(ix).native_channel_name,'.dat');
            case 'digital out'
                file = strcat('board-',IF.board_dig_out_channels(ix).native_channel_name,'.dat');
            case 'analog in'
                file = strcat('board-',IF.board_adc_channels(ix).native_channel_name,'.dat');
            otherwise
                error('Unrecognized Input Type');
        end
    end
end

