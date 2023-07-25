function qs
% does a quick save of the current figure to the temp directory.
%saveas(gcf,'C:\Temp\tmpfig.emf')
print('C:\Temp\tmpfig','-dmeta')
%print('C:\Temp\tmpfig','-dill')
%print('C:\Temp\tmpfig','-dpng','-r600')