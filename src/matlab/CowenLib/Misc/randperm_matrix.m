function O = randperm_matrix(sz,nreps)
% Does randperm but for rows.
% Cowen 2019
O = cell2mat(arrayfun(@randperm,ones(nreps,1)*sz,'UniformOutput',false));
