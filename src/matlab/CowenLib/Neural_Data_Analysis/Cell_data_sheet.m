function Cell_data_sheet(S,pos1,pos2,textstr)
%
% Print out the data relevant for Hyper V
% 
% INPUT:
%        S = ts of spike data
%        pos1,pos2 = position data 
%        textstr = string to appear on plot
% OUTPUT:
%        A number of plots(scatterfields, isi, place fields...)
%

% cowen Thu Apr  8 14:53:56 1999
% 

% Check for empty data
if isempty(Data(S))
  title( [textstr ' did not have any spikes'])
  break
end


subplot('position',[.05,.55,.85,.35])
s{1} = S;
% Instead of linearizing everthing, just add up the x and y position
xy = Data(pos1) + (Data(pos2)+400);
newpos = tsd(Range(pos1,'ts'), xy);
SS = ScatterFields(s, newpos);
hold on
plot(Range(pos1,'ts'),Data(newpos))
plot(Range(SS,'ts'),Data(SS),'ro')
title(['Scatter Filds for ' textstr]);
hold off
subplot('position',[.05,.1,.3,.35])

HistISI(S);
subplot('position',[.40,.1,.3,.35])
[TC,Occ] = TuningCurves(s, pos1,30, pos2,30);
%error('');
NTC = Normalize_TC(TC,Occ);
imagesc(NTC,[0 5]);
%colormap(gray)
brighten(.8);

subplot('position',[.75,.1,.1,.35])
[TC,Occ] = TuningCurves(s, newpos,70);
%error('');
NTC = Normalize_TC(TC,Occ);
imagesc(NTC);
%colormap(gray)
brighten(.8);
title('X + Y position');
orient landscape

if nargin == 4
  
end
