function M = Plot_scatterfields(tsd_array, base_tsd, nperpage, titletext)
% INPUT
%  an array of tsd objects to plot
%  a base tsd on which to plot the tsd objects.
% 
% OUTPUT
%  subplots of each tsd in the array.
%

% cowen 2/10/00
if nargin < 3
  nperpage = 6;
end
if nargin < 4
  titletext = '';
end

count = 1;
for ii = 1:length(tsd_array)
  if count > nperpage
    figure
    orient tall
    count = 1;
  end
  subplot(nperpage,1,count)
  plot(base_tsd);
  hold on
  plot(tsd_array{ii},'ro');
  xlabel('Timestamps')
  ylabel('Position')
  if count == 1
    title([titletext ' ID ' num2str(ii)])
  else
    title(['ID ' num2str(ii)])
  end
  count = count + 1;
end
