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
   error('feature_wavePC2 needs 2 or 3 input arguments');
end

pc = [         -0.302038768882227
        -0.302038768882227
        -0.274594675309843
        -0.219982612489545
         -0.19088847265873
         -0.19787254683885
        -0.204544873023665
        -0.181022057299047
        -0.270169487203765
        -0.278237954998499
         -0.24747084533943
        -0.237166798512539
        -0.239991003111942
        -0.238521111434274
        -0.192187524266624
       -0.0932691193190371
       -0.0230665876873598
         0.011005200247638
        0.0273960799884229
         0.033697973362857
        0.0321129214095144
        0.0242562602395981
       0.00910754639357133
       -0.0146384473458195
       -0.0499050711173086
       -0.0937782693731344
        -0.143918290672249
        -0.154091199619666
        -0.154091199619666
        -0.154091199619666
        -0.154091199619666
        -0.154091199619666];
    
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
   wavePCNames{iC} = ['stdPC2_25600'  ': ' num2str(f(iC))];
end