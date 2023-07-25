function O = pos_and_head_ang_from_posextract(fname, time_range)
% Loads the fname (use posextract with the -ascii option and -all options
% in Linux) and plots the pixels on each frame.
% First pass - get a center by fitting a circle to the points. 
% Second pass - find jumps that indicate bad data. Ignore these points and
%  re-interpolate the data.
% Third pass - fit a regression line to the points around a localized circle to the determined mean.
%  The beta value of the line should be equivalent to the head angle.
% INPUT: The filename of the ascii position file
% OUTPUT: none yet.
% 
% example: plot_pos_from_posextract('C:\Temp\tmp_pos_all.ascii')
%
% Cowen (2008)
PLOT_IT = true;
if nargin < 2
    time_range = [0 inf];
end
buffer_pts = 200000;
circ_rad = 4;
jump_size = 20; % distance in pixels that is considered to be a jump.
O = []; tline = []; oldxy = [0; 0];oldang = 0; oldcenter = [0 0]; newcenter = [0 0];
fid=fopen(fname,'r');
% Skip the header. 4750609
for ii = 1:114
    tline = fgetl(fid);
end
% optional - skip to a passed in timestmap
tstamp = 0;
while tstamp < time_range(1)
    tline = fgetl(fid);
    % get the timestmap and first frame digit.
    n = sscanf(tline,'%d:');
    tstamp = n(1);
end
if PLOT_IT
    
    axis([0 400 0 400])
    set(gca,'DrawMode','fast')
    hold on
    box off
    a1 = gca;
    a2 = axes('Position', [.8 .8 .14 .14])
end
% Get all of the points

count = 1;
tstamp = zeros(buffer_pts,1)*nan; % reserve some space.
circ_centers = zeros(buffer_pts,2)*nan;
ang = zeros(buffer_pts,1); 
n = 0;
while time_range(2) > n(1)
    tline = fgetl(fid);
    if tline == -1
        break
    end
    % get the timestmap and first frame digit.
    [n,c,a,i] = sscanf(tline,'%d:');
    tstamp(count) = n(1);
    % get the rest of the data.
    xy = sscanf(tline(i:end),'%d,%d');
    if ~isempty(xy)
        [newcenter(1), newcenter(2)] = fit_circle(xy(1:2:end), xy(2:2:end), oldcenter(1), oldcenter(2), circ_rad, 10);
        circ_centers(count,:) = newcenter;
        oldcenter = newcenter;
        if length(xy) > 6
            %b = robustfit(xy(1:2:end), xy(2:2:end));
            %p = polyfit(xy(1:2:end), xy(2:2:end),1); %seems to work as well as robust fit and a little faster.
            p = polyfit([xy(1:2:end); oldxy(1:2:end) ], [xy(2:2:end) ;oldxy(2:2:end) ],1); %seems to work as well as robust fit and a little faster.
            % Draw a line that intersects this line and the center of mass.
            ang(count) = -1/(p(1)); % slope of line perpendicular is negative of reciprocal.
            %ang2 = atan2(circ_centers(2) + circ_centers(2)*p(1),0);
            ang2 = atan(ang(count))*2;
            % Find the intersection between the center and the line.
            % compute the angle between these two points with the center
            % point always being the first.
            
        else
            ang(count) = nan;
        end
        %        plot
        if PLOT_IT
            axes(a1)
            if mod(count,50) == 0
                cla
            end
            plot(oldxy(1:2:end),oldxy(2:2:end),'k.')
            plot(xy(1:2:end),xy(2:2:end),'r.')
            draw_circle(newcenter,circ_rad,10,'-g');
%            plot(newcenter(1),newcenter(2),'go')%
            if ~isnan(ang(count))
                plot([newcenter(1) newcenter(1) + 30] ,[newcenter(2) newcenter(2) + 30*ang(count)],'c')
                %plot([newcenter(1) newcenter(1) + 30] ,[newcenter(2) newcenter(2) + 30*ang2],'m')
            end
            axes(a2)
            if mod(count,50) == 0
                cla
            end
            polar([oldang oldang],[0 1],'k')
            hold on
            polar([ang2 ang2],[0 1])
            
            drawnow
        end
        oldxy = xy;
        oldang = ang2;
    end
    count = count + 1;
end
fclose(fid);
% return the centers.
goodtimes = find(~isnan(tstamp));
tstamp    = tstamp(goodtimes);
circ_centers = circ_centers(goodtimes,:);
% interp over the ambiguous points.
goodix = find(~isnan(circ_centers(:,1)));
badix  = find(isnan(circ_centers(:,1)));

[circ_centers(badix,1)] = interp1(tstamp(goodix),circ_centers(goodix,1),tstamp(badix),'spline');
[circ_centers(badix,2)] = interp1(tstamp(goodix),circ_centers(goodix,2),tstamp(badix),'spline');

O = zeros(length(tstamp),3);
O(:,1) = tstamp;
O(:,2:3) = circ_centers;
