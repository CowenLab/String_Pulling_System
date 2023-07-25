function [burstTrain, burstEventTrain] = burstDetectionPasquale_cowenmod(timestamp, ...
    ISImax, flags, ISImaxTh, maxISImaxTh, sf, minNumSpikes)
% burstDetection.m
% by Valentina Pasquale - Italian Institute of Technology, March 2008
% %%
% Burst detection: it detects bursts on a single spike train.
% %%
% ARGUMENTS:
% %%
% peakTrain:   UPDATE: now a vector of timestamps _MS. sparse array ([number of samples x 1]), containing 1
%               when a spike is present, 0 elsewhere;
% ISImax:       value of ISI that optimally separates intra-burst ISIs and
%               out-burst ISIs (scalar), as computed by calcISImax.m;
% flags:        vector of flags (size 1x2), as computed by calcISImax.m;
% ISImaxTh:     value of ISI in ms (e.g. 100 ms) that determines whether the
%               burst detection uses one (only ISImax) or two thresholds 
%               (the first one for the burst core - ISImaxTh - 
%               and the second one for extending the burst core at the 
%               boundaries - ISImax);
% maxISImax:    maximum value allowed for ISImax (in ms); if ISImax >
%               maxISImax, then ISImaxTh is used for burst detection;
% sf:           sampling frequency (samples per second);
% minNumSpikes: minimum number of spikes in a burst.
% %%
% RESULTS:
% %%
% burstTrain:   matrix (size number_of_bursts x 6) containing the following data:
%               1st col: time instant in which the burst begins (samples)
%               2nd col: time instant in which the burst ends (samples)
%               3rd col: number of spikes in each burst
%               4th col: duration (seconds)
%               5th col: inter-burst interval (between the end of the burst
%               and the begin of the following one) (seconds)
%               6th col: burst period (time interval between the begin of the burst
%               and the begin of the following one) (seconds)
% burstEventTrain:  sparse array ([number of samples x 1]), containing 1
%                   when a burst begins (time instant of the first spike of
%                   each burst), 0 elsewhere;
% %%
% See also: V. Pasquale, S. Martinoia, M. Chiappalone "A self-adapting approach for the detection of bursts
% and network bursts in neuronal cultures", J. Comput. Neurosci., DOI
% 10.1007/s10827-009-0175-1.
%% initialize variables
burstTrain = [];
burstEventTrain = [];
%% check inputs

if ~isscalar(ISImax) || ISImax <= 0
    error('The second argument must be a positive scalar.')
end
if ~all(size(flags) == [1,2]) || any(flags < 0)
    error('The third argument must be a vector of size (1,2) of positive values.')
end
if ~isscalar(ISImaxTh) || ISImaxTh <= 0
    error('The fourth argument must be a positive scalar.')
end
if ~isscalar(maxISImaxTh) || maxISImaxTh <= 0
    error('The fifth argument must be a positive scalar.')
end
if ~(isscalar(sf) && ~(mod(sf,1))) || sf <= 0
    error('The sixth argument must be a positive scalar integer.')
end
if ~(isscalar(minNumSpikes) && ~(mod(minNumSpikes,1))) || minNumSpikes <= 0
    error('The seventh argument must be a positive scalar integer.')
end
%% computation
if flags(2) && ISImax < maxISImaxTh     % ISImax exists && ISImax < 1 s
    if ISImax > ISImaxTh                % ISImax < 100 ms
        ISImaxsample = round(ISImaxTh/1000*sf);          % threshold for ISImax [sample]
        addWinsample = round(ISImax/1000*sf);
        amplFlag = 1;
    else                                % ISImax < 100 ms
        ISImaxsample = round(ISImax/1000*sf);          % threshold for ISImax [sample]
        amplFlag = 0;
    end
else
    ISImaxsample = round(ISImaxTh/1000*sf);          % threshold for ISImax [sample]
    amplFlag = 0;
end
% indices of nonzero elements --> corrisponde al numero del sample nel
% peak_train
% timestamp = find(peakTrain);
if ~isempty(timestamp)
    allisi2 = [0;diff(timestamp) <= ISImaxsample;0];      % ISI <= ISImax [samples]
    edges2 = diff(allisi2);                                % edges of bursts: beginning & ending
    % edgeup & edgedown contain the indexes of timestamps that correspond to
    % beginning of bursts and to end of bursts respectively
    edgeup2 = find(edges2 == 1);
    edgedown2 = find(edges2 == -1);
    if ((length(edgedown2)>=2) && (length(edgeup2)>=2))    % if there are at least 2 bursts
        numSpikesInBurst = (edgedown2-edgeup2+1);
        validBursts = numSpikesInBurst >= minNumSpikes;
        % if there is at least one VALID burst
        if ~isempty(validBursts)
            edgeup2 = edgeup2(validBursts);
            edgedown2 = edgedown2(validBursts);
            if amplFlag
                tsEdgeup2 = timestamp(edgeup2);
                tsEdgedown2 = timestamp(edgedown2);
                tempIBI = tsEdgeup2(2:end)-tsEdgedown2(1:end-1);
                burst2join = tempIBI<=addWinsample;
                if any(burst2join)
                    edgeup2(find(burst2join)+1)=[];
                    edgedown2(burst2join)=[];
                end
                % %%%
                allisi1 = [0;diff(timestamp)<=addWinsample;0];   % ISI <= ISImax [samples]
                edges1 = diff(allisi1);                          % edges of bursts: beginning & ending
                % edgeup & edgedown contain the indexes of timestamps that correspond to
                % beginning of bursts and to end of bursts respectively
                edgeup1 = find(edges1 == 1);
                edgedown1 = find(edges1 == -1);
                % %%%%%%
                allEdgeUp1 = [timestamp(edgeup1) ones(length(edgeup1),1) 1*ones(length(edgeup1),1)];
                allEdgeDown1 = [timestamp(edgedown1) -1*ones(length(edgedown1),1) 1*ones(length(edgeup1),1)];
                allEdge1 = [allEdgeUp1;allEdgeDown1];
                % %%%%%%
                allEdgeUp2 = [timestamp(edgeup2) ones(length(edgeup2),1) 2*ones(length(edgeup2),1)];
                allEdgeDown2 = [timestamp(edgedown2) -1*ones(length(edgedown2),1) 2*ones(length(edgeup2),1)];
                allEdge2 = [allEdgeUp2;allEdgeDown2];
                % %%%%%%
                allEdge = [allEdge1; allEdge2];
                allEdgeSort = sortrows(allEdge,1);
                % [timestamp    type of edge    burst train]
                % type of edge: 1 rise, -1 fall
                % burst train: 1 large ISI th, 2 strict ISI th
                % look for rise edge of large ISIth
                burstBegin = find(allEdgeSort(:,2)==1 & allEdgeSort(:,3)==1);
                b = 0;
                newBurstDetection = [];
                for ii = 1:length(burstBegin)
                    % if the following edge is -1,1 --> fall of large ISIth
                    % no burst is detected
                    if (allEdgeSort(burstBegin(ii)+1,2)==-1 && allEdgeSort(burstBegin(ii)+1,3)==1)
                        continue
                    else
                        % look for fall edge of large ISIth
                        thisBurstEnd = find(allEdgeSort(burstBegin(ii):end,2)==-1 & allEdgeSort(burstBegin(ii):end,3)==1,1);
                        thisBurstEnd = thisBurstEnd+burstBegin(ii)-1;
                        % look for rise edge of strict ISIth
                        subBurstBegin = find(allEdgeSort(burstBegin(ii):thisBurstEnd,2)==1 & allEdgeSort(burstBegin(ii):thisBurstEnd,3)==2);
                        subBurstBegin = subBurstBegin+burstBegin(ii)-1;
                        % if there's more than one
                        if length(subBurstBegin)>1
                            subBurstBegin = [burstBegin(ii);subBurstBegin(2:end)];
                            subBurstEnd = [subBurstBegin(2:end);thisBurstEnd];
                            for jj = 1:length(subBurstBegin)
                                b = b+1;
                                timestampBegin = allEdgeSort(subBurstBegin(jj),1);
                                tempTimestampEnd = allEdgeSort(subBurstEnd(jj),1);
                                if jj ~= length(subBurstBegin)
                                    spks = Restrict(timestamps,timestampBegin, tempTimestampEnd-1);
                                else
                                    spks = Restrict(timestamps,timestampBegin, tempTimestampEnd);
                                end
                                timestampEnd = timestampBegin+spks(end)-1;
                                numSpikesThisBurst = length(spks);
                                duration_s = (timestampEnd-timestampBegin)./sf;
                                newBurstDetection(b,:) = [timestampBegin timestampEnd numSpikesThisBurst duration_s];
                            end
                        else
                            b = b+1;
                            timestampBegin = allEdgeSort(burstBegin(ii),1);
                            timestampEnd = allEdgeSort(thisBurstEnd,1);
%                             numSpikesThisBurst = sum(spones(peakTrain(timestampBegin:timestampEnd)));
                            numSpikesThisBurst = length(Restrict(timestamps,timestampBegin, timestampEnd));
                            duration_s = (timestampEnd-timestampBegin)./sf;
                            newBurstDetection(b,:) = [timestampBegin timestampEnd numSpikesThisBurst duration_s];
                        end
                    end
                end
            else
                % timestamps of edges (up&down)
                tsEdgeup2 = timestamp(edgeup2);
                tsEdgedown2 = timestamp(edgedown2);
                newBurstDetection = [tsEdgeup2, tsEdgedown2, (edgedown2-edgeup2+1), ...
                    (tsEdgedown2-tsEdgeup2)/sf];
            end
            if ~isempty(newBurstDetection)
                % INSIDE BURST Parameters
                binit = newBurstDetection(:,1);     % Burst init [samples]
                % put 1 in the timestamp of the first spike of each
                % burst
                burstEventTrain = sparse(binit, ones(length(binit),1), 1); % Burst event
                bp = [diff(binit)/sf; 0];     % Burst Period [sec] - start-to-start
                ibi = [((newBurstDetection(2:end,1)- newBurstDetection(1:end-1,2))/sf); 0]; % Inter Burst Interval, IBI [sec] - end-to-start
                burstTrain = [newBurstDetection, ibi, bp];
                % burstTrain = [init, end, nspikes, duration, ibi, bp]
            end
        end
    end
end