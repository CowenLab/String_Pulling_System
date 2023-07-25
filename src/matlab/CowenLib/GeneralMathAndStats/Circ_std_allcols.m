function [s, s0] = Circ_std_allcols(varargin)
% This is just a wrapper for circ_std Behrens that works on columns.
%
% Cowen 2014
s = zeros(Cols(varargin{1}),1)*nan;
s0 = zeros(Cols(varargin{1}),1)*nan;
if nargin == 1
    for ii = 1:Cols(varargin{1})
        m = varargin{1}(:,ii);
        m = m(~isnan(m));
        if length(m) > 2
            [s(ii),s0(ii)] = circ_std(m);
        end
    end
elseif  nargin == 2
    for ii = 1:Cols(varargin{1})
        m = varargin{1}(:,ii);
        m = m(~isnan(m));
        if length(m) > 2
            [s(ii),s0(ii)] = circ_std(m, varargin{2});
        end
    end
elseif  nargin == 3
    for ii = 1:Cols(varargin{1})
        m = varargin{1}(:,ii);
        m = m(~isnan(m));
        if length(m) > 2
            [s(ii),s0(ii)] = circ_std(m, varargin{2},  varargin{3});
        end
    end
end