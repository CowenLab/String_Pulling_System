function [LFPout, NANIX] = Repair_LFP(LFP)
% INPUT: LFP where each col is a channel. Nan's indicate blank spots in the
% data.
% OUTPUT: the new LFP with the nan regions filled in.
% NOTE: This does not work if there are many nan's in the data on the other
% channels. Best to set these values to zero at recronstruction time
% perhaps?
%
% This works by performing a multiple linear regression on the data on all
% channels EXCEPT the target channel, getting the coefficients, and then
% reconstructing the missing datapoints.
% Cowen - work in progress (2014). Probably need to use a kalman for such
% things given all of the missing data.
%
LFPout = LFP;
NANIX = false(size(LFP));
for iLFP = 1:Cols(LFP)
    ix = 1:Cols(LFP);
    ix = ix(ix~=iLFP);
    NAN_IX = isnan(LFP(:,iLFP));
    NOTNAN_IX = ~NAN_IX;
    if any(NAN_IX) % if no nan's then there is nothing to fix.
        NANIX(:,iLFP) = NAN_IX;
        mdl = fitlm(LFP(NOTNAN_IX,ix),LFP(NOTNAN_IX,iLFP));
%         mdl = fitlm(LFP(NOTNAN_IX,ix),LFP(NOTNAN_IX,iLFP),'RobustOpts');
%         

% tmp = LFP(NAN_IX,ix);
% tmp(isnan(tmp))=0; % this does not work - zero just makes these vals zero
% at this time.
        LFPout(NAN_IX,iLFP) = predict(mdl,LFP(NAN_IX,ix));
    end
end
% 
sum(isnan(LFPout))

if nargout == 0
    figure
    for iLFP =  1:Cols(LFP)
        subplot(Cols(LFP),1,iLFP)
        plot(LFPout(:,iLFP),'ro-')
        hold on
        plot(LFP(:,iLFP),'.')
    end
end
