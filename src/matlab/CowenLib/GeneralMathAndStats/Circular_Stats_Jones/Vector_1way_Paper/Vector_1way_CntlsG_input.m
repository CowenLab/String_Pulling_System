%Vector_1way_CntlsG_input.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Driver for the GUI that obtains the controls that specify/define
% the dataset to be used (either external file or existing data array)

% Variables to be obtained and defaults:
%   NSkipHdr=0: Number of headers on data file to be skipped
%   NRows=0: Number of rows in data file (excluding headers)
%   NCols=0: Number of columns in data file
%   UseFrq = 0: Read individual azimuths (0) or count-freq (1) data
%   MissData = -99:  If indiv. azimuths, indicates missing data when
%            groups don't have equla counts
%   WrOut = 1: Write results to external file (1=No, 0=Yes)
%   DegRad = 0: Input azimuths in degrees (0) or radians (1)
%   Data_Array='AzData' or '': Name of input array that contains data
%   RtrnCode = 0: Error return

% Script called from this module:
%   Vector_1way_CntlsG.m

RtrnCode = 0;

% initialize variables to be obtained from GUI

    % input/output
NSkipHdr = 0;
NRows = 0;  NCols = 0;
UseFrq = 0; 
MissData = -99;
WrOut = 1;
DegRad = 0;
Data_Array=''; 
if datatype ~= 1
    slist = who;
    for iiii = 1:length(slist)
        if strcmp(slist(iiii),'AzData');
            Data_Array = 'AzData';
            break
        end
    end
end

     % calculation controls

% Loop over the GUI figure.  For each iteration,
% obtain values, check for errors, notify, re-call GUI

done=0;
while done==0
    
    % Get controls  
    
    Vector_1way_CntlsG
    
    disp(' '); disp('-----------------------------------------------')
    disp(' ')
    
    if RtrnCode == 8
        disp('Job cancelled by user')
        done = 1;
        return
    end
    
    %Check for errors/omissions on data file
    
    done = 1;

  if datatype == 1
        
       % Header skips
    if NSkipHdr < 0 
        done = 0;
        prt1=['ERROR *** Invalid number of headers to skip: ', ...
                num2str(NSkipHdr)];
        disp(prt1)
    end
    
       % Number columns in file
    if NCols <= 0
        done = 0;
        prt1=['ERROR *** Invalid number of columns in datafile: ', ...
                num2str(NCols)];
        disp(prt1)
    end
    
  else
    
    if ~isstr(Data_Array) 
        done = 0;
        disp('ERROR *** No name specified for data array to process')
    else 
        NRows = 0; NCols = 0;
        slist = who;
        for iiii=1:length(slist)
            if strcmp(slist(iiii), Data_Array)
               aaa = eval(Data_Array);
               [NRows,NCols] = size(aaa);
               break
            end
        end
            if NRows == 0
               done = 0;
               prt1=['ERROR *** Data-array with specified name ', ...
                     'does not exist: ',Data_Array];
               disp(prt1)
            end
    end
    
  end  
    
% end of loop over input GUI and error checking

end
    

% specify name of output file

if WrOut == 0
    
    [fileOut, pathOut] = uiputfile('*.txt','Specify output file');
    
    if ~isstr(fileOut)
        disp('No output file specified by user - Job cancelled')
        RtrnCode = 7;
        return
    end
    
end
