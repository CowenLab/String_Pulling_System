function textbox(text_cell_array,fontsize)
% plots a figure with the text in text cell array.
% good for just displaying text/paragraphs in a figure window.
%
% function textbox(text_cell_array)
%
% INPUT: cell array to plot in a figure window.
% OUTPUT: figure of only text - does automatic word wrapping.
%
% cowen

if nargin == 1
    fontsize = 12;
end
% pos = x,y, width, height
pos = [.1 .1 .8 .1];
h = uicontrol('Style','Text','Units','Normalized','Position',pos,'HorizontalAlignment','left','FontSize',fontsize);
[outstring,newpos] = textwrap(h,text_cell_array);
pos(4) = newpos(4);
set(h,'String',outstring,'Position',[pos(1),pos(2),pos(3)+.1,pos(4)])