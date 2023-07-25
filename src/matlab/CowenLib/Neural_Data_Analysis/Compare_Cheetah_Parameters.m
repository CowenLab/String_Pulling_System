function Param = Compare_Cheetah_Parameters(param_filename, wv)
% NOTE: The neuralynx file is screwed up. There were not consistent about
% delimiters. In some cases they use commas, in others they use spaces, in
% others they use tabs. For this to work, replace all commas and tabs with
% a single space, resave the file and run this program.
%
% Load in the waveform file you are using to compare.
%[t,wv] = nlx2matSE(wave_filename,1,0,0,0,1,0);

% Load in the paramters, multiply and histogram.
P = textread(param_filename,'%s','commentstyle','shell','delimiter' ,' ','headerlines',40);
val = zeros(1,32);
Param.Matrix = [];
hist_size = 150;
hist_vals = [];
hist_xrange = [];
line_count = 1;
for ii = 1:length(P)
    if strcmp(P{ii},'-ParamAlgorithm')
        vbl_name = P{ii+1};
        count = 1;
        for jj = (ii+4):(ii+4+31)
            val(count) = str2num(P{jj});
            count = count + 1;
        end
        Param.Matrix = [Param.Matrix;val];

        vbl_name = strrep(vbl_name,'.','_');
        eval(['Param.' vbl_name ' = [' num2str(val) '];']);
        new_params = val*wv';
        [hv, hr] = hist(new_params,150);
        hist_vals = [hist_vals; hv];
        hist_xrange = [hist_xrange; hr];
        title_str{line_count} = vbl_name;
        line_count = line_count + 1;
    end
end
title_str{line_count} = 'Other Parameters...';
line_count = line_count + 1;
hist_vals = [hist_vals; zeros(size(hv))];
hist_xrange = [hist_xrange; zeros(size(hr))];
Param.Matrix = [Param.Matrix;ones(size(val))];

% Add in energy.
new_params = sqrt(sum([wv.*wv]'));
[hv, hr] = hist(new_params,150);
hist_vals = [hist_vals; hv];
hist_xrange = [hist_xrange; hr];
title_str{line_count} = 'Energy';
Param.Matrix = [Param.Matrix;ones(size(val))];
line_count = line_count + 1;
% Add in different points.
for pt = [6 8 10 12 15 17]
    new_params = wv(:,pt);
    [hv, hr] = hist(new_params,150);
    hist_vals = [hist_vals; hv];
    hist_xrange = [hist_xrange; hr];
    title_str{line_count} = ['Pt_' num2str(pt)];
    z = zeros(size(val));
    z(pt) = 1;
    Param.Matrix = [Param.Matrix; z];
    line_count = line_count + 1;
end
% Add in Dave's PCA.
load StdPC.mat
for ii = 1:32
    val = pc(:,ii)';
    new_params = val*wv';
    [hv, hr] = hist(new_params,150);
    hist_vals = [hist_vals; hv];
    hist_xrange = [hist_xrange; hr];
    title_str{line_count} = ['stdPCA_' num2str(ii)];
    Param.Matrix = [Param.Matrix;val];
    line_count = line_count + 1;
end
% Plot the parameters.
nhorz = 4; nvert=5;
n_per_page = nhorz*nvert;
plot_count = 0;
fig_count = 1;
figure
for ii = 1:(line_count-1)
    subplot(nvert,nhorz,plot_count+1)
    plot(hist_xrange(ii,:),hist_vals(ii,:))
    set(gca,'FontSize',8)
    
    axis tight
    axis off
    title(title_str{ii},'FontSize',8)
    plot_count = plot_count + 1;
    if mod(plot_count,n_per_page) ==0
        orient tall
        saveas(gcf,['Params' num2str(fig_count)],'png')
        fig_count = fig_count + 1;
        figure
        plot_count = 0;
    end
end
orient tall
saveas(gcf,['Params' num2str(fig_count)],'png')
fig_count = fig_count + 1;
% Plot out the Coefficients as well.
figure
plot_count = 0;
fig_count = 1;
for ii = 1:(line_count-1)
    subplot(nvert,nhorz,plot_count+1)
    plot(Param.Matrix(ii,:))
    set(gca,'FontSize',8)
    axis tight
    box off
    title(title_str{ii},'FontSize',8)
    plot_count = plot_count + 1;
    if mod(plot_count,n_per_page) ==0
        orient tall
        saveas(gcf,['Coefficients' num2str(fig_count)],'png')
        fig_count = fig_count + 1;
        figure
        plot_count = 0;
    end
end
% save the last figure.
orient tall
saveas(gcf,['Coefficients' num2str(fig_count)],'png')
fig_count = fig_count + 1;

figure
C = corrcoef(Param.Matrix');
C(find(C == 1)) = nan;
imagesc(1:Rows(C),1:Rows(C),C)
title('Correlation between parameters')
set(gca,'YTick',1:Rows(C))
set(gca,'YTickLabel',title_str)
set(gca,'XTickLabel',title_str)
set(gca,'FontSize',6)
orient tall
saveas(gcf,['ParamsCorrelations'],'png')
figure
%imagesc(Normalize_matrix(Param.Matrix')')
imagesc(Z_Scores(Param.Matrix')')
set(gca,'YTick',1:Rows(Param.Matrix))
set(gca,'YTickLabel',title_str)
set(gca,'FontSize',4)
xlabel('Points in waveform')
title('Parameter values (Z scores)')
orient tall
saveas(gcf,['Params'],'png')

figure
%waveform_density(wv)
saveas(gcf,['ParamsOriginalWaveform'],'png')
Param.C = C;
Param.Labels = title_str;
