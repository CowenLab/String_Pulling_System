function sz = Find_compressed_size(M)
% Finds the size of the data in M, when compressed using pkzip
% this is useful for measureing KS complexity.
% INPUT: matrix to compress
% OUTPUT: size of compressed matrix (in bytes).
% cowen
fname = fullfile(pwd,'tmp.bin');
fp = fopen(fname,'wb');
fwrite(fp,M,'integer*2');
fclose(fp);
if fp < 1
    error('Could not create file')
end

% zip it, zip it good.
%eval(['!C:\bin\wzzip tmpzip tmp_original_file.bin' ]); % Eval version
%requires a ^c to continue. Need to get real version.
eval(['!C:\bin\pkzip.exe tmpzip ' fname ]);
dr = dir('tmpzip.zip');
try
    sz = dr(1).bytes;
    delete('tmpzip.zip');
catch
    disp('Could not create zip file. Returning a nan.')
    sz = nan;
end
delete('tmp.bin');
return