function [peak_half_width, peak_to_trough] = Spike_width(WV,precision_multiplier)
%function [peak_half_width, peak_to_trough] = Spike_width(WV,precision_multiplier)
% INPUT
%
%   nWaveforms x nPoints : a matrix of waveforms with each row
%     corresponding to a waveform.
%   precision_multiplier - how many times more precise than the passed in
%     data do you want the input data to be resampled to generate the output data.
%     for instance, if the waveforms are 32 points, a precision_multiplier of 10 should up it to 
%     320 points. A spline filter is applied to interpolate the waveform.
%
% OUTPUT:
%   peak_half_width - width (in data points passed in) of the peak at
%     1/2 its height.
%   peak_to_trough - the time from the peak to the trough.
%
%  If NO output is specified, a plot with diagostic points is presented for
%  verification.
%
% NOTE: THIS CODE SEEMS MESSED UP AT THE LINE THAT ASSIGNES half2 = 5. In
% general, it work's OK but before believing all of the results, run the
% program without any ouputs so that a diagnostic plot is created. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AUTHORS:
%   Laura Wright, her engineering friend and Stephen Cowen 2006
%   (stephen.cowen@yahoo.com)
%    updated with some corrections from the Euston lab in 2010.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin <2
    precision_multiplier = 50;
end
if nargout ==0
    figure
end
half1 = nan;
left_half = nan;
startx = nan;
[nWaves,nPoints] = size(WV);
peak_half_width  = zeros(nWaves,1)*nan;
peak_to_trough   = zeros(nWaves,1)*nan;
new_range = linspace(1,nPoints,nPoints*precision_multiplier); % The new precision is 50 times that
for iW = 1:nWaves
    %this for loop brings the r_th row of the CI.MeanWaveform into a new vector
    waveform = WV(iW,:);

    % This IF makes sure that only actual data vectors are worked on and graphed
    % ~= means does not equal.. so as long as the program doesn't see a vector
    % full of just 0's the program will continue
    if sum(waveform) ~= 0 && ~isnan(sum(waveform))
        %smooth with spline
        new_waveform = spline(1:nPoints, waveform, new_range);

        % find global max and min in new wave form.
        %mx and mn are y values and the idx's are the corresponding element number(not value) in the
        % x axis vector called "new_range"
        [mx, mx_idx] = max(new_waveform);
        %  [mn, mn_idx]=min(new_waveform);


        % So here is the deal with the negative peak durations... it happens
        % whenever your min value occured before your max in time
        % if that is ok, then just put the letters infront of the
        % mn_idx-mx_idx statement later on when you calculate width... if
        % the min has to come after the max in time then you just need to
        % change the previous line of code to read
        [mn_before, mn_before_idx]= min(new_waveform(1:mx_idx));
        [mn_after,  mn_after_idx] = min(new_waveform(mx_idx:end));
        mn_after_idx = mn_after_idx + mx_idx - 1;
        %Start at real base of waveform rather than 0
        %make sure to start at correct start site::: not 0

        [starty startx]=min(new_waveform(1:mn_before_idx));
        startx = startx(1); % in case more than one min
        for i=2:length(new_range)-1
            deriv(i)= (new_waveform(i+1)-new_waveform(i-1))/(new_range(i+1)-new_range(i-1));
        end

        %big giant check to make sure you are starting in the right place

        %first part resets min to the last min before a positive slope goes all the
        %way to the max

        for i=startx:(.5*mx_idx)
            if deriv(i)<0
                starty=new_waveform(i);
            end


            % this next part is to account for slow shallow positive slopes leading up to the
            % obvious start of the activity.
            if mean(deriv(i:i+10))<3   %the 10 is totally arbitrary..
                starty=new_waveform(i+5);   %so is the 5  .. may need to change these
            end
        end

        for i=1:length(new_range)
            if new_waveform(i)==starty
                startx=i;
            end
        end


        % Find width.  Starting from 0 to the max, first make sure that there isn't accidentally a
        % perfect data point where new_waveform = 1/2 of the max of new_waveform
        for k=1:mx_idx
            if new_waveform(k)==(mx+starty)/2
                left_half=k;
            end

            % now find the last data point in new_waveform that is less than half of the
            % max and call it half1
            if new_waveform(k)<(mx+starty)/2
                half1=k;
            end
        end
        if isnan(half1)
            peak_half_width(iW) = nan;
            peak_to_trough(iW) = nan;
        else
            % Linear Interpolation.  the y=mx+b form is solved for x
            % and is in the form y-b/m=x. .
            yminusb = (mx+starty)/2-new_waveform(half1);
            m=(new_waveform(half1+1)-new_waveform(half1))/.01;

            %create the data point for the left half max x value
            % note that you have to add the interpolated value (yminusb/m) to the x
            % value of the previous data point
            left_half=yminusb/m + new_range(half1);

            %Repeat the exact same thing for the data to the right of the max
            for i=mx_idx:mn_after_idx
                if new_waveform(i)==(mx+starty)/2
                    right_half=i;
                end
                if new_waveform(i)>(mx+starty)/2
                    half2=i;
%                 else
%                     half2=5;
                end
            end

            %Linear Interpolation
            yminusb2=(mx+starty)/2-new_waveform(half2-1);
            m2=(new_waveform(half2)-new_waveform(half2-1))/.01;

            %Create the data point for right half max x value as before
            right_half=yminusb2/m2 + new_range(half2);
            
            if right_half > new_range(mn_after_idx)
                right_half = new_range(half2);
            end

            %Calculate width at half maximal height of waveform
            peak_half_width(iW)=right_half-left_half;

            %max height to min height ratio absolute value
            peak_to_trough(iW) = new_range(mn_after_idx)-new_range(mx_idx);
            % This plots each new row as its own subplot.  The 2,2 means that
            % the program expects slots for 4 graphs in one figure and the r is the
            % row from the first for loop, meaning it will only add as many graphs
            % as rows that made it past the first if statement.
            if nargout ==0
                clf
                %subplot(ceil(nWaves/2),2,iW)
                plot(1:nPoints,waveform,'k-')
                hold on
                plot(new_range,new_waveform,'r')
                plot(new_range(startx),starty,'bl+')
                % sure start is reasonable if there is a queston
                plot (new_range(mx_idx), mx, 'm*')
                plot (new_range(mn_after_idx), mn_after, 'm*')
               % plot(8 - peak_half_width(iW)/2 ,(mx)/2,'c+') 
               % plot(8 + peak_half_width(iW)/2 ,(mx)/2,'c+') 
                plot (right_half,(mx+starty)/2 , 'g<')
                plot (left_half,(mx+starty)/2,'g>')
                title('PRESS SPACEBAR')
                pause
            end
        end
    end  %ends the original if statement
end  %ends the original for loop

