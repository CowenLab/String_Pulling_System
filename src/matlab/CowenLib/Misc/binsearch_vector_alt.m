function ix = binsearch_vector_alt(v_base,v_search)
% assumes sorted. Finds first instance of each element of v_search in
% v_base.
%
% an alternative to the much faster binsearch_vector that can sadly crash
% at times (it's a mex file) - usually the crash is because v_base was not
% sorted.
%
% Cowen 2018
% if ~issorted(v_base)
%     error('v_base must be sorted!')
% end
ix = nan(size(v_search));
for ii = 1:length(v_search)
    tmp = find(v_base >= v_search(ii),1,'first');
    if ~isempty(tmp)
        ix(ii) = tmp;
    end
end
