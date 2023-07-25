function [eva, C, eva_linkage, C_linkage] = kmeans_optimal_k(D,max_k)
% function [eva, C] = kmeans_optimal_k(D,max_k)
% Determine the optimal number of clusters using kmeans on the data d.
%
% INPUT: D = n samples x d dimensions - data
%        max_k = the max number of k to evaluate.
%
% NOTE: uses CalinskiHarabasz
%
% see https://www.mathworks.com/matlabcentral/answers/76879-determining-the-optimal-number-of-clusters-in-kmeans-technique
% cowen 2021
D = double(D);
klist=2:max_k;%the number of clusters you want to try
myfunc = @(X,K)(kmeans(X, K));
eva = evalclusters(D,myfunc,'CalinskiHarabasz','klist',klist); % there are other measures like silhouette
if nargout > 1
    C = kmeans(D,eva.OptimalK);
end
if nargout > 2
    % Compare to hierarchical
    eva_linkage = evalclusters(D,'linkage','CalinskiHarabasz','klist',klist); % there are other measures like silhouette
    C_linkage = clusterdata(D,eva_linkage.OptimalK); 
end
%d = [randn(100,1); randn(100,1)-10;randn(100,1)+14;randn(100,1)+30;randn(100,1)-30;randn(100,1)+130];
%d = [randn(100,1); randn(100,1);randn(100,1);randn(100,1)];
if 0  %old way - this is depreciated but here in case I missed something.
    
    %  measures of optimal k
    %  BIC
    %  mean l-ratio
    %  CalinskiHarabaszCg
    %  The Fellous method.
    %
    %    BICs- BIC(t) = -2 * LL(t) + nu/2 log(n) where LL(t) is the maximum
    %   value of the likelihood, nu is the number of parameters and n the
    %   number of samples.
    %
    %
    niter = 2;
    % max_k = 15;
    m = zeros(niter,4);
    for ii = 1:max_k
        for jj = 1:niter
            if ii == 1
                c = ones(size(d,1),1);
            else
                c = kmeans(d,ii,'distance','cityblock','emptyaction','drop');
                %             if jj == 1
                %                 clf;hist_groups(d,c)
                %                 title(num2str(ii))
                %             end
            end
            bc = BIC(d,c);
            
            [m(jj,1)] = CalinskiHarabaszCg(grpstats(d,c), d, c);
            %         [all_q all_lr] = cluster_quality(d,c);
            %         m(jj,2) = mean(all_q(:,2));
            %         m(jj,3) = mean(all_lr(:,2));
            m(jj,4) = bc;
        end
        m = mean(m);
        Cg(ii) = m(1);
        Cq(ii) = m(4);
        Clr(ii) = m(3);
    end
    figure;
    subplot(4,1,1)
    plot(Cg)
    subplot(4,1,2)
    plot(Cq)
    subplot(4,1,3)
    plot(Clr)
    subplot(4,1,4)
    hist(d,40)
end
