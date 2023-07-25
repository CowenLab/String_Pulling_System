function I = Interval_detection(input_intervals,nSamples)
% detect the intervals NOT INCLUDED in the input_intervals n x 2 matrix. 
% nSamples is the total number of samples in the original data.
if nargout ==0
    IN = [2 3 ;10 12; 15 19]
    IN = [1 3 ;10 12; 15 19]
    A = Interval_detection(IN,19)
end
I = [];
if isempty(input_intervals)
    I=[1 nSamples];
else
    if input_intervals(1,1) > 1 
        I(:,1) = [1; input_intervals(:,2)];
        I(:,2) = [input_intervals(:,1); nSamples];
    elseif input_intervals(1,1) < 2 
        I(:,1) = [input_intervals(:,2)];
        I(:,2) = [input_intervals(2:end,1); nSamples];
    end
    
    if input_intervals(end,2) == nSamples
        I(end,:) = [];
    end
    
end
