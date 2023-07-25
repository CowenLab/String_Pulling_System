function INTAN_Extract_LFP(IF, LFP_sFreq, anti_alias, Reference_Ch)
%Takes any channel labeled "is_LFP" from the header file and downsamples
%it. Additionally, a matching time vector file is included. Note that you
%still divide this new time vector by the original sample frequency to get
%the elapsed recording time, not the downsampling frequency. The new
%vector simply has a matching number of records.

if nargin < 4
    Reference_Ch = [];
end

if nargin <3
    anti_alias = true;
end

if nargin <2
    LFP_sFreq = 10000;
end

if nargin <1 || isempty(IF)
    IF = INTAN_Read_RHD_file();
end

% load relevant meta data.
orig_sFreq = IF.frequency_parameters.amplifier_sample_rate;
LFP_Chs = find([IF.amplifier_channels.is_LFP]);

if isempty(LFP_Chs)
    disp('no LFP Channels marked')
    return
end

n_recs_to_skip = floor(orig_sFreq/LFP_sFreq);
if n_recs_to_skip == 1
    % If the output sfreq is the same as the input, no need to anti-alias
    anti_alias = false;
end

nChannels = 1; %here would be a good place to add a handler for the "file per signal type" format in the future but good for now.

% Go through each channel sequentially and convert to LFP. In theory
% performing matrix operations all at once is more efficient but in
% practice this is faster and tidier.
for ii = 1:length(LFP_Chs)
    if isempty(Reference_Ch)
        out_filename = ['LFP_Ch_' num2str(LFP_Chs(ii)) '_Skip_' num2str(n_recs_to_skip) '.datlfp'];
        ref_filename = [];
    else
        out_filename = ['LFP_Ch_' num2str(LFP_Chs(ii)) '_Ref_' num2str(Reference_Ch) '_Skip_' num2str(n_recs_to_skip) '.datlfp'];
        ref_filename = strcat('amp-',IF.amplifier_channels(Reference_Ch).native_channel_name,'.dat');
    end
    in_filename = strcat('amp-',IF.amplifier_channels(LFP_Chs(ii)).native_channel_name,'.dat');
    disp(['Resampling LFP Channel ' in_filename ' to ' num2str(LFP_sFreq) ' Hz']);
    dat_to_lfp(in_filename,out_filename,ref_filename)
end

% Create an LFP time vector that is indexed appropriately
disp('Creating matching time vector file time_lfp.dat');
anti_alias = false; %don't filter the time vector
dat_to_lfp('time.dat','time_lfp.dat',[]);

function dat_to_lfp(dat_file,lfp_file,ref_file) 
    fp = fopen(lfp_file,'wb');
    infoFile = dir(dat_file);
    if isempty(infoFile)
        error('File not found')
    end
    
    %Handle case where we convert the time vector file.
    precisionMultiplier = 2;
    if strcmp(dat_file,'time.dat')
        precision = 'uint32';
        precisionMultiplier = 4;
    else
        precision = 'int16';
    end
    
    chunk = 1e6; % Take 1 million records by default for the first bit.
    nrecs = floor(infoFile.bytes/(nChannels*precisionMultiplier));
    
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
end

end