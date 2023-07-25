function [badix goodix]= common_zero_indices(d,g)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finds an EQUAL number of zeros in d for the groups specified in g- 
%  Useful for removing trials in which neurons did NOT fire.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
z = find(d == 0);
badix = [];goodix = [];
ix = [];
keepgoing = true;
count = 1;
if isempty(z)
    goodix = 1:length(g);
    return;
end
u = unique(g);
% Find indices WITHIN each group with zeros.
for ii = 1:length(u)
    gzix{ii} = find(g == u(ii) & d ==0);
    len(ii) = length(gzix{ii});
end
nToKill = min(len);
for ii = 1:length(u)
    badix = [badix; gzix{ii}(1:nToKill)];
end
goodix = setdiff(1:length(g),badix);