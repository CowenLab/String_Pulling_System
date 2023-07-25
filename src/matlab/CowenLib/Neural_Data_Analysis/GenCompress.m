function [original_size_bytes, compressed_size_bytes] = GenCompress(sequence_numeric_vector)
% If desired, save this sequence as a text file of ascii characters for genetic sequence
%  analysis.
origfname = 'tmpseq.txt';

fp = fopen(origfname,'w+');
fprintf(fp,'%c',sequence_numeric_vector'+64);
fclose(fp);
dr1 = dir(origfname);
try
    original_size_bytes = dr1(1).bytes;
catch
    disp('Could not create compressed file. Returning a nan.')
    original_size_bytes = nan;
end
compfname = 'tmpseq.GEN';
% Compress the file...
eval(['!C:\bin\GenCompress.exe ' origfname]);

dr2 = dir(compfname);
try
    compressed_size_bytes = dr2(1).bytes;
catch
    disp('Could not create compressed file. Returning a nan.')
    compressed_size_bytes = nan;
end
%delete(compfname);
%delete(origfname);
