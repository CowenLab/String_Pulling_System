%function [Xcleaned, Ycleaned]=CleanTrackerData(X,Y)
%
%this function cleans up obvious outliers in the tracker data
%inputs: X and Y are tsd derived from VT_Raw1.ascii files using
%LoadPosition in ~adr/matlab/nsma
%outputs: X and Y tsd positional info without outliers

% ekstrom

function [Xcleaned, Ycleaned]=CleanTrackerData(X,Y)

XData=Data(X);
Ycleaned = [];
Xcleaned = [];

if nargin == 1
  dist=sqrt(diff(XData).^2);
else 
  YData=Data(Y);
  dist=sqrt(diff(XData).^2+diff(YData).^2);
end  


meandist=mean(dist);
stddist=std(dist);

%%%%% modify below but this number works well for me %%%%%%%

cut=meandist+3*stddist;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

index=find(dist<cut);
times=Range(X,'ts');
Xcleaned=tsd(times(index),XData(index));

if nargin == 2
  Ycleaned=tsd(times(index),YData(index));
end

