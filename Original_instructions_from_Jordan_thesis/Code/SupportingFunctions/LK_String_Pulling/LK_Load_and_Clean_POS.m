function [POS] = LK_Load_and_Clean_POS(fname)
if nargin < 1
    fname = 'POS.mat';
end

load(fname);
diff_thresh = 20;
BIX = POS.Red_xy(:,1) < 50 | POS.Red_xy(:,2) < 40 | POS.Red_xy(:,1) > 550 | POS.Red_xy(:,2) > 350;
POS.Red_xy(BIX,:) = nan;
BIX = POS.Green_xy(:,1) < 50 | POS.Green_xy(:,2) < 40 | POS.Green_xy(:,1) > 550 | POS.Green_xy(:,2) > 350;
POS.Green_xy(BIX,:) = nan;
%%
P = [POS.Red_xy POS.Green_xy];
Porig = P;
for iC = 1:Cols(P)   
    BIX2 = true(size(BIX));
    ABIX = false(size(BIX));
    while(sum(BIX2)> 10)
        d = abs([0;diff(P(:,iC))]);
        BIX2 = d > diff_thresh;
        ABIX = BIX2 | ABIX;
%         sum(BIX2)
        P(BIX2,iC) = nan;
    end
    P(:,iC) = movmedian(P(:,iC),4,'omitnan');
    GIX = ~isnan(P(:,iC));
    P2 = conv_filter(P(:,iC),hanning(9)/sum(hanning(9)));
    GIX2 = ~isnan(P2);
    P2(GIX & ~GIX2) = P(GIX & ~GIX2,iC);
    P(:,iC) = P2;
    
end

% for ii = 1:4
%     figure
%     plot(Porig(:,ii))
%     hold on
%     plot(P(:,ii))
% end

% Green tends to be more reliable if present. If there is no green, then go
% with red.
% This was clever: create a model whereby red predicts green. Then this
% allowos you to fill in missing green data with red's prediction and
% because it has an intercept and slope, it corrects for offsets.
POS.xy = double(P(:,3:4));
mod = fitlm(P(:,1), P(:,3)); 
pred_x = predict(mod,P(:,1));
mod = fitlm(P(:,2), P(:,4)); 
pred_y = predict(mod,P(:,2));
BIX = isnan(POS.xy(:,1));
POS.xy(BIX,1) = pred_x(BIX);
BIX = isnan(POS.xy(:,2));
POS.xy(BIX,2) = pred_y(BIX);

POS.speed = Speed_from_xy([POS.Time_uS/1e6 POS.xy]);
POS.speed(POS.speed > 200) = nan; % no rat moves that fast...

if nargout == 0
    figure
    plot(POS.Time_uS/60e6,POS.Speed_Green,'g')
    hold on
    plot(POS.Time_uS/60e6,POS.Speed_Red,'r')
    yyaxis right
    plot(POS.Time_uS/60e6,POS.speed,'k')

    figure
    plot(POS.Time_uS/60e6,POS.Red_xy)
    title('red')
    
    figure
    plot(POS.Time_uS/60e6,POS.Green_xy(:,1),'g')
    hold on
    plot(POS.Time_uS/60e6,POS.Red_xy(:,1),'r')

    plot(POS.Time_uS/60e6,POS.xy(:,1),'k')
    
    title('')
    
    figure
    % subplot(2,2,1)
    plot(POS.Red_xy(:,1),POS.Red_xy(:,2),'r.','MarkerSize',1)
    hold on
    plot(POS.Green_xy(:,1),POS.Green_xy(:,2),'g.','MarkerSize',1)
    plot(POS.xy(:,1),POS.xy(:,2),'b.','MarkerSize',1)
end