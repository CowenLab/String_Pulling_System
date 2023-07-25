function [C,ALL] = Sequence_strength_by_cycle(spk_pos_cycleID_nrnID, x_edges, smooth_factor, P)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: nspk by (spk time, position (iD), cycleID, neuronID) matrix
% Assumes times are in u_sec
% If all cycle ids are identical, then it does it for everything.
%
% OUTPUT:
%
% Gupta, A.S., Van Der Meer, M.A.A., Touretzky, D.S., Redish, A.D., 2012.
% Segmentation of spatial experience by hippocampal theta sequences. Nat.
% Neurosci. 15, 1032–1039. https://doi.org/10.1038/nn.3138
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(diff(spk_pos_cycleID_nrnID(:,3))<0)
    error('Cycles must be ascending')
end

if nargin < 4
    P.min_interval_ms = 80;
    P.min_spikes = 4;
    P.min_neurons = 3;   
    P.dist_thresh = [];
end
NID = unique(spk_pos_cycleID_nrnID(:,4));
ALL = [];
C = [];
% Convert to msec as that's easier to think about...
spk_pos_cycleID_nrnID(:,1) = spk_pos_cycleID_nrnID(:,1)/1e3;
% Do an initial filter and get rid of cells that don't fire enough...
for ii = 1:length(NID)
    GIX = spk_pos_cycleID_nrnID(:,4) == NID(ii);
    if sum(GIX) < P.min_spikes
        spk_pos_cycleID_nrnID(GIX,4) = [];
        continue
    end
end
% now that this is out of the way...
NID = unique(spk_pos_cycleID_nrnID(:,4));
nSpk = Rows(spk_pos_cycleID_nrnID);

% Create place fields.
cnt = 1;
H = nan(length(x_edges)-1,length(NID));
for ii = 1:length(NID)
    GIX = spk_pos_cycleID_nrnID(:,4) == NID(ii);
    H(:,cnt) = histcounts(spk_pos_cycleID_nrnID(GIX,2), x_edges);
    cnt = cnt + 1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine peak centers.
han = hanning(smooth_factor)/sum(hanning(smooth_factor));
Hs = convn(H,han,'same');
[~,pk_ix] = max(Hs);
ctr_locs = x_edges(pk_ix);
[~,six] = sort(ctr_locs);
ranks = 1:length(ctr_locs);
ranks(six) = ranks;
% assign the center to each cell...
for ii = 1:length(NID)
    GIX = spk_pos_cycleID_nrnID(:,4) == NID(ii);
    spk_pos_cycleID_nrnID(GIX,5) = ranks(ii); % order
    spk_pos_cycleID_nrnID(GIX,6) = ctr_locs(ii); % center location.
end
[SS,CHI] = Sequence_strength(spk_pos_cycleID_nrnID(:,[1 4 6]),P);% time, neuronID, ctrID
if isempty(SS)
    return
end

ALL.mean = SS.mean;
ALL.SE = SS.SE;
ALL.prop = SS.prop;
ALL.p = CHI.p;
ALL.CramerV = CHI.CramerV;
% determine number of spikes and number of cells per cycle.
count_neurons = @(x) length(unique(x));

[spks,n_neurons] = grpstats(spk_pos_cycleID_nrnID(:,4),spk_pos_cycleID_nrnID(:,3),{'length' count_neurons});
[CycID] = grpstats(spk_pos_cycleID_nrnID(:,3),spk_pos_cycleID_nrnID(:,3),{'mean'});
GIX = spks >= P.min_spikes & n_neurons >= P.min_neurons;
good_cycles = CycID(GIX);
% find cycle times.
% sadly binsearch_vector can sometimes crash
% disp('1')
% ix = binsearch_vector_alt(spk_pos_cycleID_nrnID(:,3),good_cycles);
ix = binsearch_vector(spk_pos_cycleID_nrnID(:,3),good_cycles);
good_times = spk_pos_cycleID_nrnID(ix,1);
% disp('2')

C.t_usec = good_times;
C.cycle = good_cycles;
C.mean = nan(length(good_cycles),1);
C.SE = nan(length(good_cycles),1);
C.prop = nan(length(good_cycles),1);
C.p = nan(length(good_cycles),1);
C.CramerV = nan(length(good_cycles),1);
C.n_neurons = n_neurons(GIX);
C.n_spikes = spks(GIX);

for iC = 1:length(good_cycles)
    IX = spk_pos_cycleID_nrnID(:,3) == good_cycles(iC);
    %     spk_pos_cycleID_nrnID
    [SS,CHI] = Sequence_strength(spk_pos_cycleID_nrnID(IX,[1 4 6]),P);% time, neuronID, ctrID
    C.mean(iC) = SS.mean;
    C.SE(iC) = SS.SE;
    C.prop(iC)= SS.prop;
    C.p(iC) = CHI.p;
    C.CramerV(iC)= CHI.CramerV;
end

