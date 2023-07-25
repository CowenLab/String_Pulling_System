function bic = lyngby_ikm_bic(X, Centers, Assign, clusters, varargin)
% lyngby_ikm_bic        - Bayesian information criterion for K-means
%
%       bic = lyngby_ikm_bic(X, Assign, Centers, clusters)
%
%       Input:  X        Data matrix
%               Center   Cluster centers
%               Assign   Assignment vector matrix
%               clusters List of number of clusters
%
%       Output  bic      BIC 
%
%       Bayesian information criterion for iterative K-means.
%
%       Example: 
%         load iris.txt
%         clusters = 1:50;
%         [C,A] = lyngby_ikm_main(iris, 'clusters', clusters);
%         bic   = lyngby_ikm_bic(iris, C, A, clusters);
%         plot(bic), xlabel('Clusters')
%         ylabel('Log likelihood/bic');
%
%       See also LYNGBY, LYNGBY_KM_BIC, LYNGBY_IKM_MAIN,
%                LYNGBY_KM_MAIN, LYNGBY_KM_LOGLIKELIHOOD,
%                LYNGBY_KM_WITHIN, LYNGBY_IKM_PLOT_W.
%
% $Id: lyngby_ikm_bic.m,v 1.2 2003/02/05 18:52:52 fnielsen Exp $


    if nargin < 4
      error('Too few input arguments')
    end

    [N,P] = size(X);
    
    offset = 0;
    for n = 1:length(clusters)
      K = clusters(n);
      assign  = Assign(:,n);
      centers = Centers((1:K)+offset,:);
      offset = offset + K; 
      bic(n) = lyngby_km_bic(X, centers, assign);
    end
      






