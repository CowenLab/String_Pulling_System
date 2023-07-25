function [P,R,states,Pshuff] = State_transition_probabilities(C)
% function [P,R] = State_transition_probabilities(C)
%  Creates a matrix that has the probabilities of transitioning from one
%  state to the next - It's a Markov state transition matrix.
%
% INPUT: a vector of integers representing a time series of states.
% OUTPUT: the transition probabilities between states where the list of states =
% unique(C);
% R = the raw counts for each state;
% states = the unique states;
% Pshuff = P after shuffling the order of C (and performing 20
% iterations)
%
% Cowen 2015
states = unique(C);
nStates = length(states);
P = zeros(nStates);
R = zeros(nStates);
for iC = 1:nStates
    ix = find(C==states(iC));
    ix = ix + 1; % the next state in the sequence.
    if ix(end) > length(C)
        ix(end) = [];
    end
    R(iC,:) = hist(C(ix),states);
    P(iC,:) = R(iC,:)/sum(R(iC,:));  % convert to probabilities
end

if nargout > 3
    % Determine expected transition probabilities by random chance.
    Pshuff = zeros(size(P));
    nIter = 20;
    for ii = 1:nIter
        Pshuff = Pshuff + State_transition_probabilities(C(randperm(length(C))));
    end
    Pshuff = Pshuff/nIter;
end

if nargout == 0
    figure
    imagesc(1:nStates,1:nStates,P)
    axis xy
    set(gca,'XTick',1:nStates);
    set(gca,'YTick',1:nStates);
    set(gca,'XTickLabel',states);
    set(gca,'YTickLabel',states);
    xlabel('State ID')
    ylabel('State ID')
    colorbar
    title('State Transition Matrix')
end