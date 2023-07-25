function [wavePCData, wavePCNames, wavePCPar] = feature_stdPC1(V, ttChannelValidity, Params)

% MClust
% wave PC with canonical (i.e., standard) principle components
% PCs are loaded from file: stdPC.mat
% canPC contains the variable pc, which contains all pc components in columns
% [wavePCData, wavePCNames, wavePCPar] = feature_canPC1(V, ttChannelValidity, Params)
% Calculate first waveform PRINCIPAL COMPONENTS  (PC1)
% if called with 2 arguments it recalcs the PC parameters,
% if called with 3 arguments it takes the PC parameters from the 3rd input
%
% INPUTS
%    V = TT tsd
%    ttChannelValidity = nCh x 1 of booleans
%    Params = 4x1 CellArray struct with fields
%             Params{}.pc (eigenvectos), 
%             Params{}.av (averages), 
%             Params{}.sd (std deviations) 
%
% OUTPUTS
%    Data - nSpikes x nPC*nCh  of waveform PCs of each spike for each valid channel
%    Names - "wavePCn: Ch"
%    wavePCPar - 4x1 cell array struct of Parameters; fields same as Params input above 

% David Euston, based on feature_wavePC1.m by Peter Lipa


%%% PARAMETERS:  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
norm = 1;    % normalize Waveforms (1) or don't normalize (0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

switch nargin
case 2
   recalcParams = 1;
case 3
   recalcParams = 0;
otherwise
   error('feature_wavePC1 needs 2 or 3 input arguments');
end

pc = [    
   -0.1016
   -0.1016
   -0.0981
   -0.0801
   -0.0485
   -0.0417
   -0.1171
   -0.1682
   -0.0626
    0.1023
    0.1686
    0.1847
    0.1739
    0.1227
   -0.0005
   -0.1390
   -0.2020
   -0.2281
   -0.2412
   -0.2491
   -0.2529
   -0.2536
   -0.2497
   -0.2403
   -0.2231
   -0.1997
   -0.1705
   -0.1643
   -0.1643
   -0.1643
   -0.1643
   -0.1643];
    
%load stdPC.mat

TTData = Data(V);
[nSpikes, nCh, nSamp] = size(TTData);

f = find(ttChannelValidity);
lf = length(f);

wavePCNames = cell(lf, 1); 
wavePCData  = zeros(nSpikes, lf);
I = ones(nSpikes,1);

for iC = 1:lf
   w = squeeze(TTData(:,f(iC),:));    % get data in nSpikes x nSamp array
   
   if norm
   	% normalize waveforms to unit L2 norm (so that only their SHAPE or
   	% relative angles but not their length (energy) matters)
   	l2norms = sqrt(sum(w.^2,2));
   	w = w./l2norms(:,ones(1,nSamp));
   end
    
   %sd = std(w);
   %av = mean(w);                % row mean vector

   wavePCPar{f(iC)}.pc = pc;
   %wavePCPar{f(iC)}.av = av;
   %wavePCPar{f(iC)}.sd = sd;
   %wstd=(w-(I*av))./(I*sd);     % standardize data to zero mean and unit variance
   %wpc = wstd*pc;               % project data onto principal component axes
   wpc = w*pc;                  % project raw waveforms onto principle components axes
   wavePCData(:,iC) = wpc(:,1);
   wavePCNames{iC} = ['stdPC1_25600'  ': ' num2str(f(iC))];
end