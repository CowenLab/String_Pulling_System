function [SI] = Synchrony_index(TbN)
% TbN = a Time(row) by neuron (col) matrix. You choose the binsize.
% see Mizuseki, K., Buzsaki, G., 2014. Theta oscillations decrease spike synchrony in the hippocampus and entorhinal cortex. Philos. Trans. R. Soc. B Biol. Sci. 369. https://doi.org/10.1098/rstb.2012.0530
% https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3866449/
% do all cell pairs.
% Look into doing this with suffle.

%%
cnt = 1;
SI = [];
for ii = 1:(Cols(TbN)-1)
    for jj = (ii+1):Cols(TbN)
        % [ii  jj]
        SumCnts = TbN(:,ii) + TbN(:,jj);
        ctr = SumCnts(2:end-1);
        left = SumCnts(1:end-2);
        right = SumCnts(3:end);
        mnlr = (left + right)/2;
        SI(cnt,:) = (ctr-mnlr)./(ctr + mnlr);
        
        pairID(cnt,:) = [ii,jj];
        
        cnt = cnt + 1;
    end
end