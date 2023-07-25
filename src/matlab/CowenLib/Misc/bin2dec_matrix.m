function b = bin2dec_matrix(B,reverse_direction)
if nargin < 2
    reverse_direction = false;
end
b = zeros(Rows(B),1);
for ii = 1:Rows(B)
    %     s = strrep(num2str(B(ii,:)),' ','');
    s = num2str(B(ii,:));
    %     b(ii) = bin2dec(s(end:-1:1));
    if reverse_direction
        b(ii) = bin2dec(s(end:-1:1));
    else
        b(ii) = bin2dec(s);
    end
end
