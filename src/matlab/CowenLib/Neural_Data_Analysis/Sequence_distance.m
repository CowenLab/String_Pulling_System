function [Similarity, Counts, Pred, C_vectors, H_Pred, H_Est] = Sequence_distance(varargin)
% Returns the distance matrix between the sequences passed in.
% INPUT: vectors -- that are sequences to be compared.
% OUTPUT: a symmetric distance matrix that displays the distance between
% the vectors.
%
% 1.	Histogram the occurrences of each of the letters so you have an estimate of the probability (frequency) of occurring of each cell. This is not strictly frequency as all adjacent doublets have been eliminated. Call this H. This is calculated independently for each epoch (s1 m1 s2).
% 2.	Using these estimates, generate a predicted state transition matrix P for each epoch. For instance, if A had 100 counts, b has 20 counts and the total number of counts for all letters(cells) is 1000, the chance of A?B (and B?A for that matter) is 100/1000 *20/1000. This is calculated independently for each epoch (s1 m1 s2).
% 3.	For the observed probability matrix. Count the number of times all possible sequences of length 2 occurs (AB BC AC…). This creates a non-symmetric count matrix C. Divide this matrix by the total number of counts (alternatively, you could put in the ratio of the number of times divided by the total number of observed sequences (sum(C(:)). The resulting matrix is a state transition matrix of probabilities from the Observed data O. This is calculated independently for each epoch (s1 m1 s2).
% 4.	Subtract P from O to yield D. Doing this provides a measure of the Divergence of the observed probabilities from the predicted. Ideally, this measure would be a Z score, but I am not really sure how to generate confidence limits in this situation. Actually, I don’t think it’s possible. Using the divergence instead of the raw O is important as the raw O will bias the matrix to those pairs that contain cells that had high firing rates. As a result, if a cell had a high rate in M1 and S2, but not S1, a strong measure of sequence reactivation may result. Subtracting the predicted probability (based on the occurrences of that cell in V) will control for this.
% 5.	Compare the similarity of these prior probability normalized rate matrices generated for each epoch. Specifically, compare Ds1 with Dm1 and Ds2 with Dm1. 
%
% For clarity, I refer to the main sequences as sentences (ACABACDADCDOABD) and the
%  sub-sequence (the targets to search for (AB, BC...) as words and A,B,...
%  as characters. Makes life much easier.
% 
% cowen
n_sentences = 0;
plotit = 0;
method = 'default';
for ii = 1:nargin
    if ischar(varargin{ii})
        switch varargin{ii}
            case 'plotit'
                plotit = 1;
            otherwise
                method = varargin{ii};
        end
    else
        n_sentences = n_sentences + 1;
    end
end

master_sentence   = [];
master_timestamps = [];
word_length = 2; % The word length to analyze: 2 = AB 3 = ABA.
for sentence_cnt = 1:n_sentences
    if ischar(varargin{sentence_cnt})
        sentence{sentence_cnt} = varargin{sentence_cnt};
        timestamps{sentence_cnt} = [];
    else
        % Convert to character array if the user passed in numbers.
        if size(varargin{sentence_cnt},2) == 2
            sentence{sentence_cnt} = char(varargin{sentence_cnt}(:,2)+64);
            timestamps{sentence_cnt} = varargin{sentence_cnt}(:,1);
        else
            sentence{sentence_cnt} = char(varargin{sentence_cnt}(:)+64);
            timestamps{sentence_cnt} = [];
        end        
    end
    sentence{sentence_cnt} = sentence{sentence_cnt}(:)'; % make sure it is a row.
    timestamps{sentence_cnt} = timestamps{sentence_cnt}(:)'; % make sure it is a row.
    % The sentenceuence of everything.
    master_sentence = [master_sentence sentence{sentence_cnt}];
    master_timestamps = [master_timestamps timestamps{sentence_cnt}];
    sentence_length(sentence_cnt) = length(sentence{sentence_cnt});
    %unique_characters{sentence_cnt} = unique(sentence{sentence_cnt});
    %n_unique_characters(sentence_cnt) = length(unique_characters{sentence_cnt});
    %n_words(sentence_cnt) = n_unique_characters(sentence_cnt)^word_length - n_unique_characters(sentence_cnt)^(word_length-1); % Ignore the diagonal (AA, BB, CC)
end
all_unique_characters = unique(master_sentence);
total_n_unique_characters = length(all_unique_characters);
% Assume that adjacent identical characters are not allowed in each
% 2 character states. A state is defined as a 2 character sequence (AB,
% BC)...
%all_n_words = total_n_unique_characters^word_length - total_n_unique_characters(word_length-1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the combos to explore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[r,c] = find(zeros(total_n_unique_characters)==0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% go through each combos and count the pairs.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for sentence_cnt = 1:n_sentences
    Pred{sentence_cnt} = zeros(total_n_unique_characters);
    Counts{sentence_cnt} = zeros(total_n_unique_characters);
    for r_cnt = 1:length(r)
        % Compute the predicted probabilities based on the rates(counts)
        n_r = length(findstr(sentence{sentence_cnt},all_unique_characters(r(r_cnt))));
        n_c = length(findstr(sentence{sentence_cnt},all_unique_characters(c(r_cnt))));
        % I need to divide by the number of unique states, not the number
        % of states! Duh!
        % The following is the probability of one character to be in a
        % state times the prob of the other character being in a state.
        % This equals the probability of them co-occuring in the same
        % state. This is first computed by assuming all states are possible and then 
        % limiting down to the allowable states.
        % The following matrix does assume that the diagonal is valid.
        % We'll deal with that later.
        Pred{sentence_cnt}(r(r_cnt),c(r_cnt)) = (n_r*n_c)/(sentence_length(sentence_cnt).^2+eps);
        % strmatch could also be used.
        search_word = [all_unique_characters(r(r_cnt)) all_unique_characters(c(r_cnt))];
        Counts{sentence_cnt}(r(r_cnt),c(r_cnt)) = length(findstr(sentence{sentence_cnt},search_word));
    end
    %P_legal_states{sentence_cnt} = P{sentence_cnt};
   % P_legal_states{sentence_cnt}(illegal_states_idx) = nan;
   % P_legal_states{sentence_cnt} = P_legal_states{sentence_cnt}./nansum(P_legal_states{sentence_cnt}(:));
    %Counts{sentence_cnt}(illegal_states_idx) = nan;
    Est{sentence_cnt} = Counts{sentence_cnt}./(nansum(Counts{sentence_cnt}(:))+eps); % Probability
end

switch method
    case 'ignore adjacent repeats'
        legal_states_idx = find((r-c)~=0); % off diagonal.
        illegal_states_idx = find((r-c)==0); % the diagonal.
    case 'default'
        legal_states_idx = find(r); % all points
        illegal_states_idx = []; % no points
    otherwise
        error('UNKNOWN METHOD')
end
C_vectors = zeros(length(legal_states_idx),n_sentences);
ill_idx = sub2ind(size(Est{sentence_cnt}),r(illegal_states_idx),c(illegal_states_idx));
good_idx = sub2ind(size(Est{sentence_cnt}),r(legal_states_idx),c(legal_states_idx));
for sentence_cnt = 1:n_sentences
    % Set the impossible states (AA, BB, etc...) to have a 0 probability.
    Est{sentence_cnt}(ill_idx) = 0;
    Pred{sentence_cnt}(ill_idx) = 0;
    % Make it sum to 1.
    Est{sentence_cnt} = Est{sentence_cnt}./nansum(Est{sentence_cnt}(:));
    Pred{sentence_cnt} = Pred{sentence_cnt}./nansum(Pred{sentence_cnt}(:));
    E = Est{sentence_cnt}(good_idx);
    P = Pred{sentence_cnt}(good_idx);
    H_Est(sentence_cnt)  = Entropy(E(:));
    H_Pred(sentence_cnt) = Entropy(P(:));
    Diff_P{sentence_cnt} = E - P; % Should I subtract or divide? I DON'T KNOW!!
    C_vectors(:,sentence_cnt) = Diff_P{sentence_cnt};
end
% Calculate the distance bewtween the vectors. 
%  I am using the normalized dot product or vector angle as the
%  distance measure. How does this scale with dimensionality? If I increase
%  the number of cells, will this change the distribution of distances?
%  Should I normalize each distance matrix to sum to 1?
nC_vectors = Normalize_matrix( C_vectors );
Similarity = nC_vectors'*nC_vectors;
%Similarity = corrcoef(C_vectors);
% corrcoef normalizes by the variance-- which really doesn't make sense for
% this comparison so I use the norm dot product.
if nargout == 0 | plotit == 1
    nsent = length(Diff_P);
    for ii = 1:nsent
        subplot(4,nsent,sub2ind([nsent 4],ii,1))
        P = Pred{ii};
        P(illegal_states_idx) = nan;
        imagesc(P)
        set(gca,'FontSize',6)
        axis xy
        title([ num2str(ii) ' Pred H= ' num2str(H_Pred(ii))],'FontSize',8)
        subplot(4,nsent,sub2ind([nsent 4],ii,2))
        EP = Est{ii};
        EP(illegal_states_idx) = nan;
        imagesc(EP)
        set(gca,'FontSize',6)
        axis xy
        title(['Obs H= ' num2str(H_Est(ii))],'FontSize',8)
        subplot(4,nsent,sub2ind([nsent 4],ii,3))
        DP = Diff_P{ii};
        DP(illegal_states_idx) = nan;
        imagesc(DP)
        set(gca,'FontSize',6)
        axis xy
        title(['Diff ' ],'FontSize',8)
    end
    subplot(4,nsent,nsent*3+1)
    imagesc(nC_vectors)
    axis xy
    title('Vectorized Diff_P','FontSize',8)
    subplot(4,nsent,nsent*3+2)
    imagesc(Similarity)
    axis xy
    colorbar
    title(['Dot ' method],'FontSize',8)
end
