function R = Sliding_window(Q, winsize, shiftamnt,method)
%
% Slide a window across the Q matrix to get a rate code for each timestep
%
% INPUT: Q matrix in cell x time
%        window size
%        offset amount to slide the window (default is one bin)
%
% OUTPUT: 
%        A matrix of population rate codes for each timeshift.
%

% cowen
if nargin ==2
   shiftamnt = 1;
end	

if nargin == 3
   method = 'mean';
end

R = sparse(Rows(Q),(Cols(Q)-winsize+1)/shiftamnt);
cnt = 1;

switch method
case 'mean'
  for  ii = 1:shiftamnt:(Cols(Q)-winsize+1)
    R(:,cnt) = mean(Q(:,ii:ii+winsize-1)')';
    cnt = cnt + 1;
  end	
case 'median'
  for  ii = 1:shiftamnt:(Cols(Q)-winsize+1)
    R(:,cnt) = median(Q(:,ii:ii+winsize-1)')';
    cnt = cnt + 1;
  end	
case 'sum'
  for  ii = 1:shiftamnt:(Cols(Q)-winsize+1)
    R(:,cnt) = sum(Q(:,ii:ii+winsize-1)')';
    cnt = cnt + 1;
  end	
otherwise
  error('wrong method')
end

