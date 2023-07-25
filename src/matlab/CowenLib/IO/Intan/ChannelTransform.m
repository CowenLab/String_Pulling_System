function [returnVar,msg] = ChannelTransform(fname,addVal,multVal,nbChan)
%Adapted from "RemoveDC" can be used to bias (add) or convert (multiply)
%auxillary continuous trace. Written for applying correction for gravity 
%from the accelerometer channels, otherwise it'd probably be a generic
%"perform algebraic function on channel trace" function
%Make a handler if you want to use this with other formats (eg amplifier channels)

if nargin < 4
    nbChan = 1;
end

if nargin <3
    multVal = 1;
end
fprintf('Transforming %s\n',fname)
    infoFile = dir(fname);
    chunk = 1e6;
    nbChunks = floor(infoFile.bytes /(nbChan*chunk*2));
    warning off
    if nbChunks==0
        chunk = infoFile.bytes/(nbChan*2);
    end
    m = memmapfile(fname,'Format','uint16','Repeat',chunk*nbChan,'writable',true);
    d = m.Data;
    d = reshape(d,[nbChan chunk]);
    d = uint16(d+uint16(addVal) * multVal);
    m.Data = d(:);
    clear d m
    
    for ix=1:nbChunks-1
        m = memmapfile(fname,'Format','uint16','Offset',ix*chunk*nbChan*2,'Repeat',chunk*nbChan,'writable',true);
        d = m.Data;
        d = reshape(d,[nbChan chunk]);
        d = uint16(d+uint16(addVal) * multVal);
        m.Data = d(:);
        clear d m
    end    
    
    newchunk = infoFile.bytes/(2*nbChan)-nbChunks*chunk;
    if newchunk
        m = memmapfile(fname,'Format','uint16','Offset',nbChunks*chunk*nbChan*2,'Repeat',newchunk*nbChan,'writable',true);
        d = m.Data;
        d = reshape(d,[nbChan newchunk]);
        d = uint16(d+uint16(addVal) * multVal);
        m.Data = d(:);
     clear d m
    end
    warning on
    returnVar = 1;
    msg = '';
    
clear m
