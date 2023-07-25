function big_figures()
% Maximizes all open figures
% Cowen 2014
figHandles = findobj('Type','figure');
for ii = 1:length(figHandles)
    set(figHandles(ii),'units','normalized','outerposition',[0 0 1 1])
end