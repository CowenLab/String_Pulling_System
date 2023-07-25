function Remove_DC(fname,nbChan)
% Adapted from "RemoveDCfromDat.m" Adrien Peyrache 2011
% Might be fun to switch it over to the chunked operations template

if nargin == 1
    nbChan = 1;
end

fprintf('Removing baseline from %s\n',fname)
    infoFile = dir(fname);
    chunk = 1e6;
    nbChunks = floor(infoFile.bytes /(nbChan*chunk*2));
    warning off
    if nbChunks==0
        chunk = infoFile.bytes/(nbChan*2);
    end
    m = memmapfile(fname,'Format','int16','Repeat',chunk*nbChan,'writable',true);
    d = m.Data;
    d = reshape(d,[nbChan chunk]);
    meanD = mean(d,2);
    d = d-int16(meanD*ones(1,chunk));
    m.Data = d(:);
    clear d m
    
    for ix=1:nbChunks-1
        m = memmapfile(fname,'Format','int16','Offset',ix*chunk*nbChan*2,'Repeat',chunk*nbChan,'writable',true);
        d = m.Data;
        d = reshape(d,[nbChan chunk]);
        d = d-int16(meanD*ones(1,chunk));
        m.Data = d(:);
        clear d m
    end    
    
    newchunk = infoFile.bytes/(2*nbChan)-nbChunks*chunk;
    
    if newchunk
        m = memmapfile(fname,'Format','int16','Offset',nbChunks*chunk*nbChan*2,'Repeat',newchunk*nbChan,'writable',true);
        d = m.Data;
        d = reshape(d,[nbChan newchunk]);
        d = d-int16(meanD*ones(1,newchunk));
        m.Data = d(:);
     clear d m
    end
    
    warning on
    
clear m
