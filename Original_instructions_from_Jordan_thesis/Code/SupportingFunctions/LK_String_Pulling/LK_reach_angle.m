function [ang,x,y,d] = LK_reach_angle(TXY, se, varargin)
% function [ang,x,y,d] = LK_reach_angle(TXY, se, varargin)
% TXY = 3 col matrix of time, x, y of paw
% se = 2 col matrix of start and end time of each pull. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cowen 2020.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
plot_it = false;
Color = lines(1);

Extract_varargin;

stix = dsearchn(TXY(:,1),se(:,1));
edix = dsearchn(TXY(:,1),se(:,2));
x = TXY(edix,2) - TXY(stix,2);
y = TXY(edix,3) - TXY(stix,3);
ang = atan2(y,x);
d = sqrt(x.^2 + y.^2);

if plot_it
    subplot(2,2,1)
    for iPull = 1:length(stix)
        xx = TXY(stix(iPull):edix(iPull),2) - TXY(stix(iPull),2);
        yy = TXY(stix(iPull):edix(iPull),3) - TXY(stix(iPull),3);
        plot(zeros(size(xx)),zeros(size(xx)), xx,yy,'Color',Color);
        hold on
    end
    
    subplot(2,2,2)
    h = histogram(d,'FaceColor',Color,'EdgeColor',Color); h.FaceAlpha = .1; h.LineWidth = 2
    xlabel('Dist')
    hold on
    
    subplot(2,2,3)
    h = polarhistogram(ang,'FaceColor',Color,'EdgeColor',Color); h.FaceAlpha = .1; 
        h.DisplayStyle = 'stairs'; h.LineWidth = 4;
    hold on
    
    subplot(2,2,4)
    plot(TXY(stix(1):edix(end),1)/60e6, TXY(stix(1):edix(end),2),'.','Color',[.4 .5 .7])
    hold on
    plot(TXY(stix(1):edix(end),1)/60e6, TXY(stix(1):edix(end),3),'.','Color',[.4 .4 .4])
    xlabel('min')
end



% function ang = Angs(x0,y0,x1,y1)
% x10 = x1-x0;
% y10 = y1-y0;
% x20 = x2-x0;
% y20 = y2-y0;
% ang = atan2(abs(x10*y20-x20*y10),x10*y10+x20*y20);
% end