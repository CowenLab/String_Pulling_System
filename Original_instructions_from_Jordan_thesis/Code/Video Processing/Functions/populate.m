%  function to populate the digit arrays
%  inputs: 
%         array to populate
%         column index to read from
%         array of all coordinates from .CSV file
%  outputs:
%         populated digit array
%         column index

function [digit,col] = populate(digit,col,cord)

    
        
        digit(1:end,1) = cord(1:end,col);
        digit(1:end,2) = cord(1:end,col+1);
        digit(1:end,3) = cord(1:end,col+2);
        col=col+3;
    
end