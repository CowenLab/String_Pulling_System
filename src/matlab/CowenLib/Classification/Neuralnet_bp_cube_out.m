function [wIH,wHO,SSE_vector,iter] = Neuralnet_bp_cube_out(wIH,wHO,in_pat,...
   out_pat,eta,max_iter,stop_crit)
%
% Backpropagation neural network. Incremental update rule with a tanh 
% activation function. In this version, the outputs are squared to accentuate
% the active units. See Lang, Waibel, and Hinton(1990) p. 35 
%
% INPUT: wIH = weights from input to hidden layer
%        wOH = weights from hidden layer to output layer
%     in_pat = cell array of input patterns
%    out_pat = cell array of output patterns
%        eta = learning rate
%   maz_iter = maximum number of iterations.
%  stop_crit = stopping criteria
%
% OUTPUT: wIH, wHO = weights after training
%        SSE_vector = vector of SSE for each trial
%           iter   = iteration number of the last trial.
%
% NOTE: 
% 
%  Bias columns(ones) are added to the input and hidden layers. Bias rows are 
%  assumed to be present in the weight matrices passed in.

% cowen 

if nargin < 7
   % if no stopping criteria passes, assume it is zero
   stop_crit = 0;
end
   
nsamples = length(out_pat); % Number of samples
SSE = 0; % Performance indicator(SSE)
SSE_vector = zeros(1,max_iter); % Stores performance for each trial.

bI = ones(size(in_pat{1},1),1); % Bias column input units
bH = ones(size(in_pat{1},1),1); % Bias column hidden units
for iter=1:max_iter
   SSE=0;
   for sample = 1:nsamples
      % Caluclate the net input to the hidden layer.
      niH = [in_pat{sample},bI]*wIH; % last term is the bias
      % Compute the activation
      aH = pmntanh(niH);
      % Net input to output units
      niO = [aH,bH] * wHO; 
      % Compute the activation
      aO = pmntanh(niO).^3; 
      % --------------------------------------------------------------------
      % Compute the error
      % --------------------------------------------------------------------
      E            = out_pat{sample} - aO;       % Training error
      %SSE          = sum(sum(E.*E));            % Sum of squared errors (SSE)
      % --------------------------------------------------------------------
      % Backpropagage the error
      % --------------------------------------------------------------------
      % delta for ouput layer -- non-linear outputs
      % Just square the outputs
      d2 = 6*E.*(pmntanh(niO).^2).*(1-aO.*aO); % 1x3
      % delta for hidden layer -- non-linear outputs
      d1 = (1-aH.*aH).*(d2*wHO(1:end-1,:)');
      % 
      cHO = (eta*d2'*[aH,bH])';
      wHO = wHO + cHO;
      
      cIH = (eta*[in_pat{sample},bH])'*d1;
      wIH = wIH + cIH;   
      
      % measure preformance
      SSE = SSE + E(:)'*E(:); % Update performance index (SSE)
   end
   SSE = SSE/(2*nsamples);
   SSE_vector(iter)=SSE;
   fprintf('iteration # %i   SSE = %f\n',iter,SSE)
   if SSE < stop_crit, break, end         % Check if stop condition is satisfied
end
