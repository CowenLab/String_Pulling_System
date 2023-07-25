fig=figure(1);
axes
axis([0 100 0 100])
hold on
disp('Mark the points with the left mouse button')
disp('Any other button will stop the program')
while 1
[a1,a2,b]=ginput(1);
if b~=1, break,end
plot(a1,a2,'o','MarkerSize',10,'LineWidth',2)
[b1,b2,b]=ginput(1);
if b~=1, break,end
plot(b1,b2,'o','MarkerSize',10,'LineWidth',2)
l1=[a1 a2 b1 b2];
line([l1(1) l1(3)],[l1(2) l1(4)]);
[a1,a2,b]=ginput(1);
if b~=1, break,end
plot(a1,a2,'o','MarkerSize',10,'LineWidth',2)
[b1,b2,b]=ginput(1);
if b~=1, break,end
plot(b1,b2,'o','MarkerSize',10,'LineWidth',2)
l2=[a1 a2 b1 b2];
line([l2(1) l2(3)],[l2(2) l2(4)]);
[x,y]=lineintersect(l1,l2);
h=plot(x,y,'rx','MarkerSize',10,'LineWidth',2);
set(h,'tag','int');
set(findobj('type','line'),'Color',[0 1 0]);
set(findobj('tag','int'),'Color',[1 0 0]);
end