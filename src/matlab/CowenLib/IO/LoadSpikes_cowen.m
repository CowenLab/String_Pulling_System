function S = LoadSpikes_cowen(tfilelist)
%x
% S = LoadSpikes(tfilelist)
%
% inp: tfilelist is a cellarray of strings, each of which is a
% 	tfile to open.  Note: this is incompatible with version unix3.1.
% out: Returns a cell array such that each cell contains a ts
% 	object (timestamps which correspond to times at which the cell fired)

nFiles = length(tfilelist);

%--------------------
% Read files
%--------------------

% for each tfile
% first read the header, the read a tfile
% note: uses the bigendian modifier to ensure correct read format.

S = cell(nFiles, 1);
for iF = 1:nFiles
    tfn = tfilelist{iF};
    if ~isempty(tfn)
        tfp = fopen(tfn, 'rb','b');
        if (tfp == -1)
            warning([ 'Could not open tfile ' tfn]);
        end
        
        ReadHeader(tfp);
        SS = fread(tfp,inf,'uint64');	%read as 32 bit ints
        
        S{iF}.t_uS = SS*100;
        
        fclose(tfp);
        
    end 		% if tfn valid
end		% for all files
