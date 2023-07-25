function [NB] = netBurstDetection(BDTrain, IBeImax, flags, IBeIThDef, sf, numElecTh)
% netBurstDetection.m
% by Valentina Pasquale - Italian Institute of Technology, March 2008
% %%
% Network burst detection: it detects network bursts on a cumulative burst train.
% %%
% ARGUMENTS:
% %%
% BDTrain:      matrix (size number_of_bursts x 3), containing data about each burst
%               recorded by a single channel:
%                   1st col: channel number
%                   2nd col: burst begin ([sample])
%                   3rd col: burst end([sample]);
% IBeImax:      value of IBeI that optimally separates intra-network burst IBeIs and
%               out-network burst IBeIs (scalar), as computed by calcIBeImax.m (ms);   
% flags:        vector of flags (size 1x2), as computed by calcIBeImax.m;
% IBeIThDef:    default value for IBeImax (ms);   
% sf:           sampling frequency (samples per second);
% numElecTh:    minimum number of channels involved in a nework burst.
% %%
% RESULTS:
% %%
% NB:           matrix (size number_of_network_bursts x 5) containing the following
%               data:
%               1st col: time instant in which the network burst begins (samples)
%               2nd col: time instant in which the network burst ends (samples)
%               3rd col: number of single-channel bursts in each network burst
%               4th col: duration (samples)
%               5th col: number of channels involved in each network burst.
% %%
% See also: V. Pasquale, S. Martinoia, M. Chiappalone "A self-adapting approach for the detection of bursts
% and network bursts in neuronal cultures", J. Comput. Neurosci., DOI
% 10.1007/s10827-009-0175-1.
%% initialize outputs
NB = [];
%% check inputs
if size(BDTrain,2)~=3
    error('The first argument must be a N-by-3 matrix.')
end
if ~isscalar(IBeImax) || IBeImax <= 0
    error('The second argument must be a positive scalar.')
end
if ~all(size(flags) == [1,2]) || any(flags < 0)
    error('The third argument must be a vector of size (1,2) of positive values.')
end
if ~isscalar(IBeIThDef) || IBeIThDef <= 0
    error('The fourth argument must be a positive scalar.')
end
if ~(isscalar(sf) && ~(mod(sf,1))) || sf <= 0
    error('The sixth argument must be a positive scalar integer.')
end
if ~(isscalar(numElecTh) && ~(mod(numElecTh,1))) || numElecTh <= 0
    error('The seventh argument must be a positive scalar integer.')
end
%% computation
% sorting bursts in chronological order
if (~isempty(BDTrain))
    BDTrainSorted = sortrows(BDTrain,2);
    tsBE = BDTrainSorted(:,2);
    % %%%%%%%
    if flags(1,2)
        IBeImax_sample = round(IBeImax/1000*sf);
    else
        IBeImax_sample = round(IBeIThDef/1000*sf);
    end
    % %%%%%%%%%%%%
    NBtrn = [0; diff(tsBE)<=IBeImax_sample; 0];
    NBedges = diff(NBtrn);
    NBFirstBurst = find(NBedges == 1);
    NBLastBurst = find(NBedges == -1);
    numNB = length(NBFirstBurst);
    numActElec = zeros(numNB,1);
    for i = 1:numNB
        % list of bursting electrodes (in the i-th NB)
        actElec = unique(BDTrainSorted(NBFirstBurst(i):NBLastBurst(i),1));
        % counts number of active electrodes
        numActElec(i) = length(actElec);
    end
    NB2save = numActElec>=numElecTh;
    newNBFirstBurst = NBFirstBurst(NB2save);
    newNBLastBurst = NBLastBurst(NB2save);
    newNumNB = length(newNBFirstBurst);
    newNumActElec = numActElec(NB2save);
    NB = zeros(newNumNB,5);
    for jj = 1:newNumNB
        burstBegin = BDTrainSorted(newNBFirstBurst(jj),2);
        burstEnd = max(BDTrainSorted(newNBFirstBurst(jj):newNBLastBurst(jj),3));
        if jj ~= newNumNB
            succBurstBegin = BDTrainSorted(newNBFirstBurst(jj+1),2);
            if burstEnd >= succBurstBegin
                burstEnd = succBurstBegin-1;
            end
        end
        NB(jj,1:4) = [burstBegin, ... % ts of the begin of the first burst [samples]
            burstEnd, ...  % ts of the end of the longest burst [samples]
            newNBLastBurst(jj)-newNBFirstBurst(jj)+1,...        % number of bursts
            burstEnd-burstBegin]; % duration [samples]
        NB(jj,5) = newNumActElec(jj);
    end
end