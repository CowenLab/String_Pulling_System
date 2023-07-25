function en = e_norm(M)
% energy normalizes by the energy of each column
en = M./repmat(sqrt(nansum(M.*M)),size(M,1),1);
