function [d]=cliffs_delta(x,y)

%Crown 6/2019
% From this website- its supposidly the probability of x being greater than
% y - the probablity of y being greater than x
%values can range between -1 and 1.
% https://garstats.wordpress.com/2016/05/02/robust-effect-sizes-for-2-independent-groups/
%When I put calculated this with sample data I got 0.41 and when I put it in R using clisffs.delta it gave me 0.3325918 (medium)
%the two aren't the same but they are close? This will change a little each
%time because its bootstrapping
%the point of a lot of this too is to work with unequal sample sizes

%later I found some OTHER code called Cliffs_delta in our working folder
%but it gave .11.....so I'm inclined to go with this since its closest to
%R?
nitter=10000; %because why  not?


x=x(~isnan(x));
y=y(~isnan(y));

for iv=1:nitter
rx=randperm(length(x),1);
ry=randperm(length(y),1);
v(iv)=x(rx)> y(ry);
end
p1=mean(v);

for iv=1:nitter
rx=randperm(length(x),1);
ry=randperm(length(y),1);
v(iv)=x(rx)< y(ry);
end
p2=mean(v);

d=p1-p2;