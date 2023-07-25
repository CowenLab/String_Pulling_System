function h = barc(X,Y,colors)
% Draws a bar graph with bars of height Y at position X with color in the colros matrix (each row is a color or a cell array of 'r'...)
%
if iscell(colors)
	for ii = 1:length(X)
	   hh(ii) = bar( X(ii),Y(ii),colors{ii});
	   hold on
	end
else
    if Rows(colors)< length(X)
        colors = repmat(colors,length(X),1);
    end
	for ii = 1:length(X)
	   hh(ii) = bar(X(ii),Y(ii));
	   hold on
	   set(hh(ii),'FaceColor',colors(ii,:));
	end
end
set(gca,'XTick',1:max(X))
box off
if nargout == 1
    h = hh;
end