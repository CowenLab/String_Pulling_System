function [M, h, edges] = Plot_spike_by_time_matrix(T, bin_size, varargin)
%% Cowen 2023

time_divisor = 1;
xlab = 'time (?)';

Extract_varargin;


[M, edges] = histcounts_cowen(T, 'binsize', bin_size);
x = edges(1:end-1) + (edges(2)-edges(1))/2;
x = x/time_divisor;

figure
h=imagesc(x,[],M');
colormap(1-gray);
ylabel('Neuron ID')
xlabel(xlab)
pubify_figure_axis