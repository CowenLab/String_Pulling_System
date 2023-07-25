function create_tfile_summary_file(tfile_dir)
% Create a text file that lists every t file and has a place for its
% subjective cluster quality score 
% Cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
cwd = pwd;
cd (tfile_dir)
ff = FindFiles('*.t');
fp = fopen('tfiles.txt','w');
fprintf(fp,'%% %s\n',pwd);
fprintf(fp,'%% tfile name, Stereotrode # (0 or 1), Quality(1worst -> 5best)\n')
fprintf(fp,'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n')
for iF = 1:length(ff)
    [p,n] = fileparts(ff{iF});
    fprintf(fp,'%s,,\n',n);
end
fclose(fp)
cd (cwd)