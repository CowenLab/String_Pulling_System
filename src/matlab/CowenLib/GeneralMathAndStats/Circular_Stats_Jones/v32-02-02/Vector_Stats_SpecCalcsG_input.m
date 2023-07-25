%Vector_Stats_SpecCalcsG_input.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced.
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Driver for GUI that obtains the controls that specify
% the calculations that are to be made.

% Variables to be obtained and defaults:
%   Flag1A=0: Test for uniformity if =1
%   Flag1B=0: Test for vonMises distribution if =1
%   Flag2P=0: Generate plots if =1
%   Flag2A=0: Inference on vector mean, kappa known if =1
%   Flag2B=0: Inference on vector mean, kappa unknown if =1
%   Flag2C=0: Confidence interval on kappa if =1
%   Flag4A=0: Separate cout two components of mixture if =1
%   alfa=0.05: Signficance level; should be 0.1, 0.05, 0.025, 0.01
%              for testing distributional forms
%   MeanKnown=0: Known or hypothesized vector mean direction
%   KappaKnown: Known concentration parameter
%   InitMean1: Initial estimate of vector mean, component 1
%   InitKappa1: Initial estimate of Kappa, component 1
%   InitMean2: Initial estimate of vector mean, component 2
%   InitKappa2: Initial estimate of Kappa, component 2
%   Propor1=0.5: Initial estimate of proportion of componnent 1
%   MaxItr: Maximum iterations
%   TolerX: tolerance for iterations
%   RtrnCode=0: Error return

% Script called from this module:
%   Vector_Stats_SpecCalcsG.m 
%   Vector_Stats_InitEstMixG.m

% initialize variables to be obtained from GUI

Flag1A=0;  Flag1B=0;
Flag2P=0;
Flag2A=0;  Flag2B=0;  Flag2C=0;
Flag3A=0;
Flag4A=0;
MeanKnown = 0;
KappaKnown = 0;
RtrnCode = 0;
alfa = 0.05;
 InitMean1 = 0;  InitMean2 = 0;
 InitKappa1 = 0; InitKappa2 = 0;
 Propor1 = 0.5;
 MaxItr = 100;
 TolerX = 0.0001;

% SPECIFY GENERAL CALCULATIONS
% Loop over the GUI figure.  For each iteration,
% obtain specified choices and values, check for errors, notify, re-call GUI

done=0;
while done==0
    
    % Get controls  
    
    Vector_Stats_SpecCalcsG
    
    if RtrnCode == 9
        disp('Job cancelled by user')
        done = 1;
        return
    end
    
    %Check for errors/omissions
    
    done = 1;

       % alfa 
    if Flag1A == 1 | Flag1B == 1 | Flag2A == 1 | Flag2B == 1 | Flag2C ==1    
     if  alfa > 0.25 
        done = 0;
        prt1=['ERROR *** Invalid significance level (alfa): ', ...
                num2str(alfa)];
        disp(prt1)
        disp( 'Allowable values are in range (0.001, 0.25)') 
     end
    end

       % Known or hypothesized vector mean
    if Flag2A == 1 | Flag2B == 1
        if MeanKnown < 0 | MeanKnown > 360
         done = 0;
         prt1=['ERROR *** Invalid known/hypothesized vector mean: ', ...
                 num2str(MeanKnown)];
         disp(prt1)
         disp( '          Must be in range 0 - 360 degrees');
        end
    end
    
           % Known concentration parameter
    if Flag2A == 1 | Flag1B == 1 
        if KappaKnown <= 0 
         done = 0;
         prt1=['ERROR *** Invalid known concentration: ', ...
                 num2str(KappaKnown)];
         disp(prt1)
         disp( '          Must be positive');
        end
    end    
end


% FOR MIXED DISTRIBUTIONS, SET INITIAL ESTIMATES
% Loop over the GUI figure.  For each iteration,
% obtain specified choices and values, check for errors, re-call GUI

if Flag4A == 1

  done=0;
  while done==0
    
    % Get controls  
    
    Vector_Stats_InitEstsMixG
    
    if RtrnCode == 10
        disp('Job cancelled by user')
        done = 1;
        return
    end
    
    %Check for errors/omissions
    
    done = 1;

       % Initial estimate of vector mean, component 1
        if InitMean1 < 0 | InitMean1 > 360
         done = 0;
         prt1=['ERROR *** Invalid initial estimate, vector mean, ', ...
                 'component 1: ', num2str(InitMean1)];
         disp(prt1)
         disp( '          Must be in range 0 - 360 degrees');
        end
    
           % Initial estimate of concentration parameter, component 1
        if InitKappa1 <= 0 
         done = 0;
         prt1=['ERROR *** Invalid initial estimate, Kappa, ', ...
                 'component 1: ', num2str(InitKappa1)];
         disp(prt1)
         disp( '          Must be positive');
        end
        
       % Initial estimate of vector mean, component 2
        if InitMean2 < 0 | InitMean2 > 360
         done = 0;
         prt1=['ERROR *** Invalid initial estimate, vector mean, ', ...
                 'component 2: ', num2str(InitMean2)];
         disp(prt1)
         disp( '          Must be in range 0 - 360 degrees');
        end
    
           % Initial estimate of concentration parameter, component 2
        if InitKappa2 <= 0 
         done = 0;
         prt1=['ERROR *** Invalid initial estimate, Kappa, ', ...
                 'component 2: ', num2str(InitKappa2)];
         disp(prt1)
         disp( '          Must be positive');
        end
        
               % Same initial means
        if abs(InitMean1 - InitMean2) < 40 |    ...
           abs(InitMean1 - InitMean2) > 320
         done = 0;
         prt1=['ERROR *** Invalid initial mean estimates: ', ...
                  num2str(InitMean1), ', ', num2str(InitMean2)];
         disp(prt1)
         disp( '          Must differ by at least 45 degrees')
        end
               
               % Proportion of component 1
        if Propor1 < 0.05 | Propor1 > 0.95
         done = 0;
         prt1=['ERROR *** Initial proportion of component 1 invalid: ', ...
                 num2str(Propor1)];
         disp(prt1)
         disp( '          Should be in range 0.10 - 0.90')
        end
                     
               % Maximum iterations
        if MaxItr < 2
         done = 0;
         prt1=['ERROR *** Maximum number of iterations invalid: ', ...
                 num2str(MaxItr)];
         disp(prt1)
        end
                            
               % Tolerance for iterating
        if TolerX > 0.01
         done = 0;
         prt1=['ERROR *** Tolerance on fit invalid: ', ...
                 num2str(TolerX)];
         disp(prt1)
         disp('          Should be less than 0.01');
        end
        
        disp(' ')
  end

end

