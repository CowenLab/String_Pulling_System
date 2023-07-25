function INTAN_Plot_Position_And_Events(POS,EVENTS)
%Same code as AMPX version (Cowen 20XX) but a local copy in case this 
%code moves and that code doesn't.

u = unique(EVENTS(:,2));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean up the pos data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
P = POS(POS(:,2) > 10,:);
SF = cell(length(u),1);
for iEvt = 1:length(u)
    %
    IX = EVENTS(:,2) == u(iEvt);
    nEvents(iEvt) = sum(IX);
    [SF{iEvt}] = ScatterFields_cowen(P, EVENTS(IX,1));
    %
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the events.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cla
plot(P(:,2),P(:,3),'k.')
hold on
colors = jet(length(u));
for iEvt = 1:length(u)
    if isempty(SF{iEvt})
        disp('Empty Event')
        u(iEvt)
    else
        plot(SF{iEvt}(:,2),SF{iEvt}(:,3),'.','Color',colors(iEvt,:));
        if size(SF{iEvt},1) > 1
            xy = nanmean(SF{iEvt}(:,2:3));
        else
            xy = SF{iEvt}(:,2:3);
        end
        text(xy(1),xy(2),num2str(u(iEvt)),'Color',colors(iEvt,:),'BackgroundColor',[.7 .7 .7])
    end
end
