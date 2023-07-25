function [D] = INTAN_Load_Dat(dat_file, sFreq, nChannels,channels_to_load, no_conv, recs_to_load)
%General all-purpose DAT_file loader. For some inscrutible reason the time
%file does not play nice with this. Use "INTAN_Load_Time" instead. The time
%file is really not strictly necessary to use except in the case of a
%triggered recording, and even then only for finding the offset in the
%first million records. Time can simply be determined from recID and
%sampling frequency.

if nargin < 2
    IF = INTAN_Read_RHD_file();
    sFreq = IF.frequency_parameters.amplifier_sample_rate;
end

if nargin < 3
    nChannels = 1;
end

if nargin < 4
    channels_to_load = 1;
end

if nargin < 5
   no_conv = true; 
end

if nargin < 6
   recs_to_load = [];
end

infoFile = dir(dat_file);
if isempty(infoFile)
    error('File not found')
end

precision = [];
precisionBytes = [];
conv = [];
filetype_handler(dat_file);

chunk = 1e6;

start_rec_id = 0;
chunk = min([chunk nrecs]);
nbChunks = floor(infoFile.bytes/(nChannels*chunk*precisionBytes));
%warning off
if nbChunks==0
    chunk = infoFile.bytes/(nChannels*precisionBytes);
end

%First Chunk
chunkops(dat_file, precision, 0, chunk)

% Subsequent Regular Chunks
for ix=1:nbChunks-1
    if start_rec_id > max(recs_to_load)
        break
    end
    chunkops(dat_file, precision, ix, chunk)
end

% Last Chunk
newchunk = infoFile.bytes/(precisionBytes*nChannels)-nbChunks*chunk;
if newchunk
    if start_rec_id > max(recs_to_load)
    else
        chunkops(dat_file, precision, nbChunks, newchunk)
    end
end

if ~isempty(recs_to_load)
    D = D(:,recs_to_load);
end

    function chunkops(file, format, offset, repeat)
        
        m = [];
        d = [];
        mmapops();
        d = d(channels_to_load,:);
        cast(d,format);
        if(strcmp(format,'uint32'))
            D = D';
            D(:,(1:size(d,precisionBytes))+start_rec_id) = d(channels_to_load,:);
        else
            D(:,(1:size(d,precisionBytes))+start_rec_id) = d(channels_to_load,:);
        end

        start_rec_id = start_rec_id + size(d,precisionBytes);
        clear m d;
        function mmapops()
            m = memmapfile(file,'Format',format,'Offset',offset*chunk*nChannels*precisionBytes,'Repeat',repeat*nChannels,'writable',true);
            d = m.Data;
            d = reshape(d,[nChannels repeat]);
            if(~no_conv)
                d = d * conv;
            end
        end
        
    end


    function filetype_handler(file)
        %%Determine what sort of channel this file represents and preallocate for
        %%first chunk
        [~,n,e] = fileparts(file);
        prefix = [];
        if (length(n) >= 3)
            prefix = n(1:3);
        end
        %Set Defaults for Amplifier Channel (as in case of tetrode files)
        precision = 'int16';
        conv = 0.195;
        precisionBytes = 2;
        switch prefix
            case 'tim'
                precision = 'int32';
                precisionBytes = 4; %4 byes for 32 bit integer
                conv = 1/sFreq; %to seconds
                nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
                %Note. This does really strange things and I've been using
                %"INTAN_Load_Time" for this purpose instead. Can't figure
                %out why but this next line, despite being like all the
                %others, transposes the matrix:
                D = int32(zeros(length(channels_to_load),nrecs));
            case 'amp'
                precision = 'int16';
                precisionBytes = 2;
                conv = 0.195; % to microvolts
                nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
                D = int16(zeros(length(channels_to_load),nrecs));
            case 'aux'
                precision = 'uint16';
                precisionBytes = 2;
                conv = 0.0000374; % to volts
                nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
                D = uint16(zeros(length(channels_to_load),nrecs));
            case 'vdd'
                precision = 'uint16';
                precisionBytes = 2;
                conv = 0.0000748; % to volts
                nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
                D = uint16(zeros(length(channels_to_load),nrecs));
            case 'boa'
                switch n(1:9);
                    case 'board-ADC'
                        precision = 'uint16';
                        conv = 0.000050354; % to volts
                    case 'board-DIN';
                        precision = 'uint16';
                        conv = 1; % (keep binary)
                    case 'board-DOU'
                        precision = 'unit16';
                        conv = 1; % (keep binary)
                end
                precisionBytes = 2;
                nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
                D = uint16(zeros(length(channels_to_load),nrecs));
            otherwise %Assume amplifier Channel
                precision = 'int16';
                precisionBytes = 2;
                conv = 0.195;
                nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
                D = int16(zeros(length(channels_to_load),nrecs));
        end
    end
end
