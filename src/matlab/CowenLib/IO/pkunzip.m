function o = pkunzip(fname,action,exe_dir)
%function o = pkunzip(fname,action,exe_dir)
% 
% cowen
c = pwd;
[tp,tn,te] = fileparts(fname);
cd(tp) % stupid but matlab demands it.
if nargin < 3
   [ exe_dir,d,e] = fileparts(which(mfilename));
end
if nargin < 2
    action = 'extract'
end
switch action
    case 'extract'
        dos(['"' fullfile(exe_dir,'pkunzip.exe') '" -e ' [tn te]])
    otherwise
        error('Unknown action')
end
cd (c)