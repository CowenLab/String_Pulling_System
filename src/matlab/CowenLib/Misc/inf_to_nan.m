function D = inf_to_nan(D)
D(find(isinf(D)))=nan;