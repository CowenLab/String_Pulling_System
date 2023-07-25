function DANA_Background_Subtraction(data_dir)
% filendata_dirame = 'F:\FSCV_DANA_DATA_FOR_TESTING\2018-01-23_R251_9dot2\FSCV\FSCV_cell_vta_9dot2\NAC_6dot2_cell_vta_9dot2114';
% Duration of a transient is 3-4 seconds. Max up to 11 seconds. 

data_dir = 'F:\FSCV_DANA_DATA_FOR_TESTING\2018-01-23_R251_9dot2\FSCV\FSCV_cell_vta_9dot2\';


WCCV_files_fnams = dir(data_dir);
ctr =1;
for iF = 1:length(WCCV_files_fnams)
    if ~strcmp(WCCV_files_fnams(iF).name,'.')&& ~strcmp(WCCV_files_fnams(iF).name,'..')
        [~,nams{iF},ext{iF}] = fileparts(WCCV_files_fnams(iF).name);
        if isempty(ext{iF})
            names{ctr} = nams{iF}; %the file names are placed into cells
            ctr =ctr+1;
        end
    end
end


application_freq_Hz = 5;
filtered_data = [];
for iF = 1:length(names)
    fname = fullfile(data_dir,names{iF});
    [WCCV_data_out,sampling_rate_Hz,application_freq_Hz] = WCCV_MAT_Read_WCCV_file(fname,application_freq_Hz);
    tmp = WCCV_MAT_filter_data(WCCV_data_out,sampling_rate_Hz);
    filtered_data(:,:,iF) = decimate_matrix(tmp,10);
    fprintf('.')
end
F = reshape(filtered_data,size(filtered_data,1), size(filtered_data,2)*size(filtered_data,3));
F = F - trimmean(F,20,2);

% BIX = abs(F) > 3;
% F(BIX) = nan;

FMM = movmean(F',100)';
Fsub = F-FMM;
Fsub(1:6,:) = 0;
[coeff] = pca(Fsub');
PC1 = coeff(:,1) .* F;
PC2 = coeff(:,2) .* F;


figure
subplot(2,1,1)
imagesc(Fsub)
caxis([-1.5 1.5])

title('input background')
back = ginput(2);
back =round(back(1,:));
back = sort(back);
title('input DA')
DA = ginput(2);
DA = round(DA(1,:));
DA = sort(DA);
G = NaN(Cols(filtered_data),1);
G(back(1):back(2)) = -1;
G(DA(1):DA(2)) = 1;
GIX = ~isnan(G);
mod = fitlm(filtered_data(:,GIX)',G(GIX),'linear');

subplot(2,1,2)
imagesc(PC2)
title('PC1')



