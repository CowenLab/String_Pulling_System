function ranks = Rank_order(M)
[~,six] = sort(M);
ranks = 1:length(M);
ranks(six) = ranks;