%Vector_Stats_CntlsG_input.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Driver for GUI that obtains the controls that specify/define
% the dataset to be used (either external file or existing data array)

% Variables to be obtained and defaults:
%   NSkipHdr=0: Number of headers on data file to be skipped
%   NRows=0: Number of rows in data file (excluding headers)
%   NCols=0: Number of columns in data file
%   NColAz=0: Which column in data file/set contains Azimuths
%   NColFrq=0: Which column in data file/set contains Class Freqs 
%   WrOut = 1: Write results to external file (1=No, 0=Yes)
%   DegRad: Input azimuths in degrees (0) or radians (1)
%   Data_Array='AzData' or '': Name of array that contains data (degrees)
%   RtrnCode = 0: Error return

% Script called from this module:
%   Vector_Stats_CntlsG.m

% initialize variables to be obtained from GUI

NSkipHdr=0;
NRows=0;
NCols=0;
NColAz=0;
NColFrq=0;
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
RtrnCode = 0;

% Loop over the GUI figure.  For each iteration,
% obtain values, check for errors, notify, re-call GUI

done=0;
while done==0
    
    % Get controls  
    
    Vector_Stats_CntlsG
    
    disp(' '); disp('-----------------------------------------------')
    disp(' ')
    
    if RtrnCode == 8
        disp('Job cancelled by user')
        done = 1;
        return
    end
    
    %Check for errors/omissions
    
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
    
       % Number of column containing Azimuths
    prt1=['ERROR *** Invalid column number for Azimuth data: ', ...
            num2str(NColAz)];
    if NColAz <= 0 
        done = 0;
        disp(prt1)
    end
    if NColAz > NCols
        done = 0;
        disp(prt1)
        prt1=['          Col. specified > max columns in datafile: ', ...
                num2str(NCols)];
        disp(prt1)    
    end
    
       % Check consistency of Azimuth and Class-Frequency entries
    if NColFrq == NColAz
        done = 0;
        disp( 'ERROR *** Inconsistent column numbers specified for')
        prt1=['          Azimuth data (',num2str(NColAz),') and', ...
              ' Class-Frequency data (',num2str(NColFrq),')'];
        disp(prt1)
    end
    
        % Number of column containing Class Frequencies
    prt1=['ERROR *** Invalid column number for Frequency data: ',...
                num2str(NColFrq)];
    if NColFrq > NCols
        done = 0;
        disp(prt1)
        prt1=['          Col. specified > max columns in datafile: ',...
                num2str(NCols)];
        disp(prt1)
    end
    if NColFrq < 0
        done = 0;
        disp(prt1)
    end
    
end

% specify name of output file

if WrOut == 0
    
    [fileOut, pathOut] = uiputfile('*.txt','Specify output file',10, 10);
    
    if ~isstr(fileOut)
        disp('No output file specified by user - Job cancelled')
        RtrnCode = 7;
        return
    end
    
end
