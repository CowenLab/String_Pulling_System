function [P_joint, p_words, p_position, word_at_bin, pos_at_bin] = Joint_prob(spikes_ts,position_tsd,binsize,wordsize)
%
% INPUT: ts object of spike times or a list of spike times
%        tsd object of positions or a matrix where col 1 is the timestamps and col 2 are the 
%          positions. This must be one dimensional and the position must be indices to positions
%          in a 1 or 2D matrix!
%        size of bins to make a bit in the spike train (msec)
%        number of bits per word
%
% OUTPUT: the matrix of words(rows) by positions(cols)
%

% cowen 8/26/99

% Convert the data if necessary.
if ~strcmp(class(spikes_ts),'ts')
	spikes_ts = ts(spikes_ts(:));
end
if ~strcmp(class(position_tsd),'tsd')
	position_tsd = tsd(position_tsd(:,1),position_tsd(:,2));
end

% Calcuate the prior probability for the words.
Qctsd    =  MakeQfromS({spikes_ts}, binsize*10);
words    =  Count_words(full(Data(Qctsd)),wordsize,'sliding');
s        =  sum(words(:,2));
p_words  =  [words(:,1) words(:,2)/s];

% Calculate the prior probability for position
up       =  unique(Data(position_tsd));
count    =  hist(Data(position_tsd),up);
sp       =  sum(count);
p_position = [up (count/sp)'];

% Joint needs only two things: position at every bin
% and the word present at every bin(binary code)
idx_of_pos_at_bin = findAlignment(position_tsd,Range(Qctsd));
pos = Data(position_tsd);
pos_at_bin = pos(idx_of_pos_at_bin);

train = Data(Qctsd)>0; % Get the spike train(all non-zeros treated as ones)
train_len = length(train)-wordsize+1;
word_at_bin = zeros(train_len,1);
word_idx_at_bin = zeros(train_len,1);

for ii = 1:(train_len)
   word_idx_at_bin(ii) = find(bi2de(train(ii:ii+wordsize-1))==words(:,1));
   word_at_bin(ii) = bi2de(train(ii:ii+wordsize-1));
end

times = Range(Qctsd);

M = [word_idx_at_bin pos_at_bin(1:train_len) ];
% Sum up all the position and 
P_joint = zeros(length(unique(words(:,1))),max(pos));
for ii = 1:Rows(M)
   P_joint(M(ii,1),M(ii,2)) = P_joint(M(ii,1),M(ii,2)) + 1;
end

P_joint = P_joint./sum(sum(P_joint));
