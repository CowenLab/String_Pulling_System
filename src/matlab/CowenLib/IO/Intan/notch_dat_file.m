function notch_dat_file(fname,sFreq,fNotch,Bandwidth)
% Adapted from "RemoveDCfromDat.m" Adrien Peyrache 2011
% Might be fun to switch it over to the chunked operations template
nbChan = 1;

if nargin < 4
    Bandwidth = 10;
end
if nargin < 3
    fNotch = 60;
end
if nargin < 2
    IF = INTAN_Read_RHD_file();
    sFreq = IF.frequency_parameters.amplifier_sample_rate;
end
if nargin < 1
    error('no file');
end

%Set up filter
tstep = 1/sFreq;
Fc = fNotch*tstep;
dn = exp(-2*pi*(Bandwidth/2)*tstep);
b = (1 + dn*dn)*cos(2*pi*Fc);
a0 = 1;
a1 = -b;
a2 = dn*dn;
a = (1 + dn*dn)/2;
b0 = 1;
b1 = -2*cos(2*pi*Fc);
b2 = 1;

disp(['Applying notch filter to ' fname]);
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
out(2) = d(2);
for i=3:chunk
    out(i) = (a*b2*d(i-2) + a*b1*d(i-1) + a*b0*d(i) - a2*out(i-2) - a1*out(i-1))/a0;
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
    out(2) = d(2);
    for i=3:chunk
        out(i) = (a*b2*d(i-2) + a*b1*d(i-1) + a*b0*d(i) - a2*out(i-2) - a1*out(i-1))/a0;
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
    out(2) = d(2);
    for i=3:newchunk
        out(i) = (a*b2*d(i-2) + a*b1*d(i-1) + a*b0*d(i) - a2*out(i-2) - a1*out(i-1))/a0;
    end
    
    d = int16(out);
    
    m.Data = d(:);
    clear d m
end

warning on

clear m
