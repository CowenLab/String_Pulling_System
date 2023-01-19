% Function calculates moving median based on previously filtered
% datapoints. Only values with good likelihoods are used in calculation
% Inputs are  complete digit x-y-l matrices and pixel threshold for
% filtering

function [digit] = medifilt(digit,thresh,win_size)
len=size(digit);
len=len(1);
med = NaN(len,1);


for i=1:1:2
    med = movmedian(digit(1:len,i),[win_size 0],'omitNaN');
    %med = movmedian(digit(1:len,i),win_size,'omitNaN');
    
    ix=(digit(:,i)-med)>thresh;
    
    digit(ix,1)=NaN;
    digit(ix,2)=NaN;
    
end
end