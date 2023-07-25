function A = Analysis_dir()
%%%%%%%%%%%%%%%%%%%%%%%%%%
% Return the data analysis director
%%%%%%%%%%%%%%%%%%%%%%%%%%
A = [];
possible_dirs = {fullfile(Dropbox_dir,'Foldershare','Analysis_Results_Dropbox'), ...
    'C:\Cowen\Analysis_results','C:\Temp\Analysis_results'};
for ii =1:length(possible_dirs)
    if exist(possible_dirs{ii},'dir')
        A = possible_dirs{ii};
        return
    end
end

if isempty(A)
    error([mfilename ': Could not find directory. ' A ])
end
