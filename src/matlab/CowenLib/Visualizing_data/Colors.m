function [c CM] = Colors(type,mapname,ncolors)
% Returns a cell array of colors.
if nargin < 1
    type = 'normal';
end
if nargin < 2
    mapname = 'jet';
end
if nargin < 3
    ncolors = 8;
end

CM = zeros(ncolors,3);
switch type
    case 'normal'
        c = {'b' 'r' 'g' 'c' 'k' 'y' 'm' 'b' 'r' 'g' 'c' 'k' 'y' 'm' 'b' 'r' 'g' 'c' 'k' 'y' 'm' 'b'  'r' 'g' 'c' 'k' 'y' 'm' 'b' 'r' 'g' 'c' 'k' 'y' 'm' 'b' 'r' 'g' 'c' 'k' 'y' 'm' 'b'  'r' 'g' 'c' 'k' 'y' 'm' 'b' 'r' 'g' 'c' 'k' 'y' 'm' 'b' 'r' 'g' 'c' 'k' 'y' 'm' 'b'  'r' 'g' 'c' 'k' 'y' 'm' 'b' 'r' 'g' 'c' 'k' 'y' 'm' 'b' 'r' 'g' 'c' 'k' 'y' 'm' 'b' };
    case 'colormap' % give me colors from a specific colormap.
        j = feval(mapname);
        ix = ceil(linspace(1,Rows(j),ncolors));
        
        for ii = 1:ncolors
            c{ii} = j(ix(ii),:);
            CM(ii,:) = j(ix(ii),:);
        end
        
end
