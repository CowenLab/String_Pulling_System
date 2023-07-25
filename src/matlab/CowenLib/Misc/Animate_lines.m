function h = Animate_lines(XY,varargin)
%%
if 0
figure
XY = rand(1000,2);
XY = [];
XY(:,1) = sin(0:.05:60*pi)';
XY(:,2) = cos(0:.05:60*pi)';
XY(:,3) = sin(0:.05:60*pi)'*.6;
XY(:,4) = cos(0:.05:60*pi)'*.5;
end
delay_s = 0.01;
tail_length = 20;
colors = lines(10);
Extract_varargin

clf
plot(XY(1,1),XY(1,2),'ro')
hold on
tail_count = 1;
start_erasing = false;
h = [];
col_starts = 1:2:(Cols(XY)-1);
for iR = 1:Rows(XY)
   
   for iXY = 1:length(col_starts)
       st = col_starts(iXY);
       xy = XY(iR,st:st+1);
       h(tail_count,iXY) = plot(xy(1),xy(2),'.','Color', colors(iXY,:));
       pause(delay_s)
   end
   rw(tail_count) = iR;
   tail_count = tail_count + 1;
   drawnow

   if start_erasing
       [~,ix] = min(rw);
       set(h(ix,:),'Color',[.8 .8 .8])
   end
   if tail_count > tail_length
       tail_count = 1;
       start_erasing = true;
   end
   
end
