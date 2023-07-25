function [PI,E,aH,aO] = Neuralnet_prop_force_cube_out(wIH,wHO,in_pat,out_pat)
%
% Propagate error through a two layer network. Return the sum squared
% error for all the training sets and the unit activations for the 
% hidden and output layers. A tanh activation function is assumed. 
% In this version, the outputs are squared to accentuate
% the active units. See Lang, Waibel, and Hinton(1990) p. 35 
%
% INPUT: wIH = weights from input to hidden layer
%        wOH = weights from hidden layer to output layer
%     in_pat = cell array of input patterns
%    out_pat = cell array of output patterns
%
% OUTPUT: PI = SSE (performance index
%          E = Errof for each sample
%         aH = hidden layer activation
%         aO = output layer activation
% NOTE: 
% 
%  Bias columns(ones) are added to the input and hidden layers. Bias rows are 
%  assumed to be present in the weight matrices passed in.

% cowen 

nsamples = length(out_pat); % Number of samples
PI = 0; % Performance indicator(SSE)
bI = ones(size(in_pat{1},1),1); % Bias column input units
bH = ones(size(in_pat{1},1),1); % Bias column hidden units

for sample = 1:nsamples
   % Caluclate the net input to the hidden layer.
   niH = [in_pat{sample},bI]*wIH; % last term is the bias
   % Compute the activation
   aH{sample} = pmntanh(niH);
   % Net input to output units
   niO = [aH{sample},bH] * wHO; 
   % Compute the activation
   aO{sample} = pmntanh(niO).^3; 
   % --------------------------------------------------------------------
   % Compute the error
   % --------------------------------------------------------------------
   [i,j] = find(aO{sample} == max(max(aO{sample})));
   E{sample} = zeros(size(aO{sample}));      
   E{sample}(i(1),:) = out_pat{sample}(i(1),:) - aO{sample}(i(1),:);   
   PI = PI + Vector(E{sample})*Vector(E{sample})'; % Update performance index (SSE)
end
PI = PI/(2*nsamples);
