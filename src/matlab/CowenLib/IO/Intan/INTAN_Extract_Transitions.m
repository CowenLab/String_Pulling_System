function EVT_IDs = INTAN_Extract_Transitions(event_file, Event_Threshold, invert)
% turns the sparse data files into dense collections of transition timestamps.

if nargin <3
    invert = false; %finds down instead of up transitions
end

if nargin <2
    Event_Threshold = 1; %"2" would be a good input argument for an analog channel taking a TTL input.
end

nChannels = 1; %Good starting point here for adding multiple channels per data file format.
infoFile = dir(event_file);
if isempty(infoFile)
    error('File not found')
end

precision = [];
precisionBytes = [];
cnv = [];
filetype_handler(event_file);

chunk = 1e6;
start_rec_id = 0;
Rec_IDs_past_threshold = [];

nrecs = floor(infoFile.bytes/2); % int16 so 2 bytes per rec.
chunk = min([chunk nrecs]);
nbChunks = floor(infoFile.bytes/(nChannels*chunk*precisionBytes));
%warning off
if nbChunks==0
    chunk = infoFile.bytes/(nChannels*precisionBytes);
end

%First Chunk
chunkops(event_file, precision, 0, chunk)

% Subsequent Regular Chunks
for ix=1:nbChunks-1
    
    if start_rec_id > max([])
        break
    end
    chunkops(event_file, precision, ix, chunk)
end

% Last Chunk
newchunk = infoFile.bytes/(precisionBytes*nChannels)-nbChunks*chunk;
if newchunk
    if start_rec_id > max([])
    else
        chunkops(event_file, precision, nbChunks, newchunk)
    end
end

IX = diff([0 Rec_IDs_past_threshold])>5;
IXd = diff([0 Rec_IDs_past_threshold])<0;
EVT_IDs = Rec_IDs_past_threshold(IX)+1; %add one because they're all going to be the rec BEFORE the transition rec and this bugged me about the ampx version of this code.

    function chunkops(file, format, offset, repeat)
        
        m = [];
        d = [];
        mmapops();
        if ~invert
            Rec_IDs_past_threshold = [Rec_IDs_past_threshold find(d>=Event_Threshold)+start_rec_id];
        else
            Rec_IDs_past_threshold = [Rec_IDs_past_threshold find(d<Event_Threshold)+start_rec_id];
        end
        start_rec_id = start_rec_id + size(d,precisionBytes);
        
        clear m d;
        function mmapops()
            m = memmapfile(file,'Format',format,'Offset',offset*chunk*nChannels*precisionBytes,'Repeat',repeat*nChannels,'writable',true);
            d = m.Data;
            d = reshape(d,[nChannels repeat]);
            d = d * cnv;
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
        cnv = 0.195;
        precisionBytes = 2;
        
        switch prefix
            case 'tim'
                if (~isEmpty(strfind(n,'time')))
                    error('cannot read time file as event file')
                else
                    precision = 'int16';
                    precisionBytes = 2;
                    cnv = 0.195;
                    nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
                    disp('(Reading as Amplifier)');
                end
            case 'amp'
                precision = 'int16';
                precisionBytes = 2;
                cnv = 0.195; % to microvolts
                nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
            case 'aux'
                precision = 'uint16';
                precisionBytes = 2;
                cnv = 0.0000374; % to volts
                nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
            case 'vdd'
                precision = 'uint16';
                precisionBytes = 2;
                cnv = 0.0000748; % to volts
                nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
            case 'boa'
                switch n(1:9);
                    case 'board-ADC'
                        precision = 'uint16';
                        cnv = 0.000050354; % to volts
                    case 'board-DIN';
                        precision = 'uint16';
                        cnv = 1; % (keep binary)
                    case 'board-DOU'
                        precision = 'uint16';
                        cnv = 1; % (keep binary)
                end
                precisionBytes = 2;
                nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
            otherwise %Assume amplifier Channel
                precision = 'int16';
                precisionBytes = 2;
                cnv = 0.195;
                nrecs = floor(infoFile.bytes/(nChannels*precisionBytes));
                disp('(Reading as Amplifier)');
        end
    end
end
