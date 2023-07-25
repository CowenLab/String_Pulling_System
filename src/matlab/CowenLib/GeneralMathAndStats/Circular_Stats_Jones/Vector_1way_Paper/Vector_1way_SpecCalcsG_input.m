%Vector_1way_SpecCalcsG_input.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced.
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Driver for GUI that obtains the controls that specify
% the calculations that are to be made.

% Variables to be obtained and defaults:
%   Flag1A=0: Test for equality of vector means if =1
%   Flag1B=0: Confidence interval on difference of vector means if =1
%   Flag2P=0: Generate plots if =1
%   Flag2A=0: Test for equality of concentrations, kappa, if =1
%   BSRS = 0: Do bootstrap calcs, even if not required by sample size
%   alfa=0.05: Signficance level; should be 0.001 <= alfa <= 0.25
%   NB=500:  Number bootstrap (resampling) trials
%   RtrnCode=0: Error return

% Script called from this module:
%   Vector_1way_SpecCalcsG.m 

% initialize variables to be obtained from GUI

Flag1A=0;  Flag1B=0;
Flag2P=0;
Flag2A=0;  
BSRS = 0;
RtrnCode = 0;
alfa = 0.05;
NB = 1000;
 
% SPECIFY GENERAL CALCULATIONS
% Loop over the GUI figure.  For each iteration,
% obtain specified choices and values, check for errors, notify, re-call GUI

done=0;
while done==0
    
    % Get controls  
    
    Vector_1way_SpecCalcsG
    
    if RtrnCode == 9
        disp('Job cancelled by user')
        done = 1;
        return
    end
    
    %Check for errors/omissions
    
    done = 1;

       % alfa 
    if Flag1A == 1 | Flag1B == 1 | Flag2A == 1    
      if  alfa > 0.25 | alfa < 0.001
        done = 0;
        prt1=['ERROR *** Invalid significance level (alfa): ', ...
                num2str(alfa)];
        disp(prt1)
        disp( 'Allowable values are in range (0.001, 0.25)') 
      end
    end

         % NB - Number of Trials for resampling
    if NB < 100 | NB > 10000 
        done = 0;
        prt1=['ERROR *** Invalid number of resampling trials: ', ...
                num2str(NB)];
        disp(prt1)
        disp( 'Allowable value is in range (100, 10000)') 
    end
    
end

