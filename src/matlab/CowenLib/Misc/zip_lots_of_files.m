% zip up a bunch of files.
% just run this in the top level directory and choose your file type.
ff = FindFiles('*.ncs');
out_ext = '.ncs.zip';
for iF  = 1:length(ff)
    ff{iF}
    [p,n,e] = fileparts(ff{iF});
    zip(fullfile(p,[ n out_ext]), ff{iF});
    d = dir(fullfile(p,[ n out_ext]));
    if d.bytes > 19000
        delete(ff{iF})
    end
end