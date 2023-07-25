function o = note(text)
% stores a note in the currently active figure in the UserData field
% Cowen 2010
if nargin ==0
    o = get(gcf,'UserData');
else
    set(gcf,'UserData',text);
    set(gcf,'Name','Contains a note')
end