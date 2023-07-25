%Vector_1way_CntlsDat_input.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Driver for GUI that obtains the controls that specify/define
% which columns in the data set define the various samples.
% Refers to either input file or existing data array.

% Variables to be obtained and defaults:
%   AzFrq = 0: If UseFrq=1, indicates number of column with Azimuths
%   X1 - X10 = 0: Column numbers containing azimuths (if UseFrq=0) or
%          frequency-counts (if Usefrq=1)
%   XName1 - XName10 = 'A' - 'J': Identifiers of the samples
%   RtrnCode = 0: Error return

% Script called from this module:
%   Vector_1way_CntlsG.m

RtrnCode = 0;

% initialize variables to be obtained from GUI

AzFrq = 0;
X1=0; X2=0; X3=0; X4=0; X5=0; X6=0; X7=0; X8=0; X9=0; X10=0; 
XName1='A'; XName2='B'; XName3='C'; XName4='D'; XName5='E'; XName6='F'; 
XName7='G'; XName8='H'; XName9='I'; XName10='J'; 
IndepX = zeros(1,10); 

% Loop over the GUI figure.  For each iteration,
% obtain values, check for errors, notify, re-call GUI

done=0;
while done==0
    
    % Get controls  
    
    Vector_1way_CntlsDat
    
    disp(' '); disp('-----------------------------------------------')
    disp(' ')
    
    if RtrnCode == 8
        disp('Job cancelled by user')
        done = 1;
        return
    end
    
    %Check for errors/omissions on data file
    
    done = 1;
  
    % load inputs into arrays for later
    
    NIndepX = 0; MaxIndep = 0;
    IndepX(1) = X1; IndepX(2) = X2; IndepX(3) = X3;
    IndepX(4) = X4; IndepX(5) = X5; IndepX(6) = X6; 
    IndepX(7) = X7; IndepX(8) = X8; IndepX(9) = X9;
    IndepX(10) = X10;  
    IndepName = str2mat(XName1, XName2, XName3, XName4, XName5, ...
                        XName6, XName7, XName8, XName9, XName10);
     
    % check inputs of variables for errors  
    
    for iii = 1:10  
      if IndepX(iii) ~= 0
            NIndepX = NIndepX + 1;
            MaxIndep = iii;
            
          % check validity of variables
           if IndepX(iii) > NCols
             done = 0;
             prt1=['ERROR *** Invalid column number for Category ', ...
                     IndepName(iii,:), '      ', num2str(iii)];
             disp(prt1);
             prt1=['          Col. specified > max columns in data: ',...
                   num2str(NCols)];
             disp(prt1);
          end
          if IndepX(iii) < 0
             done = 0;
             prt1=['ERROR *** Invalid column number for Category', ...
                     IndepName(iii,:), '     ', num2str(iii)];
             disp(prt1);
          end
      end
  end
  
  if UseFrq > 0
          % check validity of Azimuth column for Frequency data
           if AzFrq > NCols
             done = 0;
             prt1=['ERROR *** Invalid column number for Azimuth with ', ...
                    'frequency data: ', num2str(AzFrq)];
             disp(prt1);
             prt1=['          Col. specified > max columns in data: ',...
                   num2str(NCols)];
             disp(prt1);
          end
          if AzFrq < 0
             done = 0;
             prt1=['ERROR *** Invalid column number for Azimuth with ', ...
                   'frequency data: ', num2str(AzFrq)];
             disp(prt1);
          end
          if AzFrq == 0
             done = 0;
             prt1=['ERROR *** No column number specified for ', ...
                   'Azimuth with frequency data'];
             disp(prt1);
          end
  end
    
   % check if named < 2 Categories or if any numbers duplicated
  if NIndepX < 2
      done = 0;
      disp('ERROR *** Fewer than 2 Categories were specified');
  else
      for iii = 1:MaxIndep - 1
          for jjj = iii+1:MaxIndep
              if (IndepX(iii) == IndepX(jjj)) & (IndepX(iii) > 0) 
                  done = 0;
                  prt1=['ERROR *** Categories %0.f and', ...
                        ' %.0f specified with same column number'];
                  prt2=sprintf(prt1, iii, jjj);
                  disp(prt2);
              end
          end
      end
  end
  
  if UseFrq > 0
        for iii = 1:10
            if (IndepX(iii) == AzFrq) & AzFrq > 0
                  done = 0;
                  prt1=['ERROR *** Azimuth column %0.f and ', ... 
                        'Frequency column %.0f ', ...
                        'specified with same column number'];
                  prt2=sprintf(prt1, AzFrq, iii);
                  disp(prt2);
              end
        end
  end
 
  if done == 0
     disp(' '); 
     prt1=['Number of Categories specified: ',num2str(NIndepX)];
     disp(prt1);
      for iii = 1:MaxIndep
          prt1=['     ', IndepName(iii,:), '    ',num2str(IndepX(iii))];
          disp(prt1);
      end
      if UseFrq > 0
          prt1=['Azimuths used for frequency count data: ', ...
                 num2str(AzFrq)];
          disp(prt1);
      end
      disp(' ');
  end
 
% end of loop over input GUI and error checking

end
  
 
