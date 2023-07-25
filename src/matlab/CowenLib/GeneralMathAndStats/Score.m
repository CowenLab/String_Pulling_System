function s = Score(x,y,d)
% Score matrix for x & y in {1,2,3,4}.
% Mismatch penalty = d.
s =((x==1)'*(y==1)+(x==2)'*(y==2)+(x==3)'*(y==3)...
    +(x==4)'*(y==4))*(1+d) - d;