%Vector_Stats_RoseCtl_input.m

% Copyright C 2005  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Driver for GUI that obtains the controls that specify/define
% the controls used to make a rose diagram

% Variables to be obtained and defaults:
%   NClasses: Number of classes in rose (4 - 36)
%   AzOrigin:  Origin of first class (0 - 360)
%   LinSq: Linear freq plot (0) or square-root(freq) (1)
%   RtrnCode = 0: Error return

% Script called from this module:
%   Vector_Stats_RoseCtl.m

% initialize variables to be obtained from GUI

NClasses = 12;
AzOrigin = 0;
LinSq = 0;
RtrnCode = 0;

% Loop over the GUI figure.  For each iteration,
% obtain values, check for errors, notify, re-call GUI

done=0;
while done==0
    
    % Get controls  
    
    Vector_Stats_RoseCtl
    
    if RtrnCode == 9
        disp('Job cancelled by user')
        done = 1;
        return
    end
    
    disp(' '); disp('-----------------------------------------------')
    disp(' ')
    
    if RtrnCode == 8
        disp('Job cancelled by user')
        done = 1;
        return
    end
    
    %Check for errors/omissions
    
    done = 1;
    
       % Number of classes
    if NClasses < 4 | NClasses > 36 
        done = 0;
        prt1=['ERROR *** Invalid number of classes in rose: ', ...
                num2str(NClasses)];
        prt2= '          Must be in range 4 - 36';
        disp(prt1); disp(prt2);
    end
    
       % Origin for Azimuths
    if AzOrigin < 0 | AzOrigin > 360
        done = 0;
        prt1=['ERROR *** Invalid Origin for Azimuths: ', ...
                num2str(AzOrigin)];
        prt2= '          Must be in range 0 - 360'; 
        disp(prt1); disp(prt2)
    end
  
end
