function O = plot_pos_from_posextract(fname, start_time)
% Loads the fname (use posextract with the -ascii option and -all options
% in Linux) and plots the pixels on each frame.
% INPUT: The filename of the ascii position file
% OUTPUT: none yet.
% 
% example: plot_pos_from_posextract('C:\Temp\tmp_pos_all.ascii')
%
% Cowen (2008)
FIT_CIRCLE = true;
O = []; tline = []; oldxy = [0 0]; oldcenter = [0 0]; newcenter = [0 0];
fid=fopen(fname,'r');
% Skip the header. 4750609
for ii = 1:114
    tline = fgetl(fid);
end
% optional - skip to a passed in timestmap
if nargin > 1
    tstamp = 0;
    while tstamp < start_time
        tline = fgetl(fid);
        % get the timestmap and first frame digit.
        n = sscanf(tline,'%d:');
        tstamp = n(1);
    end
end
figure
axis([0 400 0 400])
set(gca,'DrawMode','fast')
hold on
box off
axis off
count = 1;
while 1
    tline = fgetl(fid);
    % get the timestmap and first frame digit.
    [n,c,a,i] = sscanf(tline,'%d:');
    tstamp = n(1);
    % get the rest of the data.
    xy = sscanf(tline(i:end),'%d,%d');
    %    if ~ischar(tline), break, end
    if ~isempty(xy)
        plot(oldxy(1:2:end),oldxy(2:2:end),'k.')
        plot(xy(1:2:end),xy(2:2:end),'r.')
        if FIT_CIRCLE
            [newcenter(1), newcenter(2)] = fit_circle(xy(1:2:end), xy(2:2:end), oldcenter(1), oldcenter(2), 4, 10);
            oldcenter = newcenter;
            plot(newcenter(1),newcenter(2),'go')
        end
        %        pause
        oldxy = xy;
        drawnow
        count = count + 1;
        if count == 50
            clf
            axis([0 400 0 400])
            set(gca,'DrawMode','fast')
            hold on
            plot(0,0,'k.')
            box off
            title(tstamp)
            
            count =1;
        end
    end
end
fclose(fid);
