function POS_out = Clean_position_data(POS, frame_size, x_y_min)
%%
%function POS_out = Clean_position_data(POS, frame_size)
%
% Cleans posiiton data by performing a median filter to get rid of
% non-linear jumps and then applying a low order polynomial filter to
% smooth over the small jitter in the signal.
% INPUT: POS - 3 col matrix of time, xpos, ypos
%        frame_size - size of the sliding window that smoothes the data.
%    NOTE: Frame size should be odd
%
% OUTPUT: a smoothed version of POS.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2010
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    frame_size = 15; % 15 seems to work well, cleans up spiky stuff, but use 19 for really bad jitter.
end
if nargin < 3
    x_y_min = [3 3]; % points less than these values will be eliminated.
end
POS_out = POS; % sortrows because some records are just messed up.
% Look for non-ascending timestmaps.
d = [1; diff(POS_out(:,1))];
%ix = find(d > 10000);
POS_out(d > 50000,:) = [];
d = [1; diff(POS_out(:,1))];
POS_out(d > 50000,:) = [];
POS_out = sortrows(POS_out,1);

% Now find the blocks of data: If there are gaps in the position data


% Get rid of bad data.
badIX = POS_out(:,2)<=x_y_min(1) | POS_out(:,3)<=x_y_min(2);

%POS_out(badIX,2:3) = -100; % don't make them nans as it will screw up medfilt.
% POS_out(:,2) = medfilt1(POS_out(:,2),frame_size);
% POS_out(:,3) = medfilt1(POS_out(:,3),frame_size);
%
badIX  = POS_out(:,2) <=x_y_min(1) | POS_out(:,3)<=x_y_min(2) | isnan(POS_out(:,2) + POS_out(:,3));
goodIX = POS_out(:,2) > x_y_min(1) & POS_out(:,3)>x_y_min(2);
%
ix = find(goodIX,1,'first');
badIX(1:ix) = false; % Dont bother interpolating bad records that occur before the first good record.
ix = find(goodIX,1,'last');
badIX(ix:length(goodIX)) = false; % Dont bother interpolating bad records at the end of the dataset either
% Don't bother interpolating blocks of data where a contiguous block of >
% 30 records is missing.
n_th = 30;
count = 1;
cum_count = zeros(size(badIX));
run_IX = zeros(size(badIX));

for ii =1:length(badIX)
    if badIX(ii)
        count = count + 1;
    else
        found_start = false;
        count = 0;
    end
    cum_count(ii) = count;
    
    if count > n_th-1
        
        ix = ii - (n_th-1);
        run_IX(ix:ii) = 1;
    end
end


% Fill in the missing pieces.
% SPLINE is necessary because you can have blocks of bad recs and then you
% just get striaight lines in these blocks which can pass lap boundaries.
%POS_out(badIX,2) = interp1(POS_out(goodIX,1),POS_out(goodIX,2),POS_out(badIX,1),'spline');
%POS_out(badIX,3) = interp1(POS_out(goodIX,1),POS_out(goodIX,3),POS_out(badIX,1),'spline');
if sum(goodIX) > 10
    POS_out(badIX,2) = interp1(POS_out(goodIX,1),POS_out(goodIX,2),POS_out(badIX,1));
    POS_out(badIX,3) = interp1(POS_out(goodIX,1),POS_out(goodIX,3),POS_out(badIX,1));
    POS_out(POS_out(:,2)>400,:) = [];
    POS_out(POS_out(:,3)>400,:) = [];
    POS_out(POS_out(:,2)<1,:) = [];
    POS_out(POS_out(:,3)<1,:) = [];
    
    % Get rid of litte spikes (I do this at the end). Make sure that there are
    % no nan's in the data - that screws up medfilt.
    POS_out(:,2) = medfilt1(POS_out(:,2),frame_size);
    POS_out(:,3) = medfilt1(POS_out(:,3),frame_size);
    
    POS_out(isnan(POS_out(:,2)),:) = [];
    
end

% Now smooth with a 3rd order polynomial.
% POS_out(:,2) = sgolayfilt(POS_out(:,2),3,frame_size);
% POS_out(:,3) = sgolayfilt(POS_out(:,3),3,frame_size);

if nargout == 0
    % Plot the data if no output argument is supplied.
    figure
    subplot(2,1,1)
    plot(POS(:,2),POS(:,3),'.','MarkerSize',1)
    hold on
    %plot(POS_out(:,1),run_IX*200,'k')
    plot(POS_out(:,2),POS_out(:,3),'r-')
    
    subplot(2,1,2)
    plot(POS(:,1),POS(:,2),'.-')
    hold on
    %plot(POS_out(:,1),run_IX*200,'k')
    plot(POS_out(:,1),POS_out(:,2),'r.-')
    legend('original','smoothed')
end
