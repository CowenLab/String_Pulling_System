function [S_ctsa,T] = Load_spikes_to_struct(tfile_list)
%
% Purpose: Load in a ctsa object of spike times.
%
% Input: 
%        A filename that contains a list of all the tfiles
%
% Output:
%        A ctsa of spike times.
%        A vector of lenght equal to the number of cells, listing the 
%          tetrode each cell belongs to. (Assumes tfiles are in TET_* directories)

S = [];
if nargin == 1
    isBigEndian = 1; % PCs are littleendian, Unix is bigendian, but for some reason, tfiles are stored bigendian. The question is how was the tfile saved.
end

if iscell(tfl)
    for ii = 1:length(tfl)
        S{ii} = loadit(tfl{ii}, isBigEndian);
    end
else
    S = loadit(tfl, isBigEndian);
end

function o = loadit(Filename,isBigEndian)
% loads the data.
if isBigEndian
    tfp = fopen(Filename, 'rb','b');
else
    tfp = fopen(Filename, 'rb');
end

if (tfp == -1)
    warning([ 'Could not open tfile ' Filename]);
    o = [];
else
    ReadHeader(tfp);    
    o = fread(tfp,inf,'uint32');	%read as 32 bit ints
    fclose(tfp);
end