function l = lyngby_km_loglikelihood(X, Centers, Assign, varargin)

% lyngby_km_loglikelihood - Log likelihood of K-means model
%
%       l = lyngby_km_loglikelihood(X, Center, Assign)
%
%       Input:  X       Data matrix
%               Center  Centers of estimated clusters
%               Assign  Assignment vector
%
%       Output: l       Log likelihood
%
%       Calculate the logarithm of the likelihood to the K-means model
%       when it is regarded as a Gaussian mixture model with isotropic
%       variance and an equal assignment weight. 
%     
%       The within variance assumes an isotropic variance, ie, that
%       there has been no standardization (eg, 'std' or 'range')
%       during the K-means estimation.  
%
%       Example:
%         load iris.txt
%         for n = 1:50
%           [C,A] = lyngby_km_main(iris, 'type', 'mean', 'clusters', n, 'init', 'random');
%           l(n) = lyngby_km_loglikelihood(iris, C, A);
%         end
%         plot(l), xlabel('Clusters'), ylabel('Log likelihood')
%
%       See also LYNGBY, LYNGBY_KM_MAIN, LYNGBY_KM_WITHIN.
%
% $Id: lyngby_km_loglikelihood.m,v 1.1 2003/02/03 17:46:20 fnielsen Exp $


    % Check arguments
    if nargin < 3 
      error('Too few input arguments');
    end
    
    % Default arguments
    sigmaType = 'unbiased';
    

    [N,P] = size(X);    % Data matrix dimensions
    K = max(Assign);    % Number of clusters
    
    % Hard assigment variance
    Within = lyngby_km_within(X, Centers, Assign, 'type', 'trace');

    if strcmp(sigmaType, 'ml')
      % Hard assigment, biased maximum likelihood estimate
      sigma2 = Within / N;
    elseif strcmp(sigmaType, 'unbiased')
      sigma2 = 0;
      for c = 1:K
    index = find(Assign==c);
    Nk = length(index);
    sigma2 = sigma2 + ...
        sum(sum( (X(index,:) - ...
        repmat(Centers(c,:), Nk, 1)).^2 )) ...
        / (Nk-1+realmin);
      end
    else
      error('Internal error')
    end
      
      
    l(1) = - N*P/2 * log(2*pi*sigma2);
    l(2) = - N / (2*sigma2);
    l(3) = - Within;
    l(4) = - log(K);
    l = sum(l);