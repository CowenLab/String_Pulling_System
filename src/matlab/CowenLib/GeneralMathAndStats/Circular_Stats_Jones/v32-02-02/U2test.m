function  U2val = U2test(Kap, alfa, type)

%U2test.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Look up cutoff values for U2 test for vonMises goodness of fit
% Four tables given for the combinations of Theta and Kappa
% being known and unknown
% Three of the tables depend on known (or estimated) value of Kappa

% Variables input:
%   Kap: Concentration parameter known or estimated
%   alfa: Significance level  (0.10, 0.05, 0.025, 0.01)
%   type: Combination of parameters known and unknown
%         0=both known   OR   test for uniform distribution
%         1=theta known, kappa unknown
%         2=kappa known, theta unknown
%         3=both unknown

%Tables contain Kappa in col.1, cutoffs for various alfa in col.2-5
%  Alfa values are 0.10, 0.05, 0.025, 0.01
%  (from Fisher, 1993, p. 230)

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
 
if type == 0
    
    %Table0 - for type 0 - Theta, Kappa both known
    Table0 = [0.0  0.152 0.187 0.222 0.268]; 
    
    U2val = Table0(1,alfacol);
    return
    
end

if type == 1
    
    %Table1 - for type 1 - Theta known, Kappa unknown
    Table1 = [0.0  0.105 0.133 0.163 0.204;
              0.5  0.107 0.135 0.165 0.205;
              1.0  0.111 0.139 0.169 0.209;
              1.5  0.115 0.144 0.173 0.214;
              2.0  0.119 0.147 0.177 0.217;
              4.0  0.124 0.153 0.183 0.224;
              25.  0.127 0.157 0.187 0.228];
    if Kap > 25
        U2val = Table1(7,alfacol);
    else
        U2val = interp1(Table1(:,1), Table1(:,alfacol), Kap, 'cubic');       
    end
    return
    
end
          
if type == 2 
          
    %Table2 - for type 2 - Theta unknown, Kappa known
    Table2 = [0.0  0.105 0.133 0.163 0.204;
              0.5  0.107 0.135 0.165 0.205;
              1.0  0.111 0.139 0.169 0.209;
              1.5  0.116 0.144 0.174 0.214;
              2.0  0.119 0.148 0.177 0.218;
              4.0  0.122 0.151 0.181 0.221;
              25.  0.122 0.151 0.180 0.221];
    if Kap > 25
        U2val = Table2(7,alfacol);
    else
        U2val = interp1(Table2(:,1), Table2(:,alfacol), Kap, 'cubic');       
    end     
    return
    
end
          
if type == 3      
          
    %Table3 - for type 3 - Theta unknown, Kappa unknown
    Table3 = [0.0  0.052 0.061 0.069 0.081;
              0.5  0.056 0.066 0.077 0.090;
              1.0  0.066 0.079 0.092 0.110;
              1.5  0.077 0.092 0.108 0.128;
              2.0  0.084 0.101 0.119 0.142;
              4.0  0.093 0.113 0.132 0.158;
              25.  0.096 0.117 0.137 0.164];
    if Kap > 25
        U2val = Table3(7,alfacol);
    else
        U2val = interp1(Table3(:,1), Table3(:,alfacol), Kap, 'cubic');       
    end     

end
     