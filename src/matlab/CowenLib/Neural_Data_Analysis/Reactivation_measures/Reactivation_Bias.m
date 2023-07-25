function [OUT] = Reactivation_Bias(S, STM_maze, binsize_maze_ms, units_of_S)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WORK IN PROGRESS
% I did a test with simulated data and ReactCOM seems to work while the
% ReactBias does not.
%
% function [OUT, P] = Reactivation_Bias(S)
% The temporal bias measure of reactivation.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% S = 3 element cell array (rest 1, maze, rest 2).
% be sure to restrict S in each epoch to the periods of time that you wish
% to analyze (for example - get rid of slow movement during maze running or
% inter-ripple periods during rest).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4
    units_of_S = '.1ms';
end
switch units_of_S
    case 'usec'
        for ii = 1:length(S)
            for jj = 1:length(S{ii})
                S{ii}{jj} = S{ii}{jj}/100;
            end
        end
    case '.1ms'
        % do nothing
    otherwise
        error('wroing time units')
end


bin_step_xcorr_ms = 5; % From Gerrard 2008
xcorr_window_rest_ms = 40;  % It would seem that the window for rest should be smaller than maze given compression. 200 is what was used in gerrard
xcorr_window_maze_ms = 100;  % From Gerrard 2008
winsize_bins_rest = 2*xcorr_window_rest_ms/bin_step_xcorr_ms;
winsize_bins_maze = 2*xcorr_window_maze_ms/bin_step_xcorr_ms;

OUT.xcorr_window_rest_ms = xcorr_window_rest_ms;
OUT.xcorr_window_maze_ms = xcorr_window_maze_ms;
OUT.bin_step_xcorr_ms = bin_step_xcorr_ms;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine significant correlations on the maze using a large bin size. Only
% look at these during rest as no sense looking at uncorrelated cells
% during behavior other than as controls.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do corrcoef
% identify significant correlations. No point in playing with insignificant
% correlations.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[R, Fr, P, IJ] = Corrcoef_with_rates(STM_maze,binsize_maze_ms/1000);
BADIX = P > 0.05;
% Remove cells that do not fire.
for iCell = 1:length(S{1})
    for iEp = 1:3
        nSpks(iCell,iEp) = length(S{iEp}{iCell});
    end
end

R = R(~BADIX,:); P = P(~BADIX,:); Fr = Fr(~BADIX,:,:);IJ = IJ(~BADIX,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% using these correlations, compute the xcorr in pre and post sleep for
% these significant pairs.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CC{1} = zeros(Rows(IJ),2*winsize_bins_rest + 1)*nan;
CC{3} = zeros(Rows(IJ),2*winsize_bins_rest + 1)*nan;
CC{2} = zeros(Rows(IJ),2*winsize_bins_maze + 1)*nan;

for ii = 1:Rows(IJ)
    a = IJ(ii,1);
    b = IJ(ii,2);
    % rest
    if nSpks(a,1) > 2 && nSpks(b,1) > 2
        CC{1}(ii,:) = CrossCorr(S{1}{a},S{1}{b},bin_step_xcorr_ms*10,2*winsize_bins_rest)';
    end
    if nSpks(a,3) > 2 && nSpks(b,3) > 2
        CC{3}(ii,:) = CrossCorr(S{3}{a},S{3}{b},bin_step_xcorr_ms*10,2*winsize_bins_rest)';
    end
    % maze
    if nSpks(a,2) > 2 && nSpks(b,2) > 2
        CC{2}(ii,:) = CrossCorr(S{2}{a},S{2}{b},bin_step_xcorr_ms*10,2*winsize_bins_maze)';
    end
end
% If there are no spike counts
for ii = 1:3
    IX = sum(CC{ii},2) < 2; % don't bother computing a number here - just will add noise to the system.
    CC{ii}(IX) = nan;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% with these xcorrs, copute a bias measure for each xcorr.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mid_ix_rest = floor(Cols(CC{1})/2)+ 1 ;
bef_ix_rest =1:(mid_ix_rest-1);
aft_ix_rest =(mid_ix_rest+1):Cols(CC{1});

mid_ix_maze = floor(Cols(CC{2})/2)+ 1 ;
bef_ix_maze =1:(mid_ix_maze-1);
aft_ix_maze =(mid_ix_maze+1):Cols(CC{2});

Bias = zeros(Rows(CC{1}),3)*nan;
normBias = zeros(Rows(CC{1}),3)*nan;
COM = zeros(Rows(CC{1}),3)*nan;
% rest
bef = nansum(CC{1}(:,bef_ix_rest),2);
aft = nansum(CC{1}(:,aft_ix_rest),2);
Bias(:,1) = aft-bef;

normBias(:,1) = (aft-bef)./(bef+aft);
ix = [bef_ix_rest aft_ix_rest ] ;
top = CC{1}(:,ix).*repmat(ix-mid_ix_rest,Rows(CC{1}),1);
COM(:,1) = nansum(top,2)./(nansum(CC{1}(:,ix),2));


bef = nansum(CC{3}(:,bef_ix_rest),2);
aft = nansum(CC{3}(:,aft_ix_rest),2);
Bias(:,3) = aft-bef;
normBias(:,3) = (aft-bef)./(bef+aft);
top = CC{3}(:,ix).*repmat(ix-mid_ix_rest,Rows(CC{3}),1);
COM(:,3) = nansum(top,2)./(nansum(CC{3}(:,ix),2));


% maze
bef = nansum(CC{2}(:,bef_ix_maze),2);
aft = nansum(CC{2}(:,aft_ix_maze),2);
ix = [bef_ix_maze aft_ix_maze ];

Bias(:,2) = aft-bef;
normBias(:,2) = (aft-bef)./(bef+aft);
top = CC{2}(:,ix).*repmat(ix-mid_ix_maze,Rows(CC{2}),1);
COM(:,2) = nansum(top,2)./(nansum(CC{2}(:,ix),2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compare the vector of biases using the standard parital correlation
% method used for EV analyses.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BADIX = isnan(sum(Bias,2));
Bias = Bias(~BADIX,:);
if Rows(Bias) < 20
    OUT = []; P = [];
    disp('not enought comparisons')
    return
end
% Compute the similarity between epochs
OUT.reactivation_strength = nan;
OUT.Bias = Bias;
OUT.normBias = normBias;
OUT.COM = COM;

GOODIX = ~isnan(sum(Bias,2));
% Simple measure - number of hits in the same direction

if sum(GOODIX) < 50 % From Gerrard 2008
    disp('not enough comparisons')
    OUT.ReactCOM  = [];
    OUT.ReactBias = [];
    OUT.ReactnormBias  = [];
else
    M = Bias(GOODIX,:);
    M(M>0) = 1; M(M<0) = -1; M(M==0) = nan;
    
    L = M(:,1) == M(:,2);
    PRE = nansum(L)/length(L(~isnan(L)));
    L = M(:,2) == M(:,3);
    POST = nansum(L)/length(L(~isnan(L)));
    OUT.ReactPropSameDir.propAB = PRE; % The proportion of comparisons that go in the same direction - should be more in POST if there is reactivation.
    OUT.ReactPropSameDir.propBC = POST;
    % Gerrard 2008 does not use partial correlations so we won't either.
    % Too many assumptions anyway.
    %     [tmp, p] = partialcorr(Bias(GOODIX,2:3),Bias(GOODIX,1));
    %     OUT.ReactBias.rBC_A  = tmp(2);
    %     OUT.ReactBias.rBC_A_p  = p(2);
    %     [tmp, p] = partialcorr(Bias(GOODIX,1:2),Bias(GOODIX,3));
    %     OUT.ReactBias.rAB_C  = tmp(2);
    %     OUT.ReactBias.rAB_C_p  = p(2);
    %     OUT.ReactBias.reactivation_strength = OUT.ReactBias.rBC_A - OUT.ReactBias.rAB_C;
    %
    %     [tmp, p] = partialcorr(normBias(GOODIX,2:3),normBias(GOODIX,1));
    %     OUT.ReactnormBias.rBC_A  = tmp(2);
    %     OUT.ReactnormBias.rBC_A_p  = p(2);
    %     [tmp, p] = partialcorr(normBias(GOODIX,1:2),normBias(GOODIX,3));
    %     OUT.ReactnormBias.rAB_C  = tmp(2);
    %     OUT.ReactnormBias.rAB_C_p  = p(2);
    %     OUT.ReactnormBias.reactivation_strength = OUT.ReactnormBias.rBC_A - OUT.ReactnormBias.rAB_C;
    %
    %     [tmp, p] = partialcorr(COM(GOODIX,2:3),COM(GOODIX,1));
    %     OUT.ReactCOM.rBC_A  = tmp(2);
    %     OUT.ReactCOM.rBC_A_p  = p(2);
    %     [tmp, p] = partialcorr(COM(GOODIX,1:2),COM(GOODIX,3));
    %     OUT.ReactCOM.rAB_C  = tmp(2);
    %     OUT.ReactCOM.rAB_C_p  = p(2);
    %     OUT.ReactCOM.reactivation_strength = OUT.ReactCOM.rBC_A - OUT.ReactCOM.rAB_C;
    %
    OUT.n_comparisons = sum(GOODIX);
    
    [tmp, p] = corrcoef(Bias(GOODIX,:),'rows','complete');
    
    OUT.ReactBias.rAB = tmp(1,2); % This would be an estimate of preactivation
    OUT.ReactBias.rBC = tmp(2,3);
    OUT.ReactBias.rAC = tmp(1,3);
    OUT.ReactBias.pAB = p(1,2);
    OUT.ReactBias.pBC = p(2,3);
    OUT.ReactBias.pAC = p(1,3);
    
    if sum(~isnan(sum(COM(GOODIX,:),2))) < 10
        disp('aborted COM')
        OUT.ReactCOM.rAB = [];
    else
        
        [tmp, p] = corrcoef(COM(GOODIX,:),'rows','complete');
        OUT.ReactCOM.rAB = tmp(1,2); % This would be an estimate of preactivation
        OUT.ReactCOM.rBC = tmp(2,3);
        OUT.ReactCOM.rAC = tmp(1,3);
        OUT.ReactCOM.pAB = p(1,2);
        OUT.ReactCOM.pBC = p(2,3);
        OUT.ReactCOM.pAC = p(1,3);
    end
    
    if sum(~isnan(sum(normBias(GOODIX,:),2))) < 10
        disp('aborted normBias')
        OUT.ReactnormBias.rAB = [];
    else
        [tmp, p] = corrcoef(normBias(GOODIX,:),'rows','complete');
        OUT.ReactnormBias.rAB = tmp(1,2); % This would be an estimate of preactivation
        OUT.ReactnormBias.rBC = tmp(2,3);
        OUT.ReactnormBias.rAC = tmp(1,3);
        OUT.ReactnormBias.pAB = p(1,2);
        OUT.ReactnormBias.pBC = p(2,3);
        OUT.ReactnormBias.pAC = p(1,3);
        
    end
    OUT.reactivation_strength = OUT.ReactBias.rBC - OUT.ReactBias.rAB;

end


if nargout == 0
    figure
    subplot(2,1,1)
    plot(Bias(:,1), normBias(:,1),'.')
    subplot(2,1,2)
    plot(Bias(:,1), COM(:,1),'.')
    
end
