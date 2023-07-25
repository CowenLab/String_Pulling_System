function INTAN_Inspect_and_delete_bad_channels()
% Assumes you are running in the data directory.
% E:\Data\Transcranial_Optogenetics\Mouse4\Depth_660uM_220217_133346
ff = find_files('amp*.dat');
group_size = 10;
subsamp = 10;
input_restrict = 1000; % So that data can be seen - blank out data above this.
file_intervals = 1:group_size:length(ff);
file_intervals(end) = length(ff)+1;
%%
for ii = 1:(length(file_intervals)-1)
    file_ids = file_intervals(ii):(file_intervals(ii+1))-1;
    L = []; fname = [];
    for jj = 1:length(file_ids)
        L(jj,:) = INTAN_Read_DAT_file(ff{file_ids(jj)});
        fname{jj} = ff{file_ids(jj)};
    end
    L = L(:,1:subsamp:end);
    L = L - trimmean(L,5,2);
    L(abs(L)>input_restrict) = input_restrict;
    % plot
    clf
    plot_LFP(L',[],[],fname)
    pause
end