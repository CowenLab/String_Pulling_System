function [SS,CHI] = Sequence_strength(spk_nid_ctr, P)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: nspk by (spk time, position (iD), cycleID, neuronID) matrix
% Assumes times are in u_sec
% If all cycle ids are identical, then it does it for everything.
%
% OUTPUT:
%
% Gupta, A.S., Van Der Meer, M.A.A., Touretzky, D.S., Redish, A.D., 2012. Segmentation of spatial experience by hippocampal theta sequences. Nat. Neurosci. 15, 1032–1039. https://doi.org/10.1038/nn.3138
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4
    P.min_interval_ms = 80;
    P.min_spikes = 4;
    P.min_neurons = 3;
%     P.dist_thresh = 50;
end
SS = []; CHI = [];
nSpk = Rows(spk_nid_ctr);
% NEEDS TO BE SORTED BY NEURON FIRST!!!
spk_nid_ctr = sortrows(spk_nid_ctr,[2 1]);

nNeurons = length(unique(spk_nid_ctr(:,2)));

if nNeurons < P.min_neurons || nSpk < P.min_spikes
    return
end

TMP = repmat(spk_nid_ctr(:,2),1,nSpk);
otherNID = TMP - TMP';
otherNID(otherNID~=0) = true;
otherNID(otherNID==0) = nan;
TRIU = triu(otherNID,0);
TRIU(TRIU == 0) = nan;
otherNID = otherNID.*TRIU;

% Time difference in spiking.
% I think I need to just take the upper or lower diagonal as well as this
% approach forces symmetry.
TMP = repmat(spk_nid_ctr(:,1),1,nSpk);
dT = TMP - TMP';
dT = dT.*otherNID;
dT(abs(dT) > P.min_interval_ms) = nan;

% figure
% histogram(dT(:))

S = dT;
S(dT > 0) = 1;
S(dT < 0) = -1;
S(dT == 0) = nan;
Sv = S(~isnan(S));
% distance in terms of PF center.
TMP = repmat(spk_nid_ctr(:,3),1,nSpk);
dD = TMP - TMP';
[CHI.p, CHI.chi2, CHI.df, CHI.CramerV] = chi2_test([sum(Sv == -1) sum(Sv == 1)], [length(Sv)/2 length(Sv)/2]);
SS.prop = sum(Sv == 1)/(sum(Sv == 1) + sum(Sv == -1));
SS.mean = mean(Sv);
SS.SE = Sem(Sv);
if nargout == 0
    subplot(1,2,1)
    bar([sum(Sv == -1) sum(Sv == 1)] )
    set(gca,'XTickLabel',{'rev' 'fow'})
    subplot(1,2,2)
    histogram(dT(:))
    plot_vert_line_at_zero
    xlabel('ms')
    axis tight
end
