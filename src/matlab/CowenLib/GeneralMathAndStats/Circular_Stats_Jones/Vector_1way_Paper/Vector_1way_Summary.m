function RtrnCode = Vector_1way_Summary(IndepX, IndepName, q,...
                               MaxIndep, CatName, SummaryStats, ...
                               CorrK, UseFrq, Azims, DataTtl, flags, ...
                               NClasses, AzOrigin, LinSq, fidO)    

%Vector_1way_Summary.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Computes summaries of each of the q samples to be analyzed, as well as
% the total sample.  Labels with identifiers.  Then calls routine to 
% generate plots.

% Input variables:
%   IndepX: sample col. numbers, ordered for the q columns of Azims
%   IndepName: identifiers of the samples
%   q: number of samples to be analyzed
%   MaxIndep: maximum column number input
%   CatName: Array of positions in IndepName list that corresponds to 
%            columns in Azims
%   SummaryStats: array of size q+1,8 containing calculated summary stats
%         for each of q samples and total combined sample (row q+1)
%         Columns contain:  1) sum(sines)     2) sum(cosines)     3) N
%            4) R-squared     5) R      6) R-bar    
%            7) Vector mean, theta (degrees)   8) Concentration (kappa) 
%   CorrK: indicator of whether kappa were corrected for small sample
%   UseFrq: 0 = data input as individual azimuths
%           1 = data input as azimuth column, plus q columns of counts
%   Azims: Array of azimuths to be processed, in radians
%   DataTtl: Title for data or job
%   flags: List of calculations to be made (plot if flags(3)=1)
%   NClasses: number of classes in rose diagram
%   AzOrigin: Edge azimuth of first class in rose diagram
%   LinSq: plot rose with linear (0), or square root (1), of counts
%   fidO: output file for writing calculations if fidO > 0
% Output variable:
%   RtrnCode: return code

% Functions and scripts called from this module:
%   Vector_1way_Plots.m

RtrnCode = 0; 

ptskip=sprintf('\n');
ptminus=sprintf('---------------------------------------------------\n');

pt8=sprintf('Sample size too small for any inferences to be done');

% Same loop and code used for statistics for Categories and Total
   
disp(ptskip);  disp(ptminus);  disp(ptskip);
ptlb=sprintf('Estimates of standard parameters for each Category\n');
disp(ptlb);  disp(ptskip);

if fidO > 0
    fprintf(fidO, ptskip); fprintf(fidO, ptminus);  fprintf(fidO, ptskip);
    fprintf(fidO, ptlb); fprintf(fidO, ptskip);
end 

% loop over categories and total

for jjj = 1:q+1
    
    % labels for category vs total
    
    % category stats
    if jjj <= q
       Categ = mat2str(IndepName(CatName(jjj), :));
       pt21 = sprintf('Category: %s          Column %.0f \n', ...
                      Categ, CatName(jjj));  disp(pt21);
       if fidO > 0
           fprintf(fidO, pt21); fprintf(fidO, ptskip);
       end
    else
   % total combined stats  
       disp(ptskip);  disp(ptminus);  disp(ptskip);
       ptlb=sprintf('Estimates of parameters of total combined sample\n');
       disp(ptlb); disp(ptskip); 
       if fidO > 0
         fprintf(fidO, ptskip); fprintf(fidO, ptminus);  
         fprintf(fidO, ptskip);
         fprintf(fidO, ptlb);  fprintf(fidO, ptskip);
       end 
    end

    % calculated values 
    
    NTot = SummaryStats(jjj, 3);
    pt0=sprintf('   N = %.0f ' , NTot);                         
    pt1=sprintf('   C=sum(cosX) = %.5g     S=sum(sinX) = %.5g',...
                SummaryStats(jjj,2), SummaryStats(jjj,1)); 
    pt2=sprintf('   R-square = %.5g        R = %.5g ', ...
                SummaryStats(jjj,4), SummaryStats(jjj,5));   
    pt3=sprintf('   R-bar = %.4f ' , SummaryStats(jjj,6));             
    pt4=sprintf('   Vector mean (Theta-bar, deg.) = %.1f ', ...
                SummaryStats(jjj,7)); 
    if CorrK(jjj) == 0        
       pt5=sprintf('   Concentration (Kappa-hat) = %.5g ', ...
                   SummaryStats(jjj,8)); 
    else
       pt5=sprintf(['   Concentration (Kappa-hat) = %.5g ', ...
                    '(Small-sample corrected)'], ...
                   SummaryStats(jjj,8)); 
    end
%   Kappa-hat correction for small-sample bias - 
%   Ref.: Fisher, 1993, p. 88 (4.41)

    disp(pt0);
    disp(pt1);   disp(pt2);   disp(pt3);
    disp(pt4);   disp(pt5);   

     % check for special cases or problems
    if NTot < 5
        disp(ptskip); disp(pt8);
        RtrnCode = 15
    end

    if fidO > 0
        fprintf(fidO, [pt0, '\n']);
        fprintf(fidO, [pt1, '\n']); fprintf(fidO, [pt2, '\n']);
        fprintf(fidO, [pt3, '\n']); fprintf(fidO, [pt4, '\n']);
        fprintf(fidO, [pt5, '\n']); 
        if NTot < 5
          fprintf(fidO, ptskip); fprintf(fidO, [pt8, '\n']);
        end
        fprintf(fidO, ptskip);
    end    

disp(ptskip);

end

if RtrnCode == 15;  return;  end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% plots - directional 

if flags(3) == 1
        
    % plots 
    
    RtrnCode = Vector_1way_Plots(UseFrq, Azims, q, ...
                      SummaryStats, fidO, DataTtl, ...
                      IndepName, CatName, ...
                      NClasses, AzOrigin, LinSq);
    if RtrnCode > 0
       return
    end   
end
   
