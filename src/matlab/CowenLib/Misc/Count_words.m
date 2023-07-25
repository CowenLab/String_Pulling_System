function nw = Count_words(V, wordsize, method)
% 
% count the number of words in each spike train
%
% INPUT: matrix of 0's and 1's to slide over. Any non-zero value
%          will be converted into a one.
%        size of words
%        sliding or jumping window.
% OUTPUT: 
%         column 1 is the word id
%         column 2 is the number of words of that id.
%

% cowen
slide_size = 1;
r = [];
V = full(V) > 0; % Change non-zero values into ones
V = V(:)'; % make sure V is a column vector

if nargin == 2
   method = 'jumping'
end

if strcmp(method,'jumping')
   endpoint = 1;
else
   endpoint = wordsize;
end

for ii = 1:endpoint/slide_size
   len = length(V);
   % Eliminate the ends of V so that the reshape works and reshape.
	r = [r ; reshape(V(1:floor(length(V)/wordsize)*wordsize),wordsize,floor(len/wordsize))'];
	% matlab does not like sending vectors to bi2de so add on a 
	% zero if the wc is 1.
	if wordsize == 1
 	  r = [r, zeros(length(r),1)];
	end	
	% Remove one element of V and redo so the window slides across the data.
	V(slide_size) = [];
end

words = sort(bi2de(r));
u = unique(words);
count = hist(words,u);
nw = [u count'];
