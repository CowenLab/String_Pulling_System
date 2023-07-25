function [t_x_y sFreq] = Load_position_text_file(fname ,st_end_time_usec)
%function [t_x_y sFreq] = Load_pvd(fname ,st_end_time_usec)
% Load a text position file (time, x, y ...). 
% This is a faster way to load than with 'load' or textread.
%
%  INPUT: text file name
%         epochs top load in usec.
%  OUTPUT:
%         matrix of timestamp, xpos,ypos
%         sampling frequency of position data.
%  
% cowen(2006)
if nargin < 2
    st_end_time_usec = [];
end
if exist([fname '.mat'])
    % much faster than the .pvd load.
    load([fname '.mat']);
    return
else
    fid = fopen(fname,'r');
    t_x_y = textscan(fid,'%f%f%f%*[^\n]');
    fclose(fid);
    nRecs = length(t_x_y{3});
    t_x_y = [t_x_y{1}(1:nRecs) t_x_y{2}(1:nRecs) t_x_y{3}(1:nRecs)];
    if ~isempty(st_end_time_usec)
        stix = binsearch(t_x_y(:,1),st_end_time_usec(1));
        edix = binsearch(t_x_y(:,1),st_end_time_usec(2));
        t_x_y = t_x_y(stix:edix,:);
    end
    sFreq = 1/median(diff(t_x_y(:,1))/1e6);
    save([fname '.mat'],'t_x_y','sFreq')
end
%    plot(t_x_y(:,1),t_x_y(:,2));
