function [p,tbl,rm] = within_anova(X)
% function [p,t] = within_anova(X)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A simple within-subject ANOVA with no between subject condition.
% also called random-effects anova.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0 
    % Create some sample data for testing
    disp('Running a DEMO of within subject ANOVA...')
    a1 = randn([10,1])*1 + 4;
    a2 = randn([10,1])*.8 + 1;
    a3 = randn([10,1])*1 + 3;
    a4 = randn([10,1])*2 + 2;
    %     ID = [1:length(a3)]'; % turns out we don't need an ID. Yeah.
    %  T = readtable('C:\Temp\tmp.csv')
    X = [a1,a2,a3,a4];
    TBL = table(a1,a2,a3,a4);

    % Sample from matlab help... This demo has a between subject factor
    % too.
    load fisheriris
    t = table(species,meas(:,1),meas(:,2),meas(:,3),meas(:,4),...
        'VariableNames',{'species','meas1','meas2','meas3','meas4'});
    Meas = table([1 2 3 4]','VariableNames',{'Measurements'});
    rm = fitrm(t,'meas1-meas4~species','WithinDesign',Meas);
    ranovatbl = ranova(rm)
    % now tweak it to a one factor anova...
    % You just have to change the ~species to ~1.
    Meas = table([1:Cols(TBL)]','VariableNames',{'Measurements'});
    rm = fitrm(TBL,'a1-a4~1','WithinDesign',Meas);
    ranovatbl = ranova(rm)
    % this is a user supplied function from matlab central. Seems to give
    % the same result as above, but the output is CONFUSING (why the 3rd
    % pvalue is the pvalue - confusing)
    [tbl,rm] = simple_mixed_anova(X);
    p = tbl.pValue(3);

end
% For now, just use the user-supplied version from matlab central.
% that way I don't have to make some weird ass table.
% see example above for comparison.
[tbl,rm] = simple_mixed_anova(X);
p = tbl.pValue(3);
