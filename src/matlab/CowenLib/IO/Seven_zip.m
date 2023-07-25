function Seven_zip(fnames,delete_after)
% Runs 7z.exe. Compresses and deletes files
% Compress
% expects either a cell array or not
% cowen 2019
if nargin < 2
    delete_after = true;
end

if ~iscell(fnames)
    fnames = {fnames};
end
disp(['Processing ' num2str(length(fnames)) ' files'])
% sys_cmd_zip = @(zd) ['"C:\Program Files\7-Zip\7z.exe" a "' zd '.zip" "' zd '"'];
% cellfun(@(zd) system(sys_cmd_zip(zd)),fnames,'uniformoutput',false);

for iF = 1:length(fnames)
    system(['"C:\Program Files\7-Zip\7z.exe" a "' fnames{iF} '.zip" "' fnames{iF} '"'])
    if delete_after
        d = dir([fnames{iF} '.zip']);
        if d.bytes > 19000
            delete(fnames{iF})
        end
    end
    disp([num2str(iF) ' of ' num2str(length(fnames)) ' complete.'])
end