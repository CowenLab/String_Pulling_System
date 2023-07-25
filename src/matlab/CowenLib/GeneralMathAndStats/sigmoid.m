function newim = sigmoid(im, gain, cutoff)
% ADJCONTRAST - Adjusts image contrast using sigmoid function.
%
% function g = adjcontrast(im, gain, cutoff)
%
% Arguments:
%            im     - image to be processed.
%            gain   - controls the actual contrast; 
%                     A value of about 5 is neutral (little change).
%                     A value of 1 reduces contrast to about 20% of original
%                     A value of 10 increases contrast about 2.5x.
%                     a reasonable range of values to experiment with.
%            cutoff - represents the (normalised) grey value about which
%                     contrast is increased or decreased.  An initial
%                     value you might use is 0.5 (the midpoint of the
%                     greyscale) but different images may require
%                     different points of the greyscale to be enhanced.  

% Peter Kovesi
% School of Computer Science & Software Engineering
% The University of Western Australia
% pk @ csse uwa edu au     
% http://www.cs.uwa.edu.au/~pk
%
% July 2001
if isa(im,'uint8');
    newim = double(im);
else 
    newim = im;
end
if nargin < 2
    gain = .5;
end
if nargin < 3
    cutoff = 5;
end
% rescale range 0-1
newim = newim-min(min(newim));
newim = newim./max(max(newim));

newim =  1./(1 + exp(gain*(cutoff-newim)));  % Apply Sigmoid function