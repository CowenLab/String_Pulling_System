function S = Sparseness_measures(M)
% function S = Sparseness_measures(M)
%
% Calculates sparseness measures for each row in M
% For RollsTovee measures, higher numbers means LESS sparseness - confusing, I
% know. For kurtosis, CV, higher numbers mean more sparseness.
% See http://www.scholarpedia.org/article/Sparse_coding
%% also added Buzsaki % of activated uerons (non zero) as another measure.
% mentioned in the Buzsaki Mizuseki 2014 review log.
%M = [1 1 1 1 1 1; 0 1 0 1 0 1; 1 1 0 0 0 0 ;-1 -1 -1 -1 -1 0; -1 0 0 0 0 0 ];
%M = rand(1000,40);
% M(M < 0.5) = 0;
% Cowen 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S.kurtosis = kurtosis(M,1,2); % Scholarpedia Field (1994). The bias correction does not seem to do anything.
% Kurtosis is interesting in that it dips down when half of the population
% is being used.
if min(M(:)) < 0
    warning([mfilename ':CV and classic sparsity measures are not appropriate for matrices with negative numbers. Use kurtosis.'])
    %     S.RT = [];
    %     S.CV = [];
    %     S.Prop_Active = [];
end
S.RT = (mean(M,2).^2)./mean(M.^2,2); % (Rolls and Tovee 1995) REMEMBER - higher values = LESS sparse (more dense)
S.CV = nanstd(M,[],2)./nanmean(M,2); % almost identicial to 1/RT.
S.Prop_Active = sum(M>0,2)/size(M,2); % proportion of neurons active.

if nargout == 0
    MM = [S.kurtosis S.RT S.CV S.Prop_Active ] ;
    figure;
    subplot(3,1,1)
    plot(S.kurtosis)
    subplot(3,1,2)
    plot(S.RT)
    subplot(3,1,3)
    plot(S.CV)
    
    figure
    plot(S.CV,S.kurtosis,'k.')
    xlabel('CV')
    ylabel('Kur')
    lsline
    
    %% Simulation for validation...
    V = rand(1000,40);
    VIX = find(V);
    rp = randperm(length(VIX));
    T = [];
    %V = standardize_range(V);
    s_level = 0:.05:.95;
    figure
    for ii = 1:length(s_level)
        ntokill = round(length(VIX)*s_level(ii))+1;
        VV = V;
        VV(VIX(rp(1:ntokill))) = 0;
        %        V(V<s_level(ii)) = 0;
        imagesc(VV)
        pause(0.04)
        
        O = Sparseness_measures(VV);
        T.k(ii)  = nanmean(O.kurtosis);
        T.rt(ii) = nanmean(O.RT);
        T.cv(ii) = nanmean(O.CV);
    end
    figure
    subplot(1,3,1)
    plot(s_level,T.k)
    title('kurtosis')
    subplot(1,3,2)
    plot(s_level,T.rt)
    title('rt')
    subplot(1,3,3)
    plot(s_level,T.cv)
    title('cv')
    
end