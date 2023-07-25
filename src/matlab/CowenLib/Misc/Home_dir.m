function p = Home_dir()
% Return the source directory for the matlab code for COWEN
p = which('plot_average_PETHs.m');
p = strrep(p,'\Working\Visualizing_data\plot_average_PETHs.m','');
p = strrep(p,'/Working/Visualizing_data/plot_average_PETHs.m','');

if ~exist(p,'dir')
    error([mfilename ': Could not find directory. ' p ])
end
