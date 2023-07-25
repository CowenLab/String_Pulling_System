function RtrnCode = Vector_Stats_Calcs(Azims, MeanKnown, KappaKnown, ...
    fidO, DataTtl, alfa, flags, init_guesses, MaxItr, TolerX, ...
    NColAz, NColFrq, AzData, NClasses, AzOrigin, LinSq, NB)    

%Vector_Stats_Calcs.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Exploratory analysis on vectorial dataset
%     Basic statistics
%     Data plots and Q-Q plots
%     Test for uniform or von Mises distributions
% Inference on data
%     Tests of hypothesis and confidence intervals
% Separate mixture of two von Mises distributions into components

% Input variables:
%   Azims: Vector of Azimuths to be processed, in radians
%   MeanKnown: Known or hypothesized vector mean, in degrees
%   KappaKnown: Known concentration parameter
%   fidO: output file for writing calculations if fidO > 0
%   DataTtl: Title for data or job
%   alfa: Level of significance for tests: must be 0.1, 0.05, 0.025, 0.01
%         for tests of distributional form
%   flags: List of which calculations are to be made
%   init_guesses: Initial estimates for two-component iterations
%   MaxItr: maximum number of iterations
%   TolerX: tolerance for iterating
%   NColAz: column in AzData containing azimuths
%   NColFrq: column in AzData containg frequencies
%   AzData: input data file
%   NClasses: number of classes in rose diagram
%   AzOrigin: Edge azimuth of first class in rose diagram
%   LinSq: plot rose with linear (0), or square root (1), of counts
%   NB: number of bootstrap iterations
% Output variable:
%   RtrnCode: Error return

% Functions and scripts called from this module:
%   VectMean_arctan.m
%   CalcKappa.m
%   Vector_Stats_Plots.m
%   Vector_Stats_Calcs1.m
%   Vector_Stats_Calcs2.m
%   Vector_Stats_Calcs3.m
%   Vector_Stats_TwoModes3.m
%   Vector_Stats_TwoModes5.m

RtrnCode = 0;
MeanKnownR = MeanKnown/57.3;

% basic statistics for vectorial data

NTot = length(Azims);

cosvals = cos(Azims);
sinvals = sin(Azims);

Cvals = sum(cosvals);
Svals = sum(sinvals);
R2val = Cvals*Cvals + Svals*Svals;
Rval = sqrt(R2val);
Rbar = Rval/NTot;

% statistics for known mean
Ck = sum(cos(Azims - MeanKnownR));
Sk = sum(sin(Azims - MeanKnownR));
Rbark = Rbar;

% estimates of parameters 

ThetaHat = VectMean_arctan(Svals,Cvals);     %degrees
KappaHat = CalcKappa(Rbar, 0);
    %correction for bias and small sample - Fisher, 1993, p. 88 (4.41)
if NTot < 18
    if KappaHat < 2
        KappaHatCorr = max(KappaHat - 2/(NTot*KappaHat), 0);
    else
        KappaHatCorr = KappaHat*(NTot - 1)^3 / (NTot + NTot^3);
    end
else
    KappaHatCorr = -99;
end

% output

ptskip=sprintf('\n');
ptminus=sprintf('---------------------------------------------------\n');

ptlb=sprintf('Estimates of standard parameters\n');
pt0=sprintf('   N = %.0f \n' , NTot);                         
pt1=sprintf('   C=sum(cosX) = %.5g     S=sum(sinX) = %.5g\n',Cvals,Svals); 
pt2=sprintf('   R-square = %.5g        R = %.5g \n', R2val, Rval);   
pt3=sprintf('   R-bar = %.4f \n' , Rbar);             
pt4=sprintf('   Vector mean (Theta-hat, deg.) = %.1f \n', ThetaHat); 
pt5=sprintf('   Concentration (Kappa-hat) = %.5g \n', KappaHat); 
pt6=sprintf(['   Kappa-hat corrected for small-sample bias = %.5g \n', ...
             '       (Ref.: Fisher, 1993, p. 88 (4.41))\n'], ...
              KappaHatCorr); 
pt8=sprintf('Sample size too small for any inferences to be done\n');
pt9=sprintf('Warning: Some tests assume large sample sizes\n');

disp(ptskip);  disp(ptminus);  disp(ptskip);
disp(ptlb);  disp(ptskip);  disp(pt0);
disp(pt1);   disp(pt2);   disp(pt3);
disp(pt4);   disp(pt5);   
if KappaHatCorr > -5
    disp(pt6); 
end
if NTot < 5
    disp(ptskip); disp(pt8)
    RtrnCode = 15
end
if NTot < 30 & NTot > 4
    disp(ptskip); disp(pt9)
end

if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, ptminus);  fprintf(fidO, ptskip);
    fprintf(fidO, ptlb); fprintf(fidO, pt0);
    fprintf(fidO, pt1); fprintf(fidO, pt2);
    fprintf(fidO, pt3); fprintf(fidO, pt4);
    fprintf(fidO, pt5); 
    if KappaHatCorr > -5
       fprintf(fidO, pt6); 
    end
    if NTot < 5
      fprintf(fidO, ptskip); fprintf(fidO, pt8);
    end
    if NTot < 30 & NTot > 4 
      fprintf(fidO, ptskip); fprintf(fidO, pt9);
    end
    fprintf(fidO, ptskip);
end    

if KappaHatCorr > -1
    KappaHat = KappaHatCorr;
end

if RtrnCode == 15;  return;  end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% plots - directional and Q-Q

if flags(3) == 1
    
    % information on rose diagram
    
    pt1 = sprintf('Controls used to generate rose diagrams\n');
    pt2 = sprintf('   Number of classes = %.0f\n', NClasses);
    pt3 = sprintf('   Width of classes (degr.) = %.1f\n', 360/NClasses);
    pt4 = sprintf('   Origin of azimuths used for classes = %.1f\n', AzOrigin);
    if LinSq == 0
       pt5 = sprintf('   Plot frequency for each class\n');
    else
       pt5 = sprintf('   Plot square-root(frequency) for each class\n');
    end
    
    disp(ptskip); disp(ptminus); disp(ptskip)
    disp(pt1); disp(ptskip)
    disp(pt2); disp(pt3); disp(pt4); disp(pt5)
    
    if fidO > 0
       fprintf(fidO, ptskip); fprintf(fidO, ptminus); fprintf(fidO, ptskip); 
       fprintf(fidO, pt1); fprintf(fidO, ptskip); 
       fprintf(fidO, pt2); fprintf(fidO, pt3); fprintf(fidO, pt4); 
       fprintf(fidO, pt5); 
       fprintf(fidO, ptskip); 
   end
       
    % plots 
    
    ptplot = sprintf(['N = %.0f \n', ...
                      'R-bar = %.4f \n', ... 
                      'Vector mean (Theta, deg.) = %.1f \n', ...
                      'Concentration (Kappa) = %.4g \n'], ...
                           NTot, Rbar, ThetaHat, KappaHat); 
    RtrnCode = Vector_Stats_Plots(Azims, cosvals, sinvals, ...
                      ThetaHat, KappaHat, fidO, ...
                      NColAz, NColFrq, AzData, ...
                      DataTtl, ptplot, NClasses, AzOrigin, LinSq);
    if RtrnCode > 0
       return
    end   
end
   
% test for data from uniform distribution or test for von Mises

if flags(1) == 1 | flags(2) == 1
   RtrnCode = Vector_Stats_Calcs1(NTot, Azims, Rbar, ...
       ThetaHat, KappaHat, MeanKnown, KappaKnown, Ck, fidO, alfa, flags, ...
       NColAz, NColFrq, AzData );
   if RtrnCode > 0
       return
   end
end

% inference on mean-orientation parameter

if flags(4) == 1 | flags(5) == 1 
    RtrnCode = Vector_Stats_Calcs2(Azims, NTot, Rbar, ...
    Ck, Sk, Rbark, fidO, MeanKnown, KappaKnown, ...
    ThetaHat, KappaHat, R2val, alfa, NB, flags);
    if RtrnCode > 0
       return
    end
end

% inference on concentration parameter

if flags(6) == 1
    RtrnCode = Vector_Stats_Calcs3(Azims, NTot, Rbar, ...
    KappaHat, fidO, NB, ThetaHat, alfa);
    if RtrnCode > 0
       return
    end
end

% separate components from mixture of two von Mises dists.

if flags(7) == 1
    RtrnCode = Vector_Stats_TwoModes3(NTot, Azims, fidO);
    RtrnCode = Vector_Stats_TwoModes5(NTot, Azims, init_guesses, fidO,...
                            MaxItr, TolerX);
end

