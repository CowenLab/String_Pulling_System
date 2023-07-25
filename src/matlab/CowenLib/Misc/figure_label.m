function h = figure_label(labeltext, fignum)
%function h = figure_label(labeltext)
% Draw a figure AND label it.
% INPUT: Text to plot on the figure.
% OUTPUT: A figure and a label.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2006
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0
    disp('figure_label REQUIRES TEXT FOR THE LABEL!')
    return
end
if nargin < 2
    fignum = [];
end

if nargout > 0
    if isempty(fignum)
        h = figure;
    else
        h = figure(fignum);
    end
%    set(h, 'Visible', off);
else
    if isempty(fignum)
        a = figure;
    else
        a = figure(fignum);
    end
%    set(a, 'Visible', off);
end

label_figure(labeltext);
% Create a menu itme and shortcut key (ctrl - e) for quick saving to the desktop.
f = uimenu('Label','QSave');
uimenu(f,'Label','Saveas_emf','Callback',['Saveas_emf(''' labeltext ''')'],...
    'Separator','on','Accelerator','E');
uimenu(f,'Label','Saveas_png','Callback',['Saveas_png(''' labeltext ''')'],...
    'Separator','on','Accelerator','N');
axis off