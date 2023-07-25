function [class,distance] = State_vector_discriminator(test, training,group,k)
% INPUT
%         sample test matrix.
%         training training matrix (sample by variable)
%         group  
% OUTPUT
% 
%   for reference, class_nonpca and dist_nonpca are the results of classification without PCA.
%
% cowen

if nargin <= 3
  how_to_normalize = 'unit_std';
end

training = full(training); % Sometimes sparse matrices do weird things.

group = group(:)';

if any(group - round(group)) | any(group < 1)
  error('The third input argument must be positive integers.');
end

[n_train_samples,n_vbls] = size(training);

if n_train_samples ~= length(group),
  error('The number of rows in the second and third input arguments must match.');
end

[n_samples,sc] = size(test);
if sc ~= n_vbls
  error('The number of columns in the first and second input arguments must match.');
end

group_ids = sort(unique(group));
n_groups = length(group_ids);

if sum((group_ids-[1:n_groups]).^2)~=0
  error('groups must be ordered from 1 to n_groups')
end
for gg = group_ids;
  group_idx{gg} = find(group==gg);
end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main routine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scoreTRn = Normalize_matrix(training);
scoreTEn = Normalize_matrix(test);
dotprod = [scoreTEn*scoreTRn'];
  
class = zeros(n_samples,1);
distance = zeros(n_samples,n_groups)*nan;

% Choose a category for each of the test set members.
%  for ii=1:n_samples
%    [d, idx] = min(acos(dotprod(ii,:)));
%    distance(ii,group(idx)) = d;
%    class(ii) = group(idx);
%  end
% Have the k nearest neighbors vote according to their distance from
% the test sample. (1/distance)

for ii=1:n_samples
  
  [d, idx] = sort(acos(dotprod(ii,:)));
  vote = 1./d(1:k);            % amount of vote each element has 
  grp  = group(idx(1:k));     % group membership of these elements
  the_groups = sort(unique(grp));
  the_votes = zeros(size(the_groups));
  cnt = 1;
  for a_grp = the_groups
    idx = find(a_grp == grp);
    the_votes(cnt) = sum(vote(idx));
    cnt = cnt + 1;
  end
  [m,idx] = max(the_votes);
  class(ii) = the_groups(idx);
  idx2 = find(grp == the_groups(idx));
  distance(ii,the_groups(idx)) = mean(d(idx2)); 
end

%distance = acos(dotprod);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTT 
if nargout == 0
  figure
  subplot(1,3,1)
  imagesc(training)
  title('training')
  subplot(1,3,2)
  imagesc(test)
  title('test')
  subplot(1,3,3)
  imagesc(group')
  
  figure
  subplot(2,2,1)
  imagesc(scoreTR)
  title('Score TR')

  subplot(2,2,2)
  imagesc(scoreTE)
  title('Score test')
  subplot(2,2,3)
  imagesc(scoreTRn)
  title('norm Score TR')
  subplot(2,2,4)
  imagesc(scoreTEn)
  title('norm Score test')
  
  figure
  boxplot(training,0,'+',0)
  
  

  figure
  sym = get_symbols;
  for gg = group_ids;
    if pcs_to_use == 1
      plot(scoreTR(group_idx{gg}),sym{gg})
    elseif pcs_to_use == 2
      plot(scoreTR(group_idx{gg},1),scoreTR(group_idx{gg},2),sym{gg})
    elseif pcs_to_use == 3
      plot3(scoreTR(group_idx{gg},1),scoreTR(group_idx{gg},2),scoreTR(group_idx{gg},3),sym{gg})
    end
    
    hold on
  end
  
  figure
  subplot(1,2,1)
  imagesc(test*training')
  title('closeness of test to each vec in train')
  colorbar
  c = caxis;
  subplot(1,2,2)
  imagesc(dotprod)
  title('closeness of PC test to each vec in PC train')
    colorbar
end
