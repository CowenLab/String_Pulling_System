function Remove_DC_and_Apply_Hardware_Mask(fname,mask_channel_fname,nbChan)
% Adapted from "RemoveDCfromDat.m" Adrien Peyrache 2011
% Applying the DC removal serially to each of the data files represents a
% sunk cost. We can cram in other functions into these read-throughs of the
% file. This file will use one of the board digital input channels as a
% mask and cancel out the corresponding amplifier channel indices--useful
% for removing the stimulus artifact from a continuous trace.
% Cowen - fixed an apparent problem with the mask.
% Cowen - the mask was set to uint I changed to int16 to keep consistent
% with the data files. Removed redundant type conversions.
% Cowen - added trimmean to mitigate impact of artifacts.
% Cowen - fixed another bug in the masking.
% Cowen - added support for passing in a vector of rec-ids instead of a
% mask file for records to blank out.
% Rauscher - Didn't change anything but just to note the mask is a digital 
% input channel which are uint16 unlike the int16 amp channels and this is
% why I was loading that way. Might be handy to know in case a weird 
% casting bug pops up or something. (thanks: stephen)

if nargin < 3
    nbChan = 1;
end

if nargin <2
    mask_channel_fname = '';
end

if ~exist(mask_channel_fname,'file')
    mask_channel_fname = '';
end

fprintf('Removing baseline from %s\n',fname)
infoFile = dir(fname);
chunk = 1e6;
nbChunks = floor(infoFile.bytes /(nbChan*chunk*2));
% warning off
if nbChunks==0
    chunk = infoFile.bytes/(nbChan*2);
end
m = memmapfile(fname,'Format','int16','Repeat',chunk*nbChan,'writable',true);
d = m.Data;
d = reshape(d,[nbChan chunk]);
RecIDs = 1:size(d,2);

meanD = trimmean(d,90,2);% use trimmean so that artifacts don't bias the est of mean.
% meanD = mean(d,2);
d = d-int16(meanD*ones(1,chunk));
if(~isempty(mask_channel_fname))
    if ischar(mask_channel_fname)
        n = memmapfile(mask_channel_fname,'Format','int16','Repeat',chunk*nbChan,'writable',false);
        e = n.Data;
        e = reshape(e,[nbChan chunk]);
        d(e == 0) = 0;
    else % assume the user passed in a vector of recIDs to blank out.
        bad_ix = intersect(RecIDs, mask_channel_fname);
        if ~isempty(bad_ix)
            d(bad_ix) = 0;
        end
    end
end
m.Data = d(:);
for ix=1:nbChunks-1
    m = memmapfile(fname,'Format','int16','Offset',ix*chunk*nbChan*2,'Repeat',chunk*nbChan,'writable',true);
    d = m.Data;
    d = reshape(d,[nbChan chunk]);
    RecIDs = (1:size(d,2)) + ix*chunk;
    
    d = d-int16(meanD*ones(1,chunk));
    if(~isempty(mask_channel_fname))
        if ischar(mask_channel_fname)
            
            n = memmapfile(mask_channel_fname,'Format','int16','Offset',ix*chunk*nbChan*2,'Repeat',chunk*nbChan,'writable',false);
            e = n.Data;
            e = reshape(e,[nbChan chunk]);
            d(e==0) = 0;
        else % assume the user passed in a vector of recIDs to blank out.
            bad_ix = intersect(RecIDs, mask_channel_fname);
            if ~isempty(bad_ix)
                d(bad_ix) = 0;
            end
        end
    end
    m.Data = d(:);
end

newchunk = infoFile.bytes/(2*nbChan)-nbChunks*chunk;
if newchunk && nbChunks > 0
    m = memmapfile(fname,'Format','int16','Offset',nbChunks*chunk*nbChan*2,'Repeat',newchunk*nbChan,'writable',true);
    d = m.Data;
    d = reshape(d,[nbChan newchunk]);
    RecIDs = (1:size(d,2)) + (ix+1)*chunk;
    
    d = d-int16(meanD*ones(1,newchunk));
    if(~isempty(mask_channel_fname))
        if ischar(mask_channel_fname)
            
            n = memmapfile(mask_channel_fname,'Format','int16','Offset',nbChunks*chunk*nbChan*2,'Repeat',newchunk*nbChan,'writable',false);
            e = n.Data;
            e = reshape(e,[nbChan newchunk]);
            d(e==0) = 0; % may want to do some interpolation here.
        else % assume the user passed in a vector of recIDs to blank out.
            bad_ix = intersect(RecIDs, mask_channel_fname);
            if ~isempty(bad_ix)
                d(bad_ix) = 0;
            end
        end
    end
    m.Data = d(:);
end
