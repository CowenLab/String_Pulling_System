function H = Read_nlx_header(header_cell_array)
%function H = Read_nlx_header(header_cell_array)
% Reads the neuralynx header information and returns a structure with the values.
%  INPUT: A cell array containing the header information such as the header
%     output from the nlx2mat functions.
%  OUTPUT: A structure containing the header values.
%
% cowen 11/11/03, 09
%
% NOTE: for some reason, the first record of the .ncs file is earlier (for
% .ncs that would be  0.422449 sec earlier which is exactly one block
% record worth of data. This means that as is usual, neuralynx screwed up
% the IO.
%%%%%%%%%%%%%%%%%%%%%%%%%
t1 = [];
if ischar(header_cell_array)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % the user passed in a file name, open it and get the header
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     FieldSelection = [0 0 0 0 0];
%     ExtractHeader  = 1;
%     ExtractMode = 1;
%     ModeArray   = [ ]; % 

    FieldSelection = [1 0 0 0 0];
    ExtractHeader  = 1;
    ExtractMode = 3; % 1=Get all records, 3=index list.
    ModeArray   = [1 ]; 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [p,n,e] = fileparts(header_cell_array);

    switch(lower(e))
        case '.ncs'
            [t1 header_cell_array] = Nlx2MatCSC( header_cell_array, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
        case {'.ntt' '.nse' '.nst'}
            [t1 header_cell_array] = Nlx2MatSpike( header_cell_array, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
        case '.Nev'
            [t1 header_cell_array] = Nlx2MatEV( header_cell_array, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
        case '.VT'
            [t1 header_cell_array] = Nlx2MatVT( header_cell_array, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
        otherwise
            error('Could not read file')
    end

end
H.StartTimeUsec = t1;
H.Comments{1} = [];
comment_count = 1;
for ii = 1:length(header_cell_array)
    if (length(header_cell_array{ii}) > 4)
        if findstr(header_cell_array{ii}(1:3),'#')
            % We found a comment.
            H.Comments{comment_count} = header_cell_array{ii};
            comment_count = comment_count + 1;
        else
            % We found a parameter value.
            dash_idx = findstr(header_cell_array{ii},'-');
            if ~isempty(dash_idx)
                [st val] = strtok(header_cell_array{ii}(dash_idx+1:end));
                switch st
                    case {'CheetahRev' 'NLX_Base_Class_Name' 'NLX_Base_Class_Type' '' ''}
                        if  isempty(val)
                        else
                            % remove leading and trailing blanks (no single
                            % function for this. (could use strrep, but that
                            % would get rid of embedded blanks.
                            % val1 = deblank(val(end:-1:1));
                            %val = val1(end:-1:1);
                            eval(['H.' st '= deblank(val);']);
                        end
                    case {'ADBitVolts' 'InputRange' 'SamplingFrequency' 'ADChannel' 'ThreshVal' 'AlignmentPt' 'NumADChannels' 'AcqEntName'}
                        if  isempty(val)
                        else
                            eval(['H.' st ' = str2num(val);']);
                        end
                    otherwise
                end
            end
        end
    end
end
