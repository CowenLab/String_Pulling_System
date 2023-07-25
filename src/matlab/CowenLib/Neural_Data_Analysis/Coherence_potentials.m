function [CP, ID] = Coherence_potentials(LFP, sFreq, thresh_SD)
%function [CP, ID] = Coherence_potentials(LFP, sFreq, thresh_SD)
%
% INPUT: A matrix of LFP data with each column being a separate channel
%        thresh_SD is the threshold in standard deviations of the CP.
% OUTPUT: indices in the LFP data where a CP occured and an id for this
%         particular CP (it's cluster)
%         the CPs
%
% See Plenz 2010 paper for the methods.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen (2010)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Presumes sampling frequency of 500.
method = 'fixed_window'; % The method by which we define a CP.
CP = [];
ix_id = [];

time_before_msec = 100;
time_after_msec = 200;

nBefore = round(time_before_msec*sFreq/1000); % MAX number of points before the peak to include in the template
nAfter = round(time_after_msec*sFreq/1000);  % MAX number of points after the peak to include in the template
nWavePts = nBefore + nAfter + 1;

LFP = Z_Scores(LFP); % Convert to Z.

% Negative is typically up in my NLX data.

% First step, find the potential target CPs on each channel by identifying
% threshold crossings and moving back to zero crossings. These will serve
% as templates for identifying similar CPs on other channels.

for iThreshCh = 1:Cols(LFP)
    CP{iThreshCh} = [];
    PIX = zeros(Rows(LFP),1);
    % Find peaks
    de = [0; diff(LFP(:,iThreshCh)); 0];   % backward derivative
    PIX(de(1:(end-1)) > 0 & de(2:end) < 0 & LFP(:,iThreshCh) > thresh_SD) = 1; % Peak IX
    % Go to each peak and move until it goes to baseline.
    % Take some points around the peak and start clustering...
    %%%%%%%%%%%%%%%%%%%%
    % Get ride of stuff at edges.
    %%%%%%%%%%%%%%%%%%%%
    PIX(1:(nBefore+1)) = 0;
    PIX((end-nAfter):end) = 0;
    nPIX = sum(PIX); % number of threshold crossings at this threhsold.
    %%%%%%%%%%%%%%%%%%%%
    % Determine the start and end of the target CP.
    %%%%%%%%%%%%%%%%%%%%
    if nPIX > 5 % don't bother if there are no detections.
        switch method
            case 'fixed_window'
                r = repmat(-nBefore:nAfter, nPIX, 1); % index range around peak.
                rr = repmat(find(PIX), 1, nWavePts);
                rrr = r + rr; % Indices of waveforms.
                %%
                d = LFP(:,iThreshCh);
                CP{iThreshCh} = d(rrr);
            case 'zero_crossing'
                % Each CP will have a variable duration. This is a pain in
                % the ass.
                CP{iThreshCh} = [];
        end
    else
        CP{iThreshCh} = [];
    end

end

% Now, how do we cluster them: Standard methods 1) PCA to get features, 2)
% KlustaKwik and merging 3) clean up in MClust 4) look at their behavior.
% kmeans might be the easiest way to do this.

