function highpass_dat_file(fname,sFreq,fCutoff)
% Adapted from "RemoveDCfromDat.m" Adrien Peyrache 2011
% Might be fun to switch it over to the chunked operations template
nbChan = 1;

if nargin < 3
    fCutoff = 250;
end
if nargin < 2
    IF = INTAN_Read_RHD_file();
    sFreq = IF.frequency_parameters.amplifier_sample_rate;
end
if nargin < 1
    error('no file');
end

%Set up filter
aHpf = exp(-1.0 * 2 * pi * fCutoff / sFreq);
bHpf = 1.0 - aHpf;

disp(['High-pass Filtering ' fname ' at ' num2str(fCutoff) ' Hz']);
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

d = double(d);

%Apply Filter

out = zeros(1,chunk);
out(1) = d(1);
HpfState = 0;
for i=2:chunk
    temp = d(i);
    out(i) = (d(i) - HpfState);
    HpfState = (aHpf * temp) + (bHpf * HpfState);
end

d = int16(out);

m.Data = d(:);
clear d m

for ix=1:nbChunks-1
    m = memmapfile(fname,'Format','int16','Offset',ix*chunk*nbChan*2,'Repeat',chunk*nbChan,'writable',true);
    d = m.Data;
    d = reshape(d,[nbChan chunk]);
    
    d = double(d);
    
    %Apply Filter
    out = zeros(1,chunk);
    out(1) = d(1);
    HpfState = 0;
    for i=2:chunk
        temp = d(i);
        out(i) = (d(i) - HpfState);
        HpfState = (aHpf * temp) + (bHpf * HpfState);
    end
    
    d = int16(out);
    
    m.Data = d(:);
    clear d m
end

newchunk = infoFile.bytes/(2*nbChan)-nbChunks*chunk;

if newchunk
    m = memmapfile(fname,'Format','int16','Offset',nbChunks*chunk*nbChan*2,'Repeat',newchunk*nbChan,'writable',true);
    d = m.Data;
    d = reshape(d,[nbChan newchunk]);
    
    d = double(d);
    
    %Apply Filter
    out = zeros(1,newchunk);
    out(1) = d(1);
    HpfState = 0;
    for i=2:newchunk
        temp = d(i);
        out(i) = (d(i) - HpfState);
        HpfState = (aHpf * temp) + (bHpf * HpfState);
    end
    
    d = int16(out);
    
    m.Data = d(:);
    clear d m
end

warning on

clear m
