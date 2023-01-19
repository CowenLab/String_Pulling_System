function LK_Session_Iterator(Analysis_function, SES)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%e%%%%%%%%%%%%%%%
% Cowen 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global DIRS
tic
cur_dir = pwd; % Grab the current working directory.
Analysis_function_string = func2str(Analysis_function); % The name of the function called.
output_directory = fullfile(DIRS.Analysis_Dir ,Analysis_function_string);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make analysis output directory (where we store all of the analysis results)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist(output_directory,'dir')
    mkdir(output_directory)
end
delete(fullfile(output_directory,'Dset*.mat')); % this ensures that analyses do not overlap. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make a copy of the main code so that we know how the parameters were set.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    copyfile(which(Analysis_function_string),output_directory)
catch
    disp('Could not copy mfile')
end

disp(['Starting to process ' num2str(Rows(SES)) ' sessions in ' DIRS.Data_Dir ])
for iSes = 1:Rows(SES) %39 4  3 11
    ca
    sesdir = fullfile(DIRS.Data_Dir,sprintf('Rat%d',SES.Rat(iSes)),sprintf('%02.0f',SES.Session(iSes)));
    cd (sesdir);
    out_fname = fullfile(output_directory,sprintf('Dset_Rat_%d_%0.2d.mat', SES.Rat(iSes), SES.Session(iSes)));
    fprintf('%d)',iSes);
    disp(SES(iSes,:))
    [Dset]= Analysis_function(); % Run the function (assumes it saves all of the relevant data and images).
    Dset.iSes = iSes;
    Dset.session_directory = pwd;
    Dset.SES = SES(iSes,:);
    save(out_fname,'-struct','Dset','-v7.3')
    try
        save(fullfile(output_directory,'last_iSes.txt'),'iSes','-ascii')
    end
end
cd(cur_dir) % go back home
sprintf('That took %1.4f minutes.',toc/60)