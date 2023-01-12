%%% Function to check likelihood values for each digit for each frame 
%%% Changes coordinates to 'NaN' if the likelihood value is below the
%%% threshold

function [digit] = likelihood_check(digit,thresh)
    
    ix=digit(:,3)<thresh;
    digit(ix,1:2)=NaN;
    
end