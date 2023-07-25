function new_w = Respline_cowen(w, n_samples)
%function new_w = Respline_cowen(w, n_samples)
% FAST SPLINE
% Taken and modified from Kleinfeld UltraMegaSort - modded by Cowen
% generate values around new alignment point using spline interpolation
% Fast interpolation.
%   num_spikes = size(w,1);
%   num_samples = size(w,2);
% up or downsamples the original sampling from the cols in w to n_samples
% points.
%
% NOTE - it seems to generate strange and non-existent troughs in the data.
%   - it's proabably fine for identifying half-width and peak-to-trough,
%   but may be sketchy for other measures.
%
if nargin == 0 % Sample for testing
    n_samples = 10000;
    w = [1 2 1 1 2 4 5 19 22 40 22 18 12 2 -10 -12 -12 -13 -9 10 1 2 1 1 1 1 2 3 4 2 ]
    w = [w;w;w;w]
    %new_inds = 1:1000;
    old_inds = 1:size(w,2);
end
new_inds = linspace(1,size(w,2),n_samples);


num_spikes = size(w,1);
num_samples = size(w,2);

pp = spline(1:num_samples, w);
%pp.order = 3; Cant change this - gets really funky.
% the efficient way to call spline is on a single vector rather than
% on a stack.  so we are going to concatenate all the waveforms together
% with zeros in between
pp.coefs = reshape(pp.coefs, num_spikes, num_samples-1, []);
pp.coefs = permute(pp.coefs, [2 1 3]);
padzeros = zeros(1,num_spikes, 4);
pp.coefs = cat(1, pp.coefs, padzeros);
pp.coefs(num_samples,:,4) = w(:,end)';
pp.coefs = reshape(pp.coefs, [], 4);
pp.pieces = num_spikes*num_samples;
pp.dim = 1;
pp.breaks = [1:(pp.pieces+1)];

% evaluate spline at the locations of the new waveforms
new_w = ppval(pp, new_inds);

if nargin == 0
    figure
    plot(old_inds,w(1,:),new_inds,new_w(1,:))
end