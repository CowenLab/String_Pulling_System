function RtrnCode = Vector_Stats_Calcs1(NTot, Azims, Rbar, ...
    ThetaHat, KappaHat, MeanKnown, KappaKnown, Ck, fidO, testalfa, flags, ...
    NColAz, NColFrq, AzData)

%Vector_Stats_Calcs1.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Tests for fits to uniform or von Mises distributions
% flags(1)==1
%    Rayleigh tests for uniformity, assuming Theta known and unknown
% flags(2)==1
%    vonMises fits, with CDF, assuming both params. known and unknown 

% Input variables:
%   NTot: N, sample size
%   Azims: Azimuths to be processed, in radians
%   Rbar: Mean vector length = sqrt(R2)/NTot
%   ThetaHat: Estimated mean vector direction, in degrees
%   KappaHat: Estimated concentration parameter
%   MeanKnown: Known or hypothesized vector mean, in degrees
%   KappaKnown: Known concentration parameter
%   Ck: sum(cos(Azims-MeanKnown))   (after conversion to radians)
%   fidO: output file for writing calculations
%   testalfa: Level of significance for tests: tabled only for
%             0.1, 0.05, 0.025, 0.01 for distributional tests
%   flags: List of calculations to be made (see above)
%   NColAz: column in data containing class azimuth
%   NColFrq: column in data containing grouped counts
%   AzData: input data array
% Output variable:
%   RtrnCode: Error return

% Functions and scripts called from this module:
%   ReylTest.m
%   Vector_Stats_CDF.m
%   U2test.m
%   U2testG.m


% set up for calculations and print lines

RtrnCode = 0;
ThetaHatR = ThetaHat/57.3;
% find nearest tabled value to specified alfa
alfalist = [0.1, 0.05, 0.025, 0.01];
tblalfa = alfalist(1);  diff = abs(testalfa - tblalfa);
for iii = 2:4;
    dd = abs(testalfa - alfalist(iii));
    if dd < diff
        diff = dd;
        tblalfa = alfalist(iii);
    end
end

ptskip=sprintf('\n');
ptminus=sprintf('-------------------------------------------------\n');

% -------------------------------------------------------------

if flags(1) == 1
    
 % TESTS OF UNIFORMITY

    disp(ptskip); disp(ptminus); disp(ptskip)
    pt1 = sprintf(['Rayleigh tests of hypothesis\n', ...
            'Ho: Data are from uniform distribution\n', ...
            'Alt.: Data are from unimodal distribution\n']);
    disp(pt1); disp(ptskip)
    if fidO > 0
        fprintf(fidO, ptskip); fprintf(fidO, ptminus);
        fprintf(fidO, ptskip); fprintf(fidO, pt1);
        fprintf(fidO, ptskip); fprintf(fidO, ptskip); 
    end

% Rayleigh test for uniformity - Vector mean unknown
% Mardia and Jupp, 2000, p. 94 - 98; Fisher, 1993, p. 70

   %RaylValue1 = RaylTest(NTot, alfa, 1);
   alfa = testalfa;
   cutoff = chi2inv(1 - alfa, 2);
   Sstar = (2*NTot - 1)*Rbar^2 + NTot*Rbar^4/2;
   if Sstar >= cutoff
       TestUnifHo1 = '     Reject uniformity hypothesis';
   else
       TestUnifHo1 = '     Cannot reject uniformity hypothesis';
   end
   PVal = 1 - chi2cdf(Sstar, 2);
   
   pt1=sprintf(['Assume vector-mean unknown\n', ...
                '(Ref.: Mardia and Jupp, 2000, p. 94-98)\n']);
   pt3=sprintf('     Calculated Sstar test statistic = %.4g\n', Sstar);
   pt4=sprintf('     Significance level (alfa) = %.3f\n', alfa);
   pt5=sprintf('     Test cutoff = %.4g\n', cutoff);
   pt6=sprintf('     P-value = %.4f\n', PVal);
   disp(pt1); 
   disp(pt3); disp(pt4); disp(pt5)
   disp(TestUnifHo1); disp(' '); 
   disp(pt6); disp(ptskip)
   if fidO > 0
       fprintf(fidO, pt1); 
       fprintf(fidO, pt3);
       fprintf(fidO, pt4); fprintf(fidO, pt5);
       fprintf(fidO, TestUnifHo1); fprintf(fidO, ptskip);
       fprintf(fidO, pt6); fprintf(fidO, ptskip); 
   end     
   
% Rayleigh test for uniformity - Vector mean assumed known
% Mardia and Jupp, 2000, p. 98 - 99; Fisher, 1993, p. 69

   Cmnk = Ck/NTot;
   if NTot > 50
       alfa = testalfa;
   else
       alfa = tblalfa;
   end
   RaylValue2 = RaylTest(NTot, alfa, 2);
   if abs(Cmnk) >= RaylValue2
       TestUnifHo2 = '     Reject uniformity hypothesis';
   else
       TestUnifHo2 = '     Cannot reject uniformity hypothesis';
   end
   PV = 2*NTot*Cmnk^2; PVal = 1 - chi2cdf(PV, 1);
   
   pt1=sprintf(['Assume vector-mean known = %.1f\n', ...
                '(Ref.: Mardia and Jupp, 2000, p. 98-99)\n'], ...
                MeanKnown);
   pt3=sprintf('     Calculated Cbar test statistic = %.4g\n', Cmnk);
   pt4=sprintf('     Significance level (alfa) = %.3f\n', alfa);
   pt5=sprintf('     Test cutoff = %.4g\n', RaylValue2);
   pt6=sprintf('     Asymptotic P-value = %.4f\n', PVal);
   disp(pt1); 
   if RaylValue2 > -5
       disp(pt3); disp(pt4); disp(pt5); 
       disp(TestUnifHo2); disp(' '); 
   else
       ptalfa=sprintf('     No test: Invalid alfa (%.4f)\n', alfa);
       disp(ptalfa)
   end
   disp(pt6); disp(ptskip)
   if fidO > 0
       fprintf(fidO, pt1); 
       if RaylValue2 > -5
           fprintf(fidO, pt3);
           fprintf(fidO, pt4); fprintf(fidO, pt5);
           fprintf(fidO, TestUnifHo2); fprintf(fidO, ptskip); 
       else
           fprintf(fidO, ptalfa);
       end
       fprintf(fidO, pt6); fprintf(fidO, ptskip); fprintf(fidO, ptskip);
   end  
    
   if NColFrq == 0
   
    % U-square test for goodness of fit with uniform CDF values
    % Watson, 1961, Biometrika, p. 109 - 114
    % Mardia and Jupp, 2000, p. 104

    pt1 = sprintf(['Test of hypothesis \n', ...
                   'Ho: Data are from uniform distribution\n',...
                   'Alt.: Data are from general distribution\n']);
    pt0 = sprintf(['U-squared test using CDF of uniform distribution\n',... 
                  '(Refs.: Watson, 1961, Biometrika, p 113 (26)\n', ...
                  '        Mardia and Jupp, 2000, p. 104)\n']);
    alfa = tblalfa;
    pipi = 2*pi;
    
    disp(ptskip); disp(ptminus); disp(ptskip)
    disp(pt1); disp(pt0); 
    if fidO > 0
        fprintf(fidO, ptskip); fprintf(fidO, ptminus);
        fprintf(fidO, ptskip); fprintf(fidO, pt1);
        fprintf(fidO, ptskip); 
        fprintf(fidO, pt0); 
    end
    
      % get CDF for all of data and sort into order    
    CDFsort = sort(Azims)/pipi;
    CDFAvg = sum(CDFsort)/NTot;
    
      % calculate and test 
    U2 = 0;
    for iii = 1: NTot
        U2 = U2 + (CDFsort(iii) - (2*iii - 1)/(2*NTot) - CDFAvg + 0.5)^2;
    end
    U2 = U2 + 1/(12*NTot);
    Ustar2 = (U2 - 0.1/NTot + 0.1/NTot^2)*(1 + 0.8/NTot);
    cutoff = U2test(0, alfa, 0);
    if Ustar2 >= cutoff
       TestU2 = '     Reject uniformity hypothesis';
   else
       TestU2 = '     Cannot reject uniformity hypothesis';
   end

     % output
   if cutoff > -5  
      pt3=sprintf('     Calculated Ustar2 test statistic = %.4g\n', Ustar2);
      pt4=sprintf('     Significance level (alfa) = %.3f\n', alfa);
      pt5=sprintf('     Test cutoff = %.4g\n', cutoff);
      disp(pt3); disp(pt4); disp(pt5)
      disp(TestU2); 
  else
      ptalfa=sprintf('     No test: Invalid alfa (%.4f)\n', alfa);
      disp(ptalfa)
  end
  disp(ptskip)
   if fidO > 0
       if cutoff > -5
          fprintf(fidO, pt3); fprintf(fidO, pt4); fprintf(fidO, pt5);
          fprintf(fidO, TestU2); 
      else
          fprintf(fidO, ptalfa);
      end
      fprintf(fidO, ptskip); 
   end   
   
   else
    
    % U-square test for goodness of fit with discrete uniform CDF values
    % Choulakian et al, 1994, Canadian Jour Stats, p. 125 - 137
    % Mardia and Jupp, 2000, p. 116 - 117

    pt1 = sprintf(['Test of hypothesis \n', ...
                   'Ho: Data are from discrete, uniform distribution\n',...
                   'Alt.: Data are from general, discrete distribution\n']);
    pt0 = sprintf(['U-squared test using class-interval data and uniform\n', ...
                   '(Refs.: Choulakian et al, 1994, Canadian Jour Stats,', ...
                   ' p. 125 - 137\n', ...
                   '        Mardia and Jupp, 2000, p. 116 - 117)\n']);
    alfa = tblalfa;
    pipi = 2*pi;
    
    disp(ptskip); disp(ptminus); disp(ptskip)
    disp(pt1); disp(pt0); 
    if fidO > 0
        fprintf(fidO, ptskip); fprintf(fidO, ptminus);
        fprintf(fidO, ptskip); fprintf(fidO, pt1);
        fprintf(fidO, ptskip); 
        fprintf(fidO, pt0); 
    end
    
      % get expected, observed, and calculated values    
      
    VObs = AzData(:, NColFrq);
    NClasses = size(VObs, 1);
    PPP = ones(1,NClasses)/NClasses  ;
    VExp = PPP*NTot;

     % calculate and test  
    
    SSS = zeros(1,NClasses);  TTT = SSS;
    SSS(1) = VObs(1);  TTT(1) = VExp(1);
    for iii = 2:NClasses
      SSS(iii) = SSS(iii-1) + VObs(iii);
      TTT(iii) = TTT(iii-1) + VExp(iii);
    end
    ZZZ = SSS - TTT;
    ZZB = sum(ZZZ*transpose(PPP));
    
    U2G = 0;
    for iii = 1:NClasses
        U2G = U2G + PPP(iii)*(ZZZ(iii) - ZZB)^2;
    end
    U2G = U2G/NTot;
    
    cutoff = U2testG(NClasses, alfa);
    if U2G >= cutoff
       TestU2 = '     Reject uniformity hypothesis';
   else
       TestU2 = '     Cannot reject uniformity hypothesis';
   end

     % output
   if cutoff > -5  
      pt3=sprintf('     Calculated U2G test statistic = %.4g\n', U2G);
      pt4=sprintf('     Significance level (alfa) = %.3f\n', alfa);
      pt5=sprintf('     Test cutoff = %.4g\n', cutoff);
      disp(pt3); disp(pt4); disp(pt5)
      disp(TestU2); 
  else
      ptalfa=sprintf('     No test: Invalid alfa (%.4f)\n', alfa);
      disp(ptalfa)
  end
  disp(ptskip)
   if fidO > 0
       if cutoff > -5
          fprintf(fidO, pt3); fprintf(fidO, pt4); fprintf(fidO, pt5);
          fprintf(fidO, TestU2); 
      else
          fprintf(fidO, ptalfa);
      end
      fprintf(fidO, ptskip); 
   end       
   
   clear SSS TTT ZZZ ZZB PPP VObs VExp
    
   end

end

% -------------------------------------------------------------

if flags(2) == 1
    
 % TEST FIT TO VON MISES DISTRIBUTION
 
 pt1 = sprintf(['Tests of hypothesis \n', ...
                'Ho: Data are from von Mises distribution\n']);
   
    % Test for goodness of fit with CDF values
    % Watson, 1961, Biometrika, p. 109 - 114
    % Fisher, 1993, p. 84 - 85 - contains typo in eq (4.35)

    pt0 = sprintf('U-squared tests using CDF of von Mises distribution\n');   
    alfa = tblalfa;
    
    % Case 0: Test assuming both Theta and Kappa are known
    
    disp(ptskip); disp(ptminus); disp(ptskip)
    pt1A=sprintf(['Assumes Theta known (%.1f) and Kappa known (%.4g)\n',...
             '(Refs.: Watson, 1961, Biometrika, p 113 (26)\n', ...
             '        Fisher, 1993, p. 84-85)\n'], ...
              MeanKnown, KappaKnown); 
    disp(pt1); disp(ptskip); disp(pt0); disp(ptskip); disp(pt1A); 
    if fidO > 0
        fprintf(fidO, ptskip); fprintf(fidO, ptminus);
        fprintf(fidO, ptskip); fprintf(fidO, pt1);
        fprintf(fidO, ptskip); 
        fprintf(fidO, pt0); fprintf(fidO, ptskip);
        fprintf(fidO, pt1A);   
    end
    
      % get CDF for all of data and sort into order
    Kap = KappaKnown;
    Thet = MeanKnown/57.3;
    
    CDFvals = Azims;   CDFvals = Vector_Stats_CDF(Azims, Thet, Kap);
    
    CDFsort = sort(CDFvals);
    CDFAvg = sum(CDFsort)/NTot;
    
      % calculate and test 
    U2 = 0;
    for iii = 1: NTot
        U2 = U2 + (CDFsort(iii) - (2*iii - 1)/(2*NTot) - CDFAvg + 0.5)^2;
    end
    U2 = U2 + 1/(12*NTot);
    Ustar2 = (U2 - 0.1/NTot + 0.1/NTot^2)*(1 + 0.8/NTot);
    cutoff = U2test(Kap, alfa, 0);
    if Ustar2 >= cutoff
       TestVM = '     Reject von Mises hypothesis';
   else
       TestVM = '     Cannot reject von Mises hypothesis';
   end

     % output
   if cutoff > -5  
      pt3=sprintf('     Calculated Ustar2 test statistic = %.4g\n',Ustar2);
      pt4=sprintf('     Significance level (alfa) = %.3f\n', alfa);
      pt5=sprintf('     Test cutoff = %.4g\n', cutoff);
      disp(pt3); disp(pt4); disp(pt5)
      disp(TestVM); 
  else
      ptalfa=sprintf('     No test: Invalid alfa (%.4f)\n', alfa);
      disp(ptalfa)
  end
  disp(ptskip)
   if fidO > 0
       if cutoff > -5
          fprintf(fidO, pt3); fprintf(fidO, pt4); fprintf(fidO, pt5);
          fprintf(fidO, TestVM); 
      else
          fprintf(fidO, ptalfa);
      end
      fprintf(fidO, ptskip); 
   end   

   
    % Case 3: Test assuming both Theta and Kappa are unknown
       
    disp(ptskip);  
    pt1A=sprintf(['Assumes both Theta and Kappa unknown\n', ...
               '(Refs.: Watson, 1961, Biometrika, p 113 (26)\n', ...
               '        Fisher, 1993, p. 84-85)\n']); 
    pt1B=sprintf('Warning: N should be at least 20\n');
    disp(pt1A); 
    if NTot < 20
        disp(pt1B);
    end
    if fidO > 0
        fprintf(fidO, ptskip); fprintf(fidO, pt1A);
        if NTot < 20
            fprintf(fidO, pt1B);
        end
    end
    
      % get CDF for all of data and sort into order
    Kap = KappaHat;
    
    CDFvals = Azims;   CDFvals = Vector_Stats_CDF(Azims, ThetaHatR, Kap);
    
    CDFsort = sort(CDFvals);
    CDFAvg = sum(CDFsort)/NTot;
    
      % calculate and test 
    U2 = 0;
    for iii = 1: NTot
        U2 = U2 + (CDFsort(iii) - (2*iii - 1)/(2*NTot) - CDFAvg + 0.5)^2;
    end
    U2 = U2 + 1/(12*NTot);
    cutoff = U2test(Kap, alfa, 3);
    if U2 >= cutoff
       TestVM = '     Reject von Mises hypothesis';
    else
       TestVM = '     Cannot reject von Mises hypothesis';
    end

     % output
   if cutoff > -5
       pt3=sprintf('     Calculated U2 test statistic = %.4g\n', U2);
       pt4=sprintf('     Significance level (alfa) = %.3f\n', alfa);
       pt5=sprintf('     Test cutoff = %.4g\n', cutoff);
       disp(pt3); disp(pt4); disp(pt5)
       disp(TestVM); 
   else
       ptalfa=sprintf('     No test: Invalid alfa (%.4f)\n', alfa);
       disp(ptalfa)
   end
   disp(ptskip)
   if fidO > 0
       if cutoff > -5
           fprintf(fidO, pt3); fprintf(fidO, pt4); fprintf(fidO, pt5);
           fprintf(fidO, TestVM); 
       else
           fprintf(fidO, ptalfa);
       end
       fprintf(fidO, ptskip); 
   end   
  
end   


