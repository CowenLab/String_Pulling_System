function O = interp1_matrix(x,Y,newx,method)
% function O = interp1_matrix(x,Y,newx,method);
% uses the matlab interp1 function to interp1 an entire matrix by column or
% if the user passes in 'nearest', just find the col that is closest to the
% target and use that..
%
% Cowen
O = [];
if nargin < 4
    method = 'linear';
end
if strcmpi(method,'nearest')
    O = zeros(Rows(Y),length(newx))*nan;
    for iF = 1:length(newx)
        ix = Closest(x,newx(iF));
        O(:,iF) = Y(:,ix);
    end
    return
end
warning off
for iC = 1:Cols(Y)
    if sum(isnan(Y(:,iC)))/Rows(Y) < 0.7
        % if > 70% oof teh data are nans, then don't bother.
        if iC == 1
            o = interp1(x,Y(:,1),newx,method,'extrap');
            O = zeros(length(o),Cols(Y))*nan;
            O(:,iC) = o(:);
        else
            O(:,iC) = interp1(x,Y(:,iC),newx,method,'extrap');
        end
    end
end
warning on