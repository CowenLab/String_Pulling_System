function h = barp(A,B,C);
% a bar plot that plots bars with the patch call -- and no spaces or lines between them.
%   matlab's bar can sometimes crash and does wierd things. This routine gets around these problems.
%
%function h = barp(A,B,C)
%
% INPUT: Values for the bars.
%  if 1 arg is passed, it is assumed to be the bar heights (must be a vector)
%  if 2 arguments are passed, the first is assumed to be the xaxis.
%  if one of the arguments is 'offset', followed by a number, the xaxis if offset by that 
%    number (useful if you want to align the bars on x_axis(offset = 0 (default)) or center them(offset = .5)
%  if three arguments are passed, first is xaxis, second is yaxis and third is offset. If the yaxis
%    is left empty, then it as assumed to be ordered from 1:length(yaxis) -
%    THIRD CAN ALSO BE A COLOR (e.g. 'k') IF YOU DON'T WANT TO PASS AN
%    OFSET.
%
% OUTPUT: A gorgeous plot and a figure handle to the patch objects of the plot.
%
% cowen 2002
offset = 0;
A = A(:)';
if nargin < 3
    C = 'k';
end

if ischar(C)
    fcolor = C;
else
    fcolor = 'k';
end

switch nargin 
case 1
    y = [zeros(1,length(A));A;A;zeros(1,length(A))];
    x = [offset:length(A)-1+offset; offset:length(A)-1+offset; (1+offset):length(A)+offset; (1+offset):length(A)+offset];
case 2
    B = B(:)';
    x = [A(1:end)+offset;A(1:end)+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset];
    %x = [A(1:end)+offset;A(1:end)+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset];
    y = [zeros(1,length(B));B;B;zeros(1,length(B))];
case 3
    B = B(:)';
    if ~ischar(C)
        offset = C;
    end
    y = [zeros(1,length(B));B;B;zeros(1,length(B))];
    if isempty(A)
        x = [offset:length(A)-1+offset; offset:length(A)-1+offset; (1+offset):length(A)+offset; (1+offset):length(A)+offset];
    else
        x = [A(1:end)+offset;A(1:end)+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset;[A(2:end) A(end) + A(end) - A(end-1) ]+offset];
    end
otherwise
    error('Invalid number of arguments')
end

h = patch(x,y,fcolor);
%set(h,'LineStyle','-')
% Get rid of the lines -- or create the illusion that the lines are gone.
%fc = get(h,'FaceColor');
set(h,'EdgeColor',fcolor);
axis tight;
box off