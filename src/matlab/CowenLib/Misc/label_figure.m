function out = label_figure(mytext,location,figure_name)
%function anew = label_figure(mytext,location)
% Insert a vertical label on the figure axis for reference purposes.
%
% INPUT: Text to insert and optionally the location on the axis at which to
% plot it. Usually only need the text. Assumes the gcf.
%
% cowen 2006
% cowen 2009 - removed the ID parameter - it was stupid - but may break
% previous versions. Also added the bottom left. Very handy for long
% labels.
%
dbs = dbstack;
if nargin ==0
    if ~isempty(dbs)
        mytext = [ dbs(end).file  '   :' num2str(dbs(end).line)];
    else
        error('Pass in a function name')
    end
end
if nargin < 2 || isempty(location)
    location = 'right vertical';
end
if nargin < 3
    figure_name = '';
end
set(gcf,'Name',figure_name)

aold = gca;

switch location
    case 'right vertical'
        anew = axes('position',[.98 .015 .5 .1]);
        h = text(.015,.015,mytext);
        set(h,'Rotation',90)
        set(h,'FontSize',6);
    case {'bottom left' 'lower left'}
        anew = axes('position',[.02 .015 .8 .1]);
        h = text(.015,.015,mytext);
        %        set(h,'Rotation',0)
        set(h,'FontSize',10);
    case {'top left' 'upper left'}
        anew = axes('position',[.02 .98 .8 .1]);
        h = text(.015,.015,mytext);
        %        set(h,'Rotation',0)
        set(h,'FontSize',10);
    otherwise
        disp('Incorrect location')
        
end
axis off
axes(aold);
axis on
if nargout > 0
    out = anew;
end
