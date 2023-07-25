function S = GaussPoissonNeurons(par)
%  Simulated Poisson Neurons with correlated Gaussian Clusters
%
%        S = GaussPoissonNeurons(par)
%
% Input:
%  paramter struct par with required fields:
%  par.StartEndTS   ...  row vector [t0,t1] with starttime and endtime
%                           of simulation interval (in NSMA 0.1 msec units)
%  par.CellRates  ...  nCells*1 or nCells*nBins array of firing rates (Spikes/sec) for each cell
%                           (if nBins = 1, a constant firing rate for each
%                           cell is assumed);
%                           Note: the number of output Neurons is
%                           determined from the length of the columns in par.CellRates;
%                           the number nBins of variable firing rates is
%                           determined from the length of the rows.
%  par.ClusterProcessFraction ... the mixture ratio between the pure poisson process component
%                           and the gaussian cluster process in range
%                           0 (= pure poisson) to 1 (= pure Gaussian Cluster process).
%  par.ClusterRate   ... the rate of the homogeneous poisson cluster center process (in
%                           cluster centers/sec)
%  par.ClusterWidthTime ... the width of each gaussian cluster in time
%                           direction (in sec units)
%  par.ClusterWidthCell ... the width (sigma) of each gaussin cluster in cell #
%                           direction (in # Cells) (Inf = cluster is
%                           uniformly distributed over all cells)
%
%
% Output:
%  S .... S-Matrix (cell array of ts objects ) of par.nCells simulated
%          spike trains in NSMA timestamp units (0.1 msec)
%
%
% requires Stats Toolbox
%
% Version 1.0
% PL July 1, 2005


[nCells,nBins] = size(par.CellRates);
T0 = par.StartEndTS(1);
T1 = par.StartEndTS(2);
binSizeSec = (T1-T0)/(10000*nBins);

% generate pure poisson component
Sp = {};        % S-Matrix for pure poissson component
if par.ClusterProcessFraction < 1
    avgN_poisson = par.CellRates*binSizeSec*(1-par.ClusterProcessFraction);
    nn = poissrnd(avgN_poisson);        % poissonian  # spikes in each bin
    nn(isnan(nn)) = 0;          % remove any NaNs that poissrnd may generate
    % fill each bin (ib) for each cell (ic)  with nn(ic,ib) uniformly distributed spikes
    Sp = cell(nCells,1);        % S-Matrix for pure poissson component
    for ic=1:nCells
        TS = cell(nBins,1);     % container of variable # of spikes in each bin
        for ib=1:nBins
            T = T0+(ib-1)*binSizeSec*10000;         % start timestamp of current bin
            TS{ib} = T + rand(nn(ic,ib),1)*binSizeSec*10000;
        end
        Sp{ic} = cat(1,TS{:});     % concatenate all spikes for current cell into nSpikes*1 column vector
    end
end


% generate gaussian cluster component
Sg = {};
if par.ClusterProcessFraction > 0
    % generate cluster centers with homogeneous poisson with rate
    % par.ClusterRate  [centers/sec]
    avgNC = par.ClusterRate*(T1-T0)/10000;         % avg # of cluster centers in epoch [T0,T1]
    NC = poissrnd(avgNC);                           % actual poissonian realization of # of clusters
    clusterBinSizeSec = (T1-T0)/(10000*NC);         % mean distance between clusters
    centersT = sort(T0 + rand(NC,1)*(T1-T0));             % timestamps of Nc uniformly distributed cluster centers
    centersC = 1+ floor(mod(rand(NC,1)*nCells,NC)); % uniform distribution of NC centers across cells

    % fill each gaussin cluster (ig) for each cell (ic) with appropriate number nG of
    % gaussian distributed spikes
    Sg = cell(nCells,1);        % S-Matrix for pure gaussian-cluster component
    if nBins > 1
        t = T0 + (0.5 + (0:nBins-1))*binSizeSec*10000;      % timestamp of each bin center
    end
    for ic=1:nCells
        TS = cell(NC,1);        % container of variable # of spikes in each cluster
        if nBins > 1
            ratesAtCenters = interp1(t,par.CellRates(ic,:),centersT) * par.ClusterProcessFraction;  % variable rates at each cluster center
            ratesAtCenters(isnan(ratesAtCenters)) = 0;  % replace NaNs with 0 if interp1 returns a NaN (don't know why - seems like a bug in interp1)
        else
            ratesAtCenters = par.CellRates(ic)*ones(1,NC) *  par.ClusterProcessFraction;            % constant rate at each cluster center
        end
        for ig = 1:NC   % loop over clusters
            if par.ClusterWidthCell > nCells
                clusterWeight = 1;
            else
                clusterWeight = diff(normcdf([ic-0.5,ic+0.5],centersC(ig),par.ClusterWidthCell))*nCells;  % weight = gaussProb/uniformProb
            end
            avgNg  = ratesAtCenters(ig) * clusterWeight * clusterBinSizeSec; % avg Cluster multiplicty (avg # Spikes in current clusters
            Ng = poissrnd(avgNg);       % piosson realization of avg Cluster multiplicity
            TS{ig} = centersT(ig) + randn(Ng,1)*par.ClusterWidthTime*10000;
        end
        Sg{ic} = cat(1,TS{:});
    end

end

% join pure poisson and gauss-cluster components
if isempty(Sp)
    S = Sg;
end
if isempty(Sg)
    S = Sp;
end
if ~isempty(Sp) & ~isempty(Sg)
    for i=1:nCells
        S{i} = sort([Sp{i};Sg{i}]);
    end
end

% convert TS vectors to ts-objects
for i=1:length(S)
    S{i} = ts(S{i});
end
