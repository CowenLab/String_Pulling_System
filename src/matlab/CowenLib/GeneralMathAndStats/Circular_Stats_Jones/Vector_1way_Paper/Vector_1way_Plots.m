function RtrnCode = Vector_1way_Plots(UseFrq, Azims, q, ...
                         SummaryStats, fidO, DataTtl, ...
                         IndepName, CatName, NClasses, AzOrigin, LinSq)    

%Vector_1way_Plots.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Generate compass plot (category vector means) and rose diagrams           

% Input variables:
%   UseFrq: 0 = data input as individual azimuths
%           1 = data input as azimuth column, plus q columns of counts
%   Azims: Array of azimuths to be processed, in radians
%   q: number of samples to be analyzed
%   SummaryStats: array of size q+1,8 containing calculated summary stats
%         for each of q samples and total combined sample (row q+1)
%         Columns contain:  1) sum(sines)     2) sum(cosines)     3) N
%            4) R-squared     5) R      6) R-bar    
%            7) Vector mean, theta (degrees)   8) Concentration (kappa) 
%   fidO: output file for writing calculations if fidO > 0
%   DataTtl: Title for data or job
%   IndepName: identifiers of the samples
%   CatName: Array of positions in IndepName list that corresponds to 
%            columns in Azims
%   NClasses: number of classes in rose diagram
%   AzOrigin: Edge azimuth of first class in rose diagram
%   LinSq: plot rose with linear (0), or square root (1), of counts
% Output variable:
%   RtrnCode: return code

% Functions and scripts called from this module:
%   VectCircPlot2Az_1way.m

RtrnCode = 0;
close all;

fig_cnt = 0;
[NR, NC] = size(Azims);
CatN = SummaryStats(1:q, 3);

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% Rose diagrams showing directions of Azimuths for each category 

% loop over categories

for iii = 1:q
    
   CatLbl = mat2str(IndepName(CatName(iii), :));
              
   NNN = SummaryStats(iii,3);       Rbar = SummaryStats(iii,6);
   ThetaHat = SummaryStats(iii,7);  Kap = SummaryStats(iii,8);
   if UseFrq == 0
      Vect_Az = Azims(1:NNN, iii)*57.3;
   else
      Vect_Az = VectCnt2IndivAz(Azims, iii, 0);
   end
   
   fig_cntx = VectCircPlot2Az_1way(0, fig_cnt, Vect_Az, ...
                        ThetaHat, ...
                        IndepName, CatName, CatN, ...
                        NClasses, AzOrigin, LinSq);
   fig_cnt = fig_cntx;
   
   ptplot = sprintf(['Category %s\n', ...
                      'N = %.0f \n', ...
                      'R-bar = %.4f \n', ... 
                      'Vector mean (degr.) = %.1f \n', ...
                      'Concentration (Kappa) = %.4g \n'], ...
                       CatLbl, NNN, Rbar, ThetaHat, Kap); 
   text(-1.2, -1.05, ptplot)
   
   pthdr = sprintf(['%s: Category %s'], DataTtl, CatLbl);
   text(-0.6, 1.05, pthdr);
   
   axis off

end

clear Vect_Az

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% Rose diagrams showing directions of Azimuths of total combined sample

 CatLbl = mat2str(IndepName(CatName(iii), :));
             
 NNN = SummaryStats(q+1,3);       Rbar = SummaryStats(q+1,6);
 ThetaHat = SummaryStats(q+1,7);  Kap = SummaryStats(q+1,8);
 if UseFrq == 0
    Vect_Az = zeros(NNN, 1); 
    i1 = 1; i2 = 0;
    for iii = 1:q
      i2 = i2 + CatN(iii);  
      Vect_Az(i1:i2) = Azims(1:CatN(iii), iii);
      i1 = i2 + 1;  
    end
    Vect_Az = Vect_Az*57.3;
 else
    Vect_Az = VectCnt2IndivAz(Azims, 0, 0);
 end
   
 fig_cntx = VectCircPlot2Az_1way(0, fig_cnt, Vect_Az, ...
                        ThetaHat, ...
                        IndepName, CatName, CatN, ...
                        NClasses, AzOrigin, LinSq);
 fig_cnt = fig_cntx;
   
 ptplot = sprintf(['N = %.0f \n', ...
                   'R-bar = %.4f \n', ... 
                   'Vector mean (degr.) = %.1f \n', ...
                   'Concentration (Kappa) = %.4g \n'], ...
                    NNN, Rbar, ThetaHat, Kap); 
 text(-1.2, -1.05, ptplot);
 
 pthdr = sprintf(['%s: Total sample'], DataTtl);
 text(-0.6, 1.05, pthdr);
 
 axis off

clear Vect_Az

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% Compass diagram showing directions of Azimuths for each category 
    
   NNN = SummaryStats(1:q, 3);    CatTheta = SummaryStats(1:q, 7);  
   
   fig_cntx = VectCircPlot2Az_1way(1, fig_cnt, CatTheta,...
                        ThetaHat, ...
                        IndepName, CatName, CatN, ...
                        NClasses, AzOrigin, LinSq);
   fig_cnt = fig_cntx;
   
   pthdr = sprintf(['%s: Category vector means'], DataTtl);
   text(-0.6, 1.05, pthdr);
   
   axis off

