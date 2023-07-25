function INTAN_DAT_to_LFP(dat_file,LFP_sFreq, anti_alias,ref_file,lfp_file)
%LFP Resampling for just one file.
%INTAN_Extract_LFP works off the header file.

if nargin < 5
    [p,n] = fileparts(which(dat_file));
    lfp_file = strcat(p,n,'.datlfp');
end

if nargin < 4
    ref_file = [];
end

if nargin <3
    anti_alias = true;
end

fp = fopen(lfp_file,'wb');
infoFile = dir(dat_file);
if isempty(infoFile)
    error('File not found')
end

precision = [];
precisionMultiplier = [];
conv = [];
nChannels= 1;
%Filetype handler
filetype_handler(dat_file);

chunk = 1e6; % Take 1 million records by default for the first bit.
nrecs = floor(infoFile.bytes/(nChannels*precisionMultiplier));
n_recs_to_skip =1;
start_rec_id = 0;
RecID = 1:n_recs_to_skip:nrecs;

chunk = min([chunk nrecs]);
nbChunks = floor(infoFile.bytes/(nChannels*chunk*precisionMultiplier));
%warning off
if nbChunks==0
    chunk = infoFile.bytes/(nChannels*precisionMultiplier);
end

%First Chunk
chunkops(0, chunk);

%Subsequent, regular chunks
for ix=1:nbChunks-1
    chunkops(ix, chunk);
end

% Last, irregular Chunk
newchunk = infoFile.bytes/(precisionMultiplier*nChannels)-nbChunks*chunk;
if newchunk
    chunkops(nbChunks, newchunk);
end
save('LFP_RecIDs','RecID', 'LFP_sFreq');
fclose(fp);

%Resampling happens here.
    function chunkops(offset_multiplier, chunksize)
        m = memmapfile(dat_file,'Format',precision,'Offset',offset_multiplier*chunk*nChannels*precisionMultiplier,'Repeat',chunksize*nChannels,'writable',true);        d = m.Data;
        d = reshape(d,[nChannels chunksize]);
        
        % %%
        rec_ids = (1:size(d,2))+start_rec_id;
        [recs_to_save, rec_save_ix] = intersect(rec_ids, RecID);
        
        if ~isempty(ref_file)
            % Re-Reference.
            rf = memmapfile(ref_file,'Format',precision,'Offset',offset_multiplier*chunk*nChannels*precisionMultiplier,'Repeat',chunksize*nChannels,'writable',true);
            r = rf.Data;
            r = reshape(r,[nChannels chunksize]);
            d = d-r;
            clear r;
        end
        
        if anti_alias
            %Slow
            d2 = decimate(double(d),orig_sFreq/(LFP_sFreq))'; % downsample to prevent aliasing
            local_rec_IDs = linspace(offset_multiplier*chunk+1,offset_multiplier*chunk+size(d,2),length(d2));
            [d3] = interp1(local_rec_IDs,d2,recs_to_save);
            fwrite(fp, cast(d3,precision), precision);
        else
            %Fast
            fwrite(fp, d(:,rec_save_ix), precision);
        end
        
        start_rec_id = start_rec_id + size(d,precisionMultiplier);
        
        clear d m
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
        precisionMultiplier = 2;
        switch prefix
            case 'tim'
                precision = 'int32';
                precisionMultiplier = 4; %4 byes for 32 bit integer
                conv = 1/sFreq; %to seconds
                nrecs = floor(infoFile.bytes/(nChannels*precisionMultiplier));
                %Note. This does really strange things and I've been using
                %"INTAN_Load_Time" for this purpose instead. Can't figure
                %out why but this next line, despite being like all the
                %others, transposes the matrix:
            case 'amp'
                precision = 'int16';
                precisionMultiplier = 2;
                conv = 0.195; % to microvolts
                nrecs = floor(infoFile.bytes/(nChannels*precisionMultiplier));
            case 'aux'
                precision = 'uint16';
                precisionMultiplier = 2;
                conv = 0.0000374; % to volts
                nrecs = floor(infoFile.bytes/(nChannels*precisionMultiplier));
            case 'vdd'
                precision = 'uint16';
                precisionMultiplier = 2;
                conv = 0.0000748; % to volts
                nrecs = floor(infoFile.bytes/(nChannels*precisionMultiplier));
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
                precisionMultiplier = 2;
                nrecs = floor(infoFile.bytes/(nChannels*precisionMultiplier));
            otherwise %Assume amplifier Channel
                precision = 'int16';
                precisionMultiplier = 2;
                conv = 0.195;
                nrecs = floor(infoFile.bytes/(nChannels*precisionMultiplier));
        end
    end
end