function RtrnCode = Vector_Stats_Calcs3(Yvect, NTot, Rbar, ...
    KappaHat, fidO, NB, ThetaBar, alfa)

%Vector_Stats_Calcs3.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Inference on concentration (Kappa): Confidence intervals
% Assumes von Mises distribution

% Input variables:
%   Yvect: vector of azimuths (radians)
%   NTot: N, sample size
%   Rbar: Mean vector length = sqrt(R2)/NTot
%   KappaHat: estimated value of concentration parameter
%   fidO: output file to write calculations
%   NB: number of bootstrap iterations
%   ThetaBar: calculated vector mean (degrees)
%   alfa: Level of significance for tests
% Output variable:
%   RtrnCode: Error return

% Functions scripts called by this module:
%   CalcKappa.m
%   Vector_Stats_Bootstrap_CIkapVM.m

% References embedded in code

% set up for calculations and printing

RtrnCode = 0;

ptskip=sprintf('\n');
ptminus=sprintf('---------------------------------------------------\n');
pt4=sprintf('     Significance level (alfa) = %.2f\n', alfa);
   
 % Confidence interval on concentration (Kappa)
    
   pt1A=sprintf(['Confidence interval on Concentration (Kappa)\n', ...
                 'Assumes von Mises distribution\n']);
   disp(ptskip); disp(ptminus); disp(ptskip)
   disp(pt1A); 
   if fidO > 0
      fprintf(fidO, ptskip); fprintf(fidO, ptminus);
      fprintf(fidO, ptskip); fprintf(fidO, pt1A); 
   end
   
   zz = norminv(1 - alfa/2, 0, 1);
   
   % Rbar < 0.45     Mardia and Jupp, 2000, p. 81 (4.8.41 and 4.8.42)
   
  if Rbar < 0.45
       pt2A=sprintf(['R-bar < 0.45 (KappaHat < 1)\n', ... 
                   '(Ref.: Mardia and Jupp, 2000, p. 81 (4.8.41, 42))\n']); 
       Rmn = asin(1.2247*Rbar);
       Rvar = (0.75/(1 - 4/NTot))/NTot;
       Rv = sqrt(Rvar);
       L1 = Rmn - zz*Rv;         L2 = Rmn + zz*Rv;  
       L1 = sin(L1)/1.2247;      L2 = sin(L2)/1.2247;
       L1 = CalcKappa(L1, 0);    L2 = CalcKappa(L2, 0);

       pt3=sprintf('   Estimated Kappa = %.4g\n', KappaHat);
       pt6=sprintf('   %.0f pct. confidence interval: (%.4g, %.4g)\n', ...
                 100*(1-alfa), L1, L2);
       disp(pt2A);     
       disp(pt3); disp(pt6); 
       if fidO > 0
           fprintf(fidO, pt2A); fprintf(fidO, ptskip);
           fprintf(fidO, pt3);  fprintf(fidO, pt6);
       end     
   end
   
   % 0.45 <= Rbar < 0.7     Mardia and Jupp, 2000, p. 82 (4.8.46, 4.8.47)
   % using Rbar > 0.40 because approximation above is poor near 0.45
   
   if Rbar > 0.4 & Rbar <=0.7
       pt2A=sprintf(['0.40 < R-bar <= 0.70 (1 < KappaHat < 2)\n', ...
                 '(Ref.: Mardia and Jupp, 2000, p. 82 (4.8.46, 47))\n']); 
       Rmn = asinh((Rbar - 1.089)/0.258);
       Rvar = (0.893^2/(1 - 3/NTot))/NTot;
       Rv = sqrt(Rvar);
       L1 = Rmn - zz*Rv;             L2 = Rmn + zz*Rv;  
       L1 = sinh(L1)*0.258+1.089;    L2 = sinh(L2)*0.258+1.089;  
       L1 = CalcKappa(L1,0);         L2 = CalcKappa(L2,0);
   end
   
   % Rbar > 0.7     Mardia and Jupp, 2000, p. 126-127 (7.2.38)
   
   if Rbar > 0.7
      pt2A=sprintf(['R-bar > 0.70 (KappaHat > 2)\n', ... 
              '(Ref.: Mardia and Jupp, 2000, p. 126-127 (7.2.38))\n']); 
      aaa = NTot*(1 - Rbar);
      bbb = aaa/chi2inv(1-alfa/2, NTot-1);
      aaa = aaa/chi2inv(alfa/2, NTot-1);
      L1 = (1 + sqrt(1 + 3*aaa))/(4*aaa);
      L2 = (1 + sqrt(1 + 3*bbb))/(4*bbb);
   end
   
      % output
      
    pt3=sprintf('     Estimated Kappa = %.4g\n', KappaHat);
    pt6=sprintf('     %.0f pct. confidence interval: (%.4g, %.4g)\n', ...
                 100*(1-alfa), L1, L2);
    disp(pt2A);         
    disp(pt3); disp(pt6); disp(ptskip)
    if fidO > 0
        fprintf(fidO, pt2A); 
        fprintf(fidO, pt3);  fprintf(fidO, pt6);
    end     


    
% Confidence interval on concentration (Kappa), generated according to
% resampling (bootstrap) methods
% Ref.: Fisher, 1993, p. 90-91, 199-207, 210-211

if KappaHat < 2.25 & NTot < 50
    
    pt1A=sprintf(['Confidence interval on Concentration (Kappa)\n', ...
                  '   using resampling (bootstrap) methods\n',...
                  '   for small Kappa (<2.25) and N (<50)\n', ...
                  '(Ref.: Fisher, 1993, p. 90-91, 199-207, 210-211)\n']);
    disp(ptskip);  disp(pt1A); 
    if fidO > 0
      fprintf(fidO, ptskip); fprintf(fidO, pt1A); 
    end
   
        % calculate
        
    [K1, K2] = Vector_Stats_Bootstrap_CIkapVM(Yvect, NB, NTot, ...
                                       ThetaBar/57.3, KappaHat, alfa);
                                         
        % output
      
    pt3=sprintf('     Estimated Kappa = %.4g\n', KappaHat);
    pt6=sprintf('     %.0f pct. confidence interval: (%.4g, %.4g)\n', ...
                 100*(1-alfa), K1, K2);         
    disp(pt3); disp(pt6); disp(ptskip)
    if fidO > 0
        fprintf(fidO, pt3);  fprintf(fidO, pt6);
    end      
   
end    
    
