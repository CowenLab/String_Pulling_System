function [mu] = Circ_mean_allcols(varargin)
% This is just a wrapper for circ_mean Behrens that works on columns.
%
% Cowen 2014
mu = zeros(Cols(varargin{1}),1)*nan;
if nargin == 1
    for ii = 1:Cols(varargin{1})
        m = varargin{1}(:,ii);
        m = m(~isnan(m));
        [mu(ii)] = circ_mean(m);
    end
elseif  nargin == 2
    for ii = 1:Cols(varargin{1})
        m = varargin{1}(:,ii);
        m = m(~isnan(m));
        [mu(ii)] = circ_mean(m, varargin{2});
    end
end
