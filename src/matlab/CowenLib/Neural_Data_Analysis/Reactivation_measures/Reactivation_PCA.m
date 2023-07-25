function [OUT, P,nComp] = Reactivation_PCA(STM, STM_binsize_msec)
%function [OUT] = Reactivation_EV(STM, STM_binsize_msec)
% Based loosely on Francesco Battaglia's work.
% THIS NEEDS TO BE REDONE - DOES NOT WORK - I think a big conceptual issue
% is afoot - we are still looking at temporal correlations when PCA works
% to get rid of such correlations (given that vectors are slices of time). 
%
% INPUT: 
% STM - cell array: Pass in the binned spike train matrices (rows = time, col = cell) for
%       Each element of the cell array STM is the STM for each epoch.
%
% epochs: 1 = rest 1, 2 = maze (awake), 3 = Rest 2.
%
% STM_binsize_msec: Pass in the binsizes for each epoch as a 3 element matrix.
%
% Options:
%
% Cowen 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii = 1:3
    STM{ii} = Z_scores(STM{ii});
end
% Compute the principal components
[PC_maze, sc_maze, maze_lat] = princomp(STM{2});
% Determine the numnber of latent variables to use
t = sum(maze_lat);
cs = cumsum(maze_lat);
nComp = find(cs > t*.5, 1 ,'first'); % Select the number of components that explain 50% of the variance.
% Transform all of the matrices by these components.
SC{1} = PC_maze(:,1:nComp)' * STM{1}'; % rest 1
SC{1} = SC{1}';
SC{2} = sc_maze(:,1:nComp); % maze
SC{3} = PC_maze(:,1:nComp)' * STM{3}'; % rest 2
SC{3} = SC{3}';
% The standard EV approach to reactivation can now be used with these new
% time by transformed component matrices.
[OUT, P] = Reactivation_EV(SC, STM_binsize_msec);
