function O = Partial_r(I, boot)
%function O = Partial_r(I, boot)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
%   a nx3 or nx5 matrix where n is the number of observations and each column 
%   corresponds to the variable (i.e. S1, M1, S3).
% OUTPUT:
%   O = [rAB_C, rBC_A, rAC_B, rAB, rBC, rAC]
%    *NOTE* I do it this way to make it easy to use bootstrp on this function.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 1
    boot = 0;
end

good_idx = find(~isnan(sum(I')));
%if good_idx < size(I,1)
%warning('Nans in input matrix. Removed from analysis')
%end

I = I(good_idx,:);
if isempty(I)
    warning('No usable data');
    O = zeros(1,6)*nan;
    return
end


if size(I,2) ~= 3 & size(I,2) ~= 5 & size(I,1) ~= 1
    error('Must have 3 or 5 columns and at least one row in input.')
end

n_to_boot_by_r = 400;
rAE = [];
rDE = [];
if boot
    tmp = bootstrp(n_to_boot_by_r,'corrcoef',I(:,1),I(:,2));
    rAB = median(tmp(:,2));
    tmp = bootstrp(n_to_boot_by_r,'corrcoef',I(:,2),I(:,3));
    rBC = median(tmp(:,2));
    tmp = bootstrp(n_to_boot_by_r,'corrcoef',I(:,1),I(:,3));
    rAC = median(tmp(:,2));
    if size(I,2) == 5
        tmp = bootstrp(n_to_boot_by_r,'corrcoef',I(:,1),I(:,4));
        rAD = median(tmp(:,2));
        tmp = bootstrp(n_to_boot_by_r,'corrcoef',I(:,1),I(:,5));
        rAE = median(tmp(:,2));
        tmp = bootstrp(n_to_boot_by_r,'corrcoef',I(:,4),I(:,5));
        rDE = median(tmp(:,2));
    end
else 
    tmp = corrcoef(I(:,1),I(:,2));
    rAB = tmp(1,2);
    tmp = corrcoef(I(:,2),I(:,3));
    rBC = tmp(1,2);
    tmp = corrcoef(I(:,1),I(:,3));
    rAC = tmp(1,2);
    if size(I,2) == 5
        tmp = corrcoef(I(:,1),I(:,4));
        rAD = tmp(1,2);
        tmp = corrcoef(I(:,1),I(:,5));
        rAE = tmp(1,2);
        tmp = corrcoef(I(:,4),I(:,5));
        rDE = tmp(1,2);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% partial correlation coeff (r) of B_C|A, r^2 is the explained variance.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rBC_A = (rBC - rAB.*rAC) ./ sqrt((1 - rAB.^2).* (1 - rAC.^2));
rAB_C = (rAB - rAC.*rBC) ./ sqrt((1 - rBC.^2).* (1 - rAC.^2));
rAC_B = (rAC - rBC.*rAB) ./ sqrt((1 - rAB.^2).* (1 - rBC.^2));

if size(I,2) == 3
    O = [rAB_C, rBC_A, rAC_B, rAB, rBC, rAC];
else
    rAD_E = (rAD - rAE.*rDE) ./ sqrt((1 - rAE.^2).* (1 - rDE.^2));
    rDE_A = (rDE - rAD.*rAE) ./ sqrt((1 - rAD.^2).* (1 - rAE.^2));
    O = [rAB_C, rBC_A, rAC_B, rAD_E, rDE_A, rAB, rBC, rAC, rAD, rDE, rAE];
end

