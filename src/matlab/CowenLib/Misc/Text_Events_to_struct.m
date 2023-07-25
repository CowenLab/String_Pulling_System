function E = Scores_to_struct(filename, delimiter)
if nargin == 1
    delimiter = ',';
end

[a, b] = textread(filename,'%s%s','delimiter',delimiter,'commentstyle','matlab');
vbls = unique(b);
for vbl = 1:length(vbls);
    count = 1;
    idx = [];
    for ii = 1:length(b)
        if strcmp(b{ii},vbls{vbl})
            idx(count) = ii;
            count = count + 1;
        end
    end
    
    for ii = 1:length(idx)
        try
            eval(['E.' strtok(b{idx(ii)}) '(ii) =' a{idx(ii)} ';'])
        catch
            disp(['Could not enter event: ' b{idx(ii)}]);
        end
    end
end