function [auc, p, auc_sh, auc_info] = Auc_from_ranksum(x,y)
%function [auc, p, auc_sh] = Auc_from_ranksum(x,y)
% 
% Area under the curve measure of the capacity to discriminate between the
% data in x and y.
%
% auc = the area under the curver measure.
% p = ranksum p value of the significance of the difference between the
% data.
% auc_sh = auc from a shuffled version of the data.
%
% if x and y have > 1 col, then pca is used to reduce the dimensionality.
%
% see http://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U
% A good measure of info content is ...
% abs(auc-.5) - abs(auc_sh-0.5)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2010
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check to see if the user passed in multi-dimensional data. If so, do PCA
% on the data to reduce the dimensionality and then compute the ranksum...

if size(x,2) > 1
    v = [x;y];
    v = [v  Z_Scores(v')']; % This allows the PCA to pick up on non-magnitude based changes such as increases or decreases in firing rate that are independent of magnitude
    [pc,sc] = princomp(v);
    x = sc(1:size(x,1),1);
    y = sc((size(x,1)+1):end,1);
end

[p,h,rs] = ranksum(x,y);

nx = length(x);
ny = length(y);

ns = min([nx ny]);

u = rs.ranksum - (ns*(ns + 1))/2;
auc = u/(nx*ny);
% Create a shuffled version as well.
if nargout > 2
    v = [x(:); y(:)];
    v = v(randperm(length(v)));
    auc_sh = Auc_from_ranksum(v(1:ns),v((ns+1):end));
end
if nargout > 3
    auc_info = abs(auc-.5) - mean(abs(auc_sh-.5));
end

% A good measure of info content is ...
% abs(auc-.5) - abs(auc_sh-0.5)

if nargout == 0 
    % Validate - make sure that the values make sense.
    arnd = Auc_from_ranksum(poissrnd(5,1000,1),poissrnd(5,1000,1))
    alft = Auc_from_ranksum(poissrnd(15,1000,1),poissrnd(5,1000,1))
    art = Auc_from_ranksum(poissrnd(5,1000,1),poissrnd(15,1000,1))
end