function [tc tce Occ svg] = tuning_curves(vbin_se,v,s);
%function [tc tce Occ] = tuning_curves(vbinse,v,s);
% Stephen's version of a one dimensional tuning curve.
% Pass in the start and end bins of the environmental parameter v (eg.
% position) and a vector of position associated with each row in spiking
% activity (s). 
%
% Returens a tuning curve and error estimate (SEM).
% 
% cowen
nCells = size(s,2);
nBins = size(vbin_se,1);
tc = zeros(nBins,nCells)*nan;
tce = zeros(nBins,nCells)*nan;

for iBin = 1:nBins
    ix = find(v >= vbin_se(iBin,1) & v < vbin_se(iBin,2));
    Occ(iBin) = length(ix);
    if ~isempty(ix)
        % cc(iBin) = sum(TA.D1.SpikeRate{iSeq}(ix,iCell))
        tc(iBin,:)  = mean(s(ix,:));
        tce(iBin,:) = Sem(s(ix,:));
        % cs(iBin) = std(TA.D1.SpikeRate{iSeq}(ix,iCell))
    else
        %cb{iBin} = [];
        tc(iBin,:) = nan;
        tce(iBin,:) = nan;
    end
end

if nargout > 3
    % Group data.
    svg = [];
    for iBin = 1:nBins
        ix = find(v >= vbin_se(iBin,1) & v < vbin_se(iBin,2));
        if ~isempty(ix)
            % cc(iBin) = sum(TA.D1.SpikeRate{iSeq}(ix,iCell))
            svg  = [svg; s(ix,:) v(ix,:) repmat(iBin,length(ix),1)];
            % cs(iBin) = std(TA.D1.SpikeRate{iSeq}(ix,iCell))
        end
    end
end

if nargout == 0
     for iCell = 1:nCells

         subplot(1,2,1)
         errorbar(mean(vbin_se,2),tc(:,iCell),tce(:,iCell))
         axis tight
         subplot(1,2,2)
         plot(mean(vbin_se,2),Occ)
         title('Occupancy')
         axis tight
     end
end
  