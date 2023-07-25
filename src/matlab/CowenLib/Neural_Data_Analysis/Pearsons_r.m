function [Pr] = Pearsons_r(IN, dt_msec);
% INPUT
%  IN could be a nxcell matrix or a cell array of ts objects or a tsl object.
%  bin size in msec for the xcorr if  a cell array is passed in.
% 
% OUTPUT
%  A cellxcell matrix with the upper diagonal set to nan since it is symmetric.
% 
% 
%  cowen
if nargin < 2
    dt_msec = [];
end

if iscell(IN)
    IN = Data(MakeQfromS(IN,dt_msec*10));
elseif isa(IN,'tsl')
    IN = Qmatrix(IN,dt_msec);
end

badidx = find(triu(ones(Cols(IN)))==1);
Pr = corrcoef(IN);
Pr(badidx) = nan;
