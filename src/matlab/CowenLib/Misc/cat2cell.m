function C = cat2cell(c)
% input is a vecotor of categoricals
% output is a cell array of strings.
% cowen 2020
c = char(c);
for ii = 1:Rows(c)
    C{ii} = strtrim(c(ii,:));
end
