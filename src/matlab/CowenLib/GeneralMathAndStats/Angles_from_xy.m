function [ang ang_chg] = Angles_from_xy(txy)
dt = diff(txy(:,1));
dx = diff(txy(:,2)); 
dy = diff(txy(:,3)); 
ang = atan2(dy,dx); % The angle at each point as he runs into the circle.
ang_chg = [0;diff(ang)]./dt;

ang = [0;ang];
ang_chg = [0;ang_chg];