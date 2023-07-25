function [O, RM] = anovan_cowen(Mca)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ANOVA - cell array input. each cell array has a matrix where each row
% is an observation, each column is a level of a factor (within
% subject) and each cell array is a differnt group (between subject).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
D = [];   G1 = [];    G2 = [];
for ii = 1:length(Mca)
    D = [D;Mca{ii}];
    G1 = [G1;repmat(1:Cols(Mca{ii}),Rows(Mca{ii}),1)];
    G2 = [G2;ones(size(Mca{ii}))*ii];
    [~,O.ttest_zero_p] = ttest(Mca{ii}); % test if diff from zero.
    O.ttest_zero_p_bonf = bonf_holm(O.ttest_zero_p);
end
%
[O.p,O.tbl,O.stats] = anovan(D(:),{G1(:) G2(:)},'model','interaction','display','off');
O.multcomp1 = multcompare(O.stats,'display','off');
O.multcomp2 = multcompare(O.stats,'Dimension',[1 2],'display','off');
IX = O.multcomp1(:,6) < 0.05;
O.sigcomps1 = O.multcomp1(IX,:);
IX = O.multcomp2(:,6) < 0.05;
O.sigcomps2 = O.multcomp2(IX,:);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do it my way - limit tests to just paired columns. My way does not seem to
% be any more powerful than the multcompare way even though
% multocompare does EVERY comparison.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,O.ttest2_p] = ttest2(Mca{1}, Mca{2});
O.ttest2_p_bonf = bonf_holm(O.ttest2_p);
if nargout > 1
    % repeated measures design - assme each row is a repeated measure.
    %% Repeated measure design for days 5-10.
    % Work in progress. 
    AN = 1:Rows(D);
    vbls = {'Grp' 'AN' };
    for ii = 1:Cols(D)
        vbls{ii + 2} = ['t' num2str(ii)];
        DD{ii} = D(:,ii);
    end
    
    T3 = table(ones(size(AN)),AN, DD ,'VariableNames',vbls);
    
    Day = 1:Cols(D);
    rm = fitrm(T3,'t1-t5 ~ Grp','WithinDesign',Day);
    multcompare(rm,'Grp')
    ranovatbl = ranova(rm)
end