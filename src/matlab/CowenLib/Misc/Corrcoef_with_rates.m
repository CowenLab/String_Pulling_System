function [C, Rates, P, IJ] = Corrcoef_with_rates(STM, binsize_sec)
%function [C, Rates, P, IJ] = Corrcoef_with_rates(STM, binsize_sec)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the coorcoef but also return the firing rates, indices into the
% original R matrix and the p value of each correlation. Only the upper
% diagonal is returned as this is all that really matters. 
%
% Cowen 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[RV, P] = corrcoef(STM);
T = triu(ones(Cols(STM),Cols(STM)),1);
IX = T==1;
C = RV(IX);
if nargout > 1
    if nargin < 2
        disp('No binsize specified. Assuming a size of 1second')
        binsize_sec = 1;
    end
    P = P(IX);
    [i,j] = ind2sub(size(RV),find(T==1));

    rates = sum(STM)/(Rows(STM)*binsize_sec);
    Rates = zeros(Rows(C),2);
    IJ = zeros(Rows(C),2);

    Rates(:,1) = rates(i);
    Rates(:,2) = rates(j);
    IJ(:,1) = i;
    IJ(:,2) = j;
end
