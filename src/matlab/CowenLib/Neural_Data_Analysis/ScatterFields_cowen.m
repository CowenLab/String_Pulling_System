function [SF] = ScatterFields_cowen(M,t)
% Find the times in the first column of matrix M that correspond most
% closely to the values in t.
%
% t can be a cell array of timestmamps. If so, a cell array of SFs is
% returned for ech element in t.
%
% This is similar to the Redish Scatterfields without all of the extra
% object oriented packing and unpacking and with my modified
% binsearch_vector function.
%
% Cowen.
if isempty(M)
    SF = [];
    return
end

if iscell(t)
    SF = cell(1,length(t));
    for ii = 1:length(t)
        SF{ii} = ScatterFields_cowen(M,t{ii});
    end
else
    ix = binsearch_vector(M(:,1), t); % MUCH faster than using binsearch with a for loop. Can crash if
    SF = M(ix,:);

    d = t(:) - SF(:,1);

    if any(d) > 80e3
        error('Problem with scatterfields')
        % If timing is usec, then the sampling rate for the video is about
        % 30msec so if some time and the data are off by much more than that,
        % spit out an error.
    end
end
