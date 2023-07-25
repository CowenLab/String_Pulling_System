function  U2val = U2testG(NClasses, alfa)

%U2testG.m

% Copyright C 2005  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Look up cutoff values for U2G test for uniform, discrete (grouped)
% goodness of fit
% Table given for number of classes vs alfa

% Variables input:
%   NClasses: Number of discrete classes
%   alfa: Significance level  (0.10, 0.05, 0.025, 0.01)

% Tables contain NClasses in col.1, cutoffs for various alfa in col.2-5
%  Alfa values are 0.10, 0.05, 0.025, 0.01
%  (from Choulakian et al, 1994, Canadoian Jour stats, p. 128)

U2val = -999;

% determine which column to use for alfa

alfacol = 0;
if alfa == 0.10
    alfacol = 2;
else if alfa == 0.05
    alfacol = 3;
else if alfa == 0.025
        alfacol = 4;
    else if alfa == 0.01
            alfacol = 5;
        end
    end
end
end
    
if alfacol == 0
    return
end
          
    TableU = [3  0.171  0.222  0.273  0.341;
              4  0.165  0.209  0.252  0.309;
              5  0.161  0.201  0.241  0.294;
              6  0.158  0.197  0.235  0.286;
              8  0.156  0.193  0.230  0.278;
              10 0.154  0.191  0.227  0.275;
              20 0.152  0.188  0.223  0.270;
              40 0.152  0.187  0.222  0.269;
              99 0.152  0.187  0.222  0.268];
    if NClasses > 99
        U2val = TableU(9,alfacol);
    else
        U2val = interp1(TableU(:,1), TableU(:,alfacol), NClasses, 'cubic');       
    end     
    return
         
     