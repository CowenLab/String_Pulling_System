function RtrnCode = Vector_Stats_Calcs2(Azims, NTot, Rbar, ...
    Ck, Sk, Rbark, fidO, MeanKnown, KappaKnown, ...
    ThetaHat, KappaHat, R2val, alfa, NB, flags)

%Vector_Stats_Calcs2.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Inference on vector mean (Theta) 
%    Tests of hypothesis on specific values
%    Confidence intervals

% flags(4)==1: Inference on mean vector direction, kappa known
% flags(5)==1: Inference on mean vector direction, kappa unknown
% Both seem to assume vonMises distribution is underlying

% Input variables:
%   Azims: Azimuths (radians)
%   NTot: N, sample size
%   Rbar: Mean vector length = sqrt(R2)/NTot
%   Ck, Sk: sum(cos(Azims-MeanKnown)), sum(sin(Azims-MeanKnown))  
%   Rbark: sqrt(Ck^2 + Sk^2)/NTot
%   fidO: output file to write calculations
%   MeanKnown: Known or hypothesized vector mean, in degrees
%   KappaKnown: Known concentration parameter
%   ThetaHat: Estimated mean vector direction, in degrees
%   KappaHat: Estimated concentration parameter
%   R2val: square length of mean vector = Cvals^2+Svals^2
%   alfa: Level of significance for tests
%   NB: number bootstrap iterations
%   flags: List of calculations to be made
% Output variable:
%   RtrnCode: Error return

% Function called by this module:
%   CalcKappa.m
%   Vector_Stats_Bootstrap_CImean.m

% set up for calculations and printing

RtrnCode = 0;

MeanKnownR = MeanKnown/57.3;
Cmnk = Ck/NTot;
Smnk = Sk/NTot;
chisq1df = chi2inv(1 - alfa, 1);

ptskip=sprintf('\n');
ptminus=sprintf('---------------------------------------------------\n');
pt4=sprintf('     Significance level (alfa) = %.2f\n', alfa);
pt1A=sprintf('Test of hypothesis: Vector Mean = %.1f\n', MeanKnown);

% ---------------------------------------------------------------

% inference on vector mean (Theta) for specific direction
    
if flags(4) == 1    
    
       % Kappa assumed known (Mardia and Jupp, 2000, p. 120)
       
   pt1A=sprintf('Test of hypothesis: Vector Mean = %.1f\n', MeanKnown);    
   pt1B=sprintf(['Concentration (Kappa) assumed known = %.5g\n', ...
                 'Assumes von Mises distribution\n', ...
                 '(Ref.: Mardia and Jupp, 2000, p. 120)\n'], ...
                 KappaKnown);
   disp(ptskip); disp(ptminus); disp(ptskip)
   disp(pt1A); disp(pt1B); disp(ptskip)
   if fidO > 0
      fprintf(fidO, ptskip); fprintf(fidO, ptminus);
      fprintf(fidO, ptskip); fprintf(fidO, pt1A); 
      fprintf(fidO, pt1B);  
      fprintf(fidO, ptskip); 
   end
       
w = 2*NTot*KappaKnown*(Rbark - Cmnk);
PVal = 1 - chi2cdf(w, 1);
cutoff = chisq1df;
if NTot > 50
    % "large" NTot
    pt2B=sprintf('     Test for "large" N (N > 50)\n');
    if w > cutoff
        Test1 = '     Reject hypothesized vector mean direction';
    else
        Test1 = '     Cannot reject hypothesized vector mean direction';
    end
else
    if KappaKnown >= 2
       % "moderate" NTot and kappa > 2 
       pt2B=sprintf('     Test for "moderate" N and Kappa >= 2\n');
       ww = 1/(1/KappaKnown + 3/(8*KappaKnown^2));
       w = 2*NTot*ww*(Rbark - Cmnk);
       PVal = 1 - chi2cdf(w, 1);
       if w > cutoff
          Test1 = '     Reject hypothesized vector mean direction';
       else
          Test1 = '     Cannot reject hypothesized vector mean direction';
       end
   else
       % "moderate" NTot
       pt2B=sprintf('     Test for "moderate" N and Kappa < 2\n');
       aaaaa = CalcKappa(KappaKnown, 1);
       wstar = w*(1-1/(4*NTot*KappaKnown*aaaaa));
       PVal = 1 - chi2cdf(wstar, 1);
       if w > cutoff
          Test1 = '     Reject hypothesized vector mean direction';
       else
          Test1 = '     Cannot reject hypothesized vector mean direction';
       end
   end
end  

   pt3=sprintf('     Calculated test statistic = %.4g\n', w);
   pt5=sprintf('     Test cutoff = %.4g\n', cutoff);
   pt6=sprintf('     Approx. P-value = %.4f\n', PVal);
   disp(pt2B); disp(pt3); disp(pt4); disp(pt5)
   disp(Test1); disp(' '); disp(pt6); disp(ptskip)
   if fidO > 0
       fprintf(fidO, pt2B); fprintf(fidO, pt3);
       fprintf(fidO, pt4) ; fprintf(fidO, pt5);
       fprintf(fidO, Test1);fprintf(fidO, ptskip);
       fprintf(fidO, pt6); fprintf(fidO, ptskip);
   end     

   doBoots = 0;
   if KappaKnown < 0.4  doBoots = 1; end;
   if NTot < 50 & (KappaKnown > 0.4 & KappaKnown < 1)  doBoots = 1; end;
   if NTot < 30 & (KappaKnown >= 1  & KappaKnown < 2)  doBoots = 1; end;   
   if doBoots > 0
   
      % confidence interval on vector mean, using resampling
      % Fisher, 1993, p. 199 - 211
    
      pt9A=sprintf(['Confidence interval on Vector Mean (Theta)\n',...
            '   using bootstrap resampling\n', ...
            'Assumes von Mises distribution with Kappa known\n', ...
            '(Ref.: Fisher, 1993, p. 88, 199 - 211)\n']); 
      disp(ptskip); 
      disp(pt9A); 
      if fidO > 0
         fprintf(fidO, ptskip); fprintf(fidO, pt1A);
      end
      
      ThetaHatR = ThetaHat/57.3;
      [L1, L2] = Vector_Stats_Bootstrap_CImnVM(Azims, NB, NTot, ...
                                         ThetaHatR, KappaKnown, alfa);
   
      L1 = L1*57.3;      L2 = L2*57.3;
      if L2-L1 > 180
         tmp=L2; L2=L1; L1=tmp;
      end
  
      pt3=sprintf('     Estimated Vector Mean = %.1f\n', ThetaHat);
      pt6=sprintf('     %.0f pct. confidence interval: (%.2f, %.2f)\n', ...
          100*(1-alfa), L1, L2);
      disp(pt3); disp(pt6); 
      if fidO > 0
          fprintf(fidO, pt3); fprintf(fidO, pt6);
      end  
   
   end
   
end

% ---------------------------------------------------------------

if flags(5) == 1
       
       % Kappa not assumed known  
       % (Mardia and Jupp, 2000, p. 122 (7.2.15, 7.2.16)
       
   pt1B=sprintf(['Concentration parameter (Kappa) unknown\n', ...
                 'Assumes von Mises distribution\n', ...
               '(Ref.: Mardia and Jupp, 2000, p. 122 (7.2.15, 16))\n']); 
   disp(ptskip); disp(ptminus); disp(ptskip)
   disp(pt1A); disp(pt1B); disp(ptskip)
   if fidO > 0
      fprintf(fidO, ptskip); fprintf(fidO, ptminus);
      fprintf(fidO, ptskip); fprintf(fidO, pt1A); 
      fprintf(fidO, pt1B);  
      fprintf(fidO, ptskip); 
   end
                                           
cutoff = chisq1df;                                  
if Cmnk <= 0.667
    % NTot >= 5 and Cbar <= 2/3
    w = 4*NTot*(Rbark^2 - Cmnk^2)/(2 - Cmnk^2);
    PVal = 1 - chi2cdf(w, 1);
    if w > cutoff
       Test1 = '     Reject hypothesized vector mean direction';
    else
       Test1 = '     Cannot reject hypothesized vector mean direction';
    end
else
    % NTot >= 5 and Cbar > 2/3
    w = 2*NTot^3/(NTot^2 + Ck^2 + 3*NTot);
    w = w*log((1 - Cmnk^2)/(1 - Rbark^2));
    PVal = 1 - chi2cdf(w, 1);
    if w > cutoff
       Test1 = '     Reject hypothesized vector mean direction';
    else
       Test1 = '     Cannot reject hypothesized vector mean direction';
    end
end    

   pt3=sprintf('     Calculated test statistic = %.4g\n', w);
   pt5=sprintf('     Test cutoff = %.4g\n', cutoff);
   pt6=sprintf('     P-value = %.4f\n', PVal);
   disp(pt3); disp(pt4); disp(pt5)
   disp(Test1); disp(' '); disp(pt6); disp(ptskip)
   if fidO > 0
       fprintf(fidO, pt3);
       fprintf(fidO, pt4); fprintf(fidO, pt5); 
       fprintf(fidO, Test1); fprintf(fidO, ptskip);
       fprintf(fidO, pt6); fprintf(fidO, ptskip); 
   end     
    
% ---------------------------------------------------------------

    % confidence interval on vector mean
    % Mardia and Jupp, 2000, p. 124 (7.2.27 and 7.2.28)
    
   pt1A=sprintf(['Confidence interval on Vector Mean (Theta)\n',...
            'Assumes von Mises distribution\n', ...
            '(Ref.: Mardia and Jupp, 2000, p. 124 (7.2.27, 28))\n']); 
   disp(ptskip); disp(ptminus); disp(ptskip)
   disp(pt1A); 
   if fidO > 0
      fprintf(fidO, ptskip); fprintf(fidO, ptminus);
      fprintf(fidO, ptskip); fprintf(fidO, pt1A);
   end
    
   if Rbar <= 0.667
       w = 2*NTot*(2*R2val - NTot*chisq1df);
       w = w/(R2val*(4*NTot - chisq1df));
       w = acos(sqrt(w))*57.3;
   else
       w = NTot^2 - (NTot^2 - R2val)*exp(chisq1df/NTot);
       w = acos(sqrt(w/R2val))*57.3;
   end
   L1 = ThetaHat - w;
   L2 = ThetaHat + w;
   if L1 > 360; L1 = L1 - 360; end
   if L1 < 0; L1 = L1 + 360; end
   if L2 > 360; L2 = L2 - 360; end
   if L2 < 0; L2 = L2 + 360; end
   if L2-L1 > 180
       tmp=L2;L2=L1;L1=tmp;
   end
  
   pt3=sprintf('     Estimated Vector Mean = %.1f\n', ThetaHat);
   pt6=sprintf('     %.0f pct. confidence interval: (%.2f, %.2f)\n', ...
       100*(1-alfa), L1, L2);
   disp(pt3); disp(pt6); 
   if fidO > 0
       fprintf(fidO, pt3); fprintf(fidO, pt6);
   end      
   
   
   doBoots = 0;
   if KappaHat < 0.4  doBoots = 1; end;
   if NTot < 50 & (KappaHat > 0.4 & KappaHat < 1)  doBoots = 1; end;
   if NTot < 30 & (KappaHat >= 1  & KappaHat < 2)  doBoots = 1; end;   
   if doBoots > 0
     
      % confidence interval on vector mean, using resampling
      % assumes von Mises
      % Fisher, 1993, p. 199 - 211
    
      pt1A=sprintf(['Confidence interval on Vector Mean (Theta)\n',...
               '   using bootstrap resampling\n', ...
               'Assumes von Mises distribution\n', ...
               '(Ref.: Fisher, 1993, p. 88, 199 - 211)\n']); 
      disp(ptskip); 
      disp(pt1A); 
      if fidO > 0
         fprintf(fidO, ptskip); fprintf(fidO, pt1A);
      end
   
      ThetaHatR = ThetaHat/57.3;
      [L1, L2] = Vector_Stats_Bootstrap_CImnVM(Azims, NB, NTot, ...
                                            ThetaHatR, KappaHat, alfa);
   
      L1 = L1*57.3;      L2 = L2*57.3;
      if L2-L1 > 180
          tmp=L2; L2=L1; L1=tmp;
      end
  
      pt3=sprintf('     Estimated Vector Mean = %.1f\n', ThetaHat);
      pt6=sprintf('     %.0f pct. confidence interval: (%.2f, %.2f)\n', ...
          100*(1-alfa), L1, L2);
      disp(pt3); disp(pt6); 
      if fidO > 0
          fprintf(fidO, pt3); fprintf(fidO, pt6);
      end  
   
  end
  
  if NTot < 35
      
      % confidence interval on vector mean, using resampling
      % no assumption of distributional form
      % Fisher, 1993, p. 199 - 211
    
      pt1A=sprintf(['Confidence interval on Vector Mean (Theta)\n',...
               '   using bootstrap resampling\n', ...
               'No von Mises distribution assumption\n', ...
               '(Ref.: Fisher, 1993, p. 75, 199 - 211)\n']); 
      disp(ptskip); 
      disp(pt1A); 
      if fidO > 0
         fprintf(fidO, ptskip); fprintf(fidO, pt1A);
      end
   
      ThetaHatR = ThetaHat/57.3;
      [L1, L2] = Vector_Stats_Bootstrap_CImean(Azims, NB, NTot, ...
                                            ThetaHatR, alfa);
   
      L1 = L1*57.3;      L2 = L2*57.3;
      if L2-L1 > 180
          tmp=L2; L2=L1; L1=tmp;
      end
  
      pt3=sprintf('     Estimated Vector Mean = %.1f\n', ThetaHat);
      pt6=sprintf('     %.0f pct. confidence interval: (%.2f, %.2f)\n', ...
          100*(1-alfa), L1, L2);
      disp(pt3); disp(pt6); 
      if fidO > 0
          fprintf(fidO, pt3); fprintf(fidO, pt6);
      end  
   
   end
   
end
   
 
