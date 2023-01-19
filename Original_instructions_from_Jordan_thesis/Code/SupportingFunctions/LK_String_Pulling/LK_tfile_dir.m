function td = LK_tfile_dir(DATA_DIR)
if nargin < 1
    DATA_DIR = pwd;
end
tmp = dir(fullfile(DATA_DIR,'*_processed*'));

cnt = 1; dd = [];
for ii = 1:length(tmp)
    if tmp(ii).isdir
        dd = [dd;tmp(ii)];
        cnt = cnt + 1;
    end
end

if length(dd) > 1 
    pwd
    disp('WARNING: Should only be ONE processed directory. Choosing the first.')
end
td = fullfile(DATA_DIR,dd(1).name);
