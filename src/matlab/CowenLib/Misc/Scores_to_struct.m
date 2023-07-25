function E = Scores_to_struct(filename, delimiter)
%function E = Scores_to_struct(filename, delimiter)
% Convert the Scores.txt file into a structure. 
%  If no parameters are passed it assumes you are in the directory with
%  Scores.txt.
% cowen(2004)
E = [];
if nargin <2 1
    delimiter = '\t';
end
if nargin == 0
    filename = 'Scores.txt';
end

[a, b, c] = textread(filename,'%s%s%s','delimiter',delimiter,'commentstyle','matlab');

for ii = 1:length(a)
    c{ii} = strrep(c{ii}, ' ','_');
    % Truncate
    if length(c{ii})>20
        c{ii} = c{ii}(1:20);
    end
    % compare with the previous records. If it already has been entered,
    % count how many times and then add it to a pre-existing record.
    count = 0;
    for jj = 1:(ii-1)
        if strcmp(c{ii},c{jj})
            count = count + 1;
        end
    end
    try
        eval(['E.' strtok(c{ii}) '(' num2str(count+1) ') =' a{ii} ';'])
    catch
        disp(['Could not enter event: ' c{ii}]);
    end
end

