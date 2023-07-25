function RtrnCode = Vector_1way_Calcs(q, UseFrq, Azims, SummaryStats, ...
                                   flags, NB, BSRS, ... 
                                   IndepName, CatName,alfa, fidO)  

%Vector_1way_Calcs.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Performs the statistical tests and calculations.
% Determines which tests can be done with Kappa and N for the samples.
% Then does the tests of equal vector means: 
% (1) von Mises assumption, (2) non-parametric, (3) bootstrap
% Then does confidence interval on difference of vector means for
% all pairs of samples.
% Then does tests of equal concentrations, incl. bootstrap.

% Input variables:
%   q: number of samples to be analyzed
%   UseFrq: 0 = data input as individual azimuths
%           1 = data input as azimuth column, plus q columns of counts
%   Azims: Array of azimuths to be processed, in radians
%   SummaryStats: array of size q+1,8 containing calculated summary stats
%         for each of q samples and total combined sample (row q+1)
%         Columns contain:  1) sum(sines)     2) sum(cosines)     3) N
%            4) R-squared     5) R      6) R-bar    
%            7) Vector mean, theta (degrees)   8) Concentration (kappa)
%   flags: List of which calculations are to be made   =0 do not do
%        flags(1)=1 do vector-mean tests    
%        flags(2)=1 do conf ints on pairs of vector means
%        flags(4)=1 do kappa tests
%   NB: number of bootstrap iterations
%   BSRS: do bootstraps even if not required by N (1) - else dont (0)
%   IndepName: identifiers of the samples
%   CatName: Array of positions in IndepName list that corresponds to 
%            columns in Azims
%   alfa: Level of significance: should be in range (0.001 - 0.25)
%   fidO: output file for writing calculations if fidO > 0
% Generated variable:
%   Nlimit1: do standard tests if all subsample sizes exceed this
%   Nlimit2: do bootstrap if all subsample sizes less than this
%   CalcsToDo: Do each individual test for corresp. entries in array?
%              yes = 1; 0 = no
%   BSeqK: do bootstrap assuming equal Kappas? 0=no, 1=yes
%   BSneK: do bootstrap assuming not-equal Kappas? 0=no, 1=yes
% Output variable:
%   RtrnCode: return code

% Functions and scripts called from this module:
%   Vector_1way_Calcs1AVM.m
%   Vector_1way_Calcs1ANP.m
%   Vector_1way_Calcs1B.m
%   Vector_1way_Calcs2.m
%   Vector_1way_Calcs13.m
%   Vector_1way_Calcs3A.m
%   Vector_1way_Calcs3B.m

RtrnCode = 0;
MedKappa = median(SummaryStats(1:q, 8));
minN = min(SummaryStats(1:q, 3));

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% test if vector-mean directions are equal

if flags(1) == 1
    
    % set up list for what is valid to do
    
    CalcsToDo = zeros(6,1);  BSeqK = BSRS;  BSneK = BSRS;
    Nlimit1 = [22, 11,  8, 0, 22, 22];
    Nlimit2 = [27, 18, 12, 0, 27, 27];
    % likelihood ratio tests
    if MedKappa < 1 & MedKappa > 0.05;
        if minN < Nlimit2(1);   BSeqK = 1;  end;
        if minN >= Nlimit1(1);  CalcsToDo(1) = 1;  end;
    end;
    if MedKappa > 0.87;
        if minN < Nlimit2(2);   BSeqK = 1;  end;
        if minN >= Nlimit1(2);  CalcsToDo(2) = 1;  end;
        if MedKappa < 2 & minN >= Nlimit1(2);  CalcsToDo(2) = 2;  end;
    end;
    % embedding method
    if MedKappa > 1.5;
        if minN < Nlimit2(3);   BSeqK = 1;  end;
        if minN >= Nlimit1(3);  CalcsToDo(3) = 1;  end;
    end;
    % heterogenous
    if min(SummaryStats(1:q, 8)) >= 1.7;
        if minN < Nlimit2(5);   BSneK = 1;  end;
        if minN >= Nlimit1(5);  CalcsToDo(5) = 1;  end;    
    else
        BSneK = 1;
    end; 
    
    
 CalcsToDo(6)=1;
 
    
    % do the calculations
    
    % von Mises
    RtrnCode = Vector_1way_Calcs1AVM(q, SummaryStats, CalcsToDo, ...
                                   Nlimit2, alfa, fidO);
    if RtrnCode > 0
        return
    end
    
    % non-parametric
    if minN < 27;  BSeqK = 1;  end;
     RtrnCode = Vector_1way_Calcs1ANP(q, UseFrq, Azims, ...
                                      SummaryStats, alfa, fidO);
     if RtrnCode > 0
         return
     end
    
     % bootstrap
     if (BSeqK + BSneK) > 0
        RtrnCode = Vector_1way_Calcs1B(q, UseFrq, Azims, SummaryStats, ...
                                    BSeqK, BSneK, NB, alfa, fidO);
        if RtrnCode > 0
            return
        end
    end
    
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% test if vector means are equal AND if concentrations are equal

if flags(1) == 1 | flags(4) == 1
    N1 = 22; N2 = 27;
    RtrnC = Vector_1way_Calcs13(q, SummaryStats, N1, N2, alfa, fidO);
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% confidence interval on difference between two vector means
% calculate for all pairs category iii - category jjj

if flags(2) == 1
    
    for iii = 1:q-1
        for jjj = iii+1:q
           RtrnC = Vector_1way_Calcs2(q, SummaryStats, iii, jjj, ...
                                       IndepName, CatName, alfa, fidO);
        end
    end
    
end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% test if concentration parameters (kappa) are equal

if flags(4) == 1
    
    % set up list for what is valid to do
    
    BSeqK = BSRS;  
    CalcsToDo = zeros(6,1);
    Nlimit1 = [22, 11, 22, 10];
    Nlimit2 = [27, 18, 27, 12];
    % likelihood ratio tests
    if MedKappa < 1
        if minN < Nlimit2(1);   BSeqK = 1;  end;
        if minN >= Nlimit1(1);  CalcsToDo(1) = 1;  end;
    end;
    if MedKappa > 0.87 & MedKappa <= 2
        if minN < Nlimit2(2);   BSeqK = 1;  end;
        if minN >= Nlimit1(2);  CalcsToDo(2) = 1;  end;
    end;
    if MedKappa > 2
        if minN < Nlimit2(3);   BSeqK = 1;  end;
        if minN >= Nlimit1(3);  CalcsToDo(3) = 1;  end;
    end;
    if MedKappa >= 1 
        if minN < Nlimit2(4);   BSeqK = 1;  end;
        if minN >= Nlimit1(4);  CalcsToDo(4) = 1;  end;
    end;
    
    % do the calculations
    
    RtrnCode = Vector_1way_Calcs3A(q, UseFrq, Azims, SummaryStats, ...
                                   CalcsToDo, Nlimit2, ...
                                   alfa, fidO);
    if RtrnCode > 0
        return
    end

    % bootstrap
    
    if BSeqK > 0
       RtrnCode = Vector_1way_Calcs3B(q, UseFrq, Azims, SummaryStats, ...
                                      NB, alfa, fidO);
       if RtrnCode > 0
         return
       end
    end
    
end

