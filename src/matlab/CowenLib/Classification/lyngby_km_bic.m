function bic = lyngby_km_bic(X, Centers, Assign, varargin)
% lyngby_km_bic        - Bayesian information criterion for K-means
%
%       bic = lyngby_km_bic(X, Assign, Centers, varargin)
%
%       Input:  X        Data matrix
%               Center   Cluster centers
%               Assign   Assignment vector
%
%       Output  bic      BIC 
%
%       Bayesian information criterion (BIC) for K-means that is
%       computed as the log likelihood penalized with a term
%      
%          BIC = log[ P(X|C, sigma2) ] - (K*P+1)/2 * log(N)
%
%       where X is the data matrix, C the centers, sigma2 the variance
%       (which here is estimated), (K*P+1) is the number of
%       paramenters in the model (K clusters on a P-dimensional
%       problem) and N is the number of objects in the X(N x P) data
%       matrix. 
%
%       Example: 
%         load iris.txt
%         for n = 1:50
%           [C,A] = lyngby_km_main(iris, 'type', 'mean', 'clusters', n, 'init', 'random');
%           l(n) = lyngby_km_loglikelihood(iris, C, A);
%           bic(n) = lyngby_km_bic(iris, C, A);
%         end
%         plot([l ; bic]'), xlabel('Clusters')
%         ylabel('Log likelihood/bic');
%
%       See also LYNGBY, LYNGBY_KM_MAIN, LYNGBY_KM_LOGLIKELIHOOD,
%                LYNGBY_KM_WITHIN.
%
% $Id: lyngby_km_bic.m,v 1.1 2003/02/03 17:56:02 fnielsen Exp $



    [N,P] = size(X);
    K = max(Assign);

    bic = lyngby_km_loglikelihood(X, Centers, Assign) - ...
    (K*P+1)/2 * log(N);
    