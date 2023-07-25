function O = flip_matrix(O,dire)
if nargin < 2
    dire = 'horizontal';
end
switch dire
    case 'horizontal'
        O = O(:,end:-1:1);
    case 'vertical'
        O = O(end:-1:1,:);
    otherwise
        error('improper flip type')
end

