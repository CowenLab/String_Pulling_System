function [cv, cs, pcv, pcs, tcv, tpcv] = Noise_correlation_Nitz(A,B)
%function [cv cs] = Correlated_variance(A,B)
%
% This is from Nitz and Cargo 2007. It is the 'noise correlation' used in this paper. To
% avoid confusion with other measures of noise correlation, it is called
% Noise_correlation_Nitz
%
% INPUT: 
%      A, B = nTrials x nPositions (or time bins) for two cells (Cell A
%         and Cell B). A and B must be the same size.
%  
% OUTPUT: cv = the correlation between the non-signal variance between cells A and B
%         cs = the correlation between the mean responses of A and B.
%        pcv,pcs = p values of the correlations.
%
%
% Procedure:
%  cv
%    1) subtract mean from each trial (mean for each column, NOT the row)
%    2) correlate these resudials
%  cs
%    1) correlate the mean responses (column mean)
%
% Cowen (2010)
A = Z_Scores(A')';
B = Z_Scores(B')';

m_A = nanmean(A);
m_B = nanmean(B);

%m_A = nanmedian(A); % This may be better given the fact that rates are often not normally distributed
%m_B = nanmedian(B);

%[tmp p] = corrcoef(m_A,m_B); % Correlate the mean responses. W
[tmp, p] = corrcoef(A(:),B(:),'rows','complete'); % Correlate the entire sequence. This is a measure of how reliably the two neurons respond to the signal. 
% This could mean that both neurons (not just one) are strongly driven by the signal because they receive common input.

cs = tmp(2,1);
pcs = p(2,1);

A_dev = A - repmat(m_A,Rows(A),1);
B_dev = B - repmat(m_B,Rows(B),1);

% Get rid of nans... (They screw up corrcoef).
warning off
[tmp, p] = corrcoef(A_dev(:),B_dev(:),'rows','complete'); % The parameters ask corrcoef to ignore the nans.
warning on
% This measures the reliability to which the two neurons both respond to non-signal related information.
%
% A part of me thinks that this is biased by normal statistics. Subtracting
% the mean assumes that the rates follow a normal distribution.
% Imagine if you had some trials with zero rates or high responses. Such a
% more bi-modal distribution would bias the response AWAY from the true
% stimulus response. The noise correlation would thus reflect some of the
% stimulus correlation.

cv = tmp(2,1);
pcv = p(2,1);

if nargout > 4
    %%%%%%%%%%%%%%%%%%%%%
    % But wait, the above assumes that the mean stays the same on each trial (as it
    % merges all trials together). Truth is that the mean could change
    % considerably from trial to trial. (maybe this does not matter)
    %%%%%%%%%%%%%%%%%%%%%
    zA = Z_Scores(A')';
    zB = Z_Scores(B')';
    
    
    for iR=1:Rows(A_v)
        [tmp p] = corrcoef(A_v(iR,:)',B_v(iR,:)','rows','complete');
        tcv(iR) = tmp(2,1);
        tpcv(iR) = p(2,1);
    end

    tcv = nanmean(tcv);
    tpcv = nanmean(tpcv);

end

% Plot it if necessaryl.,
if nargout == 0
    plot(A(:),B(:),'b.',A_dev(:),B_dev(:),'r.');
    xlabel('A')
    xlabel('B')
    legend('signal','noise')
    title('Signal and noise rates')
    lsline
end
