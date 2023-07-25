function h = barch(X,Y,colors)
% Draws a bar graph with bars of height Y at position X with color in the colros matrix (each row is a color or a cell array of 'r'...)
%
if iscell(colors)
	for ii = 1:length(X)
	   h(ii) = barh( X(ii),Y(ii),colors{ii});
	   hold on
	end
else
	for ii = 1:length(X)
	   h(ii) = barh(X(ii),Y(ii));
	   hold on
	   set(h(ii),'FaceColor',colors(ii,:));
	end
end
set(gca,'YTick',0:length(X))
