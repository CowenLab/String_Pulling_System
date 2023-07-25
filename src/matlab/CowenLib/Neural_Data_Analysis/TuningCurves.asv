function [TC,Occ]= TuningCurves(S, varargin)

% [TC,Occ] = TuningCurves(S, sFreq_pos, X1, b1, X2, b2, X3, b3, ...)
% 
% INPUTS:
%      S -- a cell array of class ts or a single object of class ts
%      REMOVED: sFreq_pos -- the sampling frequency of the position data. Empty if
%            you want TuningCurves to make an estimate. If you are using
%            fragmented time intervals for position data passed into
%            TuingCurves, then be sure to pass in the same sFreq_pos for
%            each condition.
%      Xi, bi -- pairs of class ctsd or tsd (X) & a number (b)
%         Xi = the data along which we are finding the tuning (i.e. head direction "HD"
%              or position along track "V")
%         bi = number of bins in which to separate that dimension 
%              if b is omitted for a dimension, it defaults to 64
% 
% OUTPUTS:
%    TC -- a cell array (if S was a cell array) or a single (if S is one object)
%          n-dimensional matrix of number of spikes occuring at each bin
%    Occ -- Occupancy within each bin (number of frames at which this
%    location entered.
%
%    NOTE: TC is not normalized by default.  To normalize TC, use TC/(Occ + epsilon)
%
% ADR 1998
% version L5.0
% status: PROMOTED
%
% v 4.1 2 nov 1998 now takes out all NaNs.
% v 4.2 17 nov 98 now correctly returns same order of dimensions
% v 5.0 8 dec 99 now uses timestamps from first dim input (X1) for occupancy samples
% v 6 cowen 09 - changed the DT calculation of the sampling rate from mean(diff(t)) to median(diff(t))
%   - mean is too prone to gaps in the position data so I'm using the median.
%   another problem I noticed is if you use lage bin counts (> 200 or so,
%   especially at 800). This gaurantees that the occupancy will get messed
%   up and thus screw up the PF in a major way. I really don't know why
%   there is a problem.

%--------------------
% Unpack inputs
% V = cell array of tsd or ctsd of each dimension
% nV = array of bins for each dimension
%--------------------
vi=1; vc=1;
while vi <= length(varargin)
   V{vc} = varargin{vi};
   if vi+1 <= length(varargin) && isa(varargin{vi+1},'double')
      nV(vc) = varargin{vi+1};
      vi = vi+1;
   else
      nV(vc) = 64;
   end
   vi=vi+1;
   vc=vc+1;
end  

%--------------------
% Size/type checks

if ~isa(S, 'cell')
   S = {S};
end

for iC = 1:length(S)
   if ~isa(S{iC}, 'ts')
      %error(['S{', num2str(iC), '} is not a ts object.'])
      S{iC} = ts(S{iC});
   end
end

%--------------------
% parameters
nCells = length(S);
nD = length(V);

%--------------------
% restrict data to be in range for which we have 
% sufficient data

Tmin = -inf; 
Tmax = inf;
for iV=1:nD
   Tmin = max(Tmin, StartTime(V{iV}));
   Tmax = min(Tmax, EndTime(V{iV}));
end

VR = cell(size(V));
for iV=1:nD
   VR{iV} = Restrict(V{iV}, Tmin, Tmax);
end

SR = cell(size(S));
for iS=1:nCells
   SR{iS} = Restrict(S{iS}, Tmin, Tmax);
end

% get mins & maxes

mV = zeros(size(V)); 
MV = zeros(size(V)); 
for iV=1:nD
   mV(iV) = min(Data(V{iV}));
   MV(iV) = max(Data(V{iV}));
end
timestamps = Range(VR{1}, 'ts'); % Timestamps of all of the position data (not restricted to a cell)
% if isempty(sFreq_pos)
%     sFreq_pos = 10000/median(diff(timestamps));
% end
% prepare output

TC = cell(nCells,1);

%--------------------
% Calculate fields
%--------------------

% foreach cell in the SpikeList
for iC = 1:nCells
   
   spikeTimes = Data(SR{iC});
   
   if isempty(spikeTimes)
      TC{iC} = squeeze(zeros([nV 1]));	% need to add dummy dimension if 1D
   else  
      dataValue = zeros(nD,length(spikeTimes));   % nD x |S{iC}| array for ndhist
      for vd=1:nD
         dataValue(vd,:) = Data(VR{vd}, spikeTimes)';  % VR is restricted V
      end
      [nanRows, nanCols] = find(isnan(dataValue));
      dataValue(:,nanCols) = [];
      TC{iC} = ndhist(dataValue, nV', mV', MV');
      % need to permute TC to return dimensions in correct order
      if (length(nD) > 1)
          TC{iC} = permute(TC{iC}, nD:-1:1);
      end
   end    
end

if length(TC) == 1
   TC = TC{1};
end

%--------------------
% Calculate Occupancy
%--------------------
% Cowen: I am confused regarding how this really gives an accurate measure
% of the time within a bin. It seems to just histogram the number of times
% a particular bin was entered (but not how much time the animal spent in
% the bin - theoretically, the animal could have stopped within the bin and
% stayed there. I guess since the tracker is sampling at a constant rate,
% you have a point for each of the bins so you do know how long the animal
% was in each bin.


dataValue = zeros(nD, length(timestamps)); 
for vd = 1:nD
    % The x, y data for the position data that was passed in.
   dataValue(vd,:) = Data(VR{vd}, timestamps)';
end
[nanRows, nanCols] = find(isnan(dataValue));
dataValue(:,nanCols) = [];

% The number of times each bin was encoutnered.
Occ = ndhist(dataValue, nV', mV', MV');
if (length(nD) > 1)
  Occ = permute(Occ, nD:-1:1);
end
% changed from mean as mean assumes timestamps that are passed in are
% continuous - they often are not if you are restricting the input to
% specific behaviora epochs.
%Occ = Occ * median(diff(timestamps)) / 10000; % normalize for time and convert to seconds (This DT should be typically 30Hz)
%Occ = Occ/sFreq_pos; % normalize for time and convert to seconds (This sFreq should be typically 30Hz)

