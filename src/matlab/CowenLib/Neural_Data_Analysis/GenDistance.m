function [distance_matrix] = GenDistance(varargin)
% Returns the distance matrix between the sequences passed in.
% INPUT: vectors -- that are sequences to be compared.
% OUTPUT: a symmetric distance matrix that displays the distance between
% the vectors.
% cowen
n_seq = length(varargin);
cmd_string = '!GenDistance.exe ';
for ii = 1:length(varargin)
    fname{ii} = ['GenDistTmp' num2str(ii)  '.txt'];
    fp = fopen(fname{ii},'w+');
    fprintf(fp,'%c',varargin{ii}'+64);
    fprintf('%c',varargin{ii}'+64)
    fprintf('\n')
    fclose(fp);
    cmd_string = [ cmd_string fname{ii} ' '];
end
cmd_string = [ cmd_string '> GenDistMatrix.out'];
eval(cmd_string);
% Load in the results and try to parse it.
distance_matrix = zeros(n_seq)*nan;
t = textread('GenDistMatrix.out','%s','delimiter','<>%');
lent = length(t);
count = 1;
for ii = 1:lent
    try
        tmp = str2num(t{ii});
        if ~isempty(tmp)
            v(count) = tmp;
            count = count+1;
        end
    catch
    end
        
end
count = 1;
for ii = (n_seq^2-1):-1:0
    try
        distance_matrix(count) = v(end-ii);
        count = count + 1;
    catch 
        count = count + 1;
    end
end

