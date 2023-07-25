%Vector_1way.m

% This script is described in the Computers & Geosciences paper:
%   MATLAB functions to analyze directional (azimuthal) data.
%   III. q-sample inference
%   by Thomas A. Jones

% Copyright C 2008-2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Calculates tests of equality of parameters that describe properties of
% directional data that represent vectors over a circle.  This is 
% analogous to one-way ANOVA or two-sample t-tests with linear data.
% The vectors input are in degrees, defined over the interval (0, 360) 
% (equivalent to (0, 2PI) radians).

% User controls primarily are specified via a GUI.

% Vector data may be read from an external ascii file, or in a 2D data
% array already in Matlab memory.  For both cases, Rows represent the 
% various data values (observations), and the columns contains the  
% data values for the various groups or categories (q of them).  
% If the data consist of the individual azimuths, then q of the columns
% each contain azimuths.  If dataset consists of count-frequency data,
% then one column represents the azimuths, and q additional columns 
% contain the counts of each of the azimuths.

% Calculations include:
%   Test if all q vector means for q groups are equal
%   Test if all q concetrations for q groups are equal
%   Confidence interval for difference of two vector means
%   Rose diagrams of each group and summary of the group vector means
 
% Commonly used variables in the functions include:
%   Theta, ThetaHat: relate to vector mean direction
%   Kappa, KappaHat: relate to concentration parameter
%   AzData: original data set input to the script (degrees or radians)
%   Azims: data vector used for calculations (in radians)
%   NTot: N, sample size
%   NB: number of resampling or bootstrapping iterations
%   fidO: output file for calculations (>0 implies write file)
%   RtrnCode: error return code
%    0 = OK
%    1 = Input data set could not be opened or not found
%    2 = Incorrect numbers of rows or columns specified for input dataset
%    3 = Could not open external output file for calculations
%    7 = User didn't specify name of external output file
%    8 = Job cancelled while inputting data controls
%    9 = Job cancelled while specifying calculations to be made
%   10 = Job cancelled while specifying initial estimates
%   15 = N too small for inference

% Functions and scripts called from this module:
%   Vector_DataTypeG.m
%   Vector_1way_CntlsG_input.m
%   Read_Reals_File.m
%   Vector_1way_CntlsDat_input.m
%   Vector_1way_SpecCalcsG_input.m
%   Vector_Stats_RoseCtl_input.m
%   Vector_1way_Analyze.m


% set up for job and printing

RtrnCode = 0;
fclose all;

pthdr=sprintf('ONE-WAY ANALYSIS FOR VECTORIAL DATA\n');
ptskip=sprintf('\n');
pteq=sprintf('==================================================\n');

disp(ptskip); disp(pteq); disp(ptskip); disp(pthdr); disp(ptskip); 

% determine if using data array or input external file
% get job title/description

datatype = 0;
DataTtl = '';
Vector_DataTypeG

disp(DataTtl); 

% Get name of external file to analyze

if datatype == 1
   disp(' '); disp(' ')
   disp('Specify external text file containing data')

   [fileIn,pathIn] = uigetfile('*.txt','Files of type txt');
   if ~isstr(fileIn)
       disp('No external file specified')
       RtrnCode=7;
       ptstop=sprintf('JOB TERMINATING: ReturnCode = %.0f \n',RtrnCode);
       disp(ptskip); disp(ptstop); disp(pteq); disp(ptskip)
       return
   end
end

% Input general controls on data set to be used  
    
Vector_1way_CntlsG_input
if RtrnCode > 0
    ptstop=sprintf('JOB TERMINATING: ReturnCode = %.0f \n',RtrnCode);
    disp(ptskip); disp(ptstop); disp(pteq); disp(ptskip)
    return
end

% Input controls on which columns in dataset to be used  
    
Vector_1way_CntlsDat_input
if RtrnCode > 0
    ptstop=sprintf('JOB TERMINATING: ReturnCode = %.0f \n',RtrnCode);
    disp(ptskip); disp(ptstop); disp(pteq); disp(ptskip)
    return
end

% Input data array or external file

if datatype == 0
    AzData = eval(Data_Array);
    ptdsnIn=['Name of input data array: ', Data_Array]; 
    disp(ptdsnIn);   disp(ptskip)
else
   dsnIn = [pathIn, fileIn];
   [RtrnCode, NRows, AzData] = Read_Reals_File(dsnIn, NSkipHdr, NCols);
   if RtrnCode > 0
      ptstop=sprintf('JOB TERMINATING: ReturnCode = %.0f \n',RtrnCode);
      disp(ptskip); disp(ptstop); disp(pteq); disp(ptskip)
      return
   end
   ptdsnIn=['Name of input data file: ', fileIn];
   disp(ptdsnIn);   disp(ptskip)
end

% open file to write calculations

fidO = -99;
if WrOut == 0
    dsnOut = [pathOut, fileOut];
    fidO = fopen(dsnOut, 'wt');
    if fidO < 0 
        RtrnCode = 3;
        disp('ERROR *** Output file could not be opened')
        ptstop=sprintf('JOB TERMINATING: ReturnCode = %.0f \n',RtrnCode);
        disp(ptskip); disp(ptstop); disp(pteq); disp(ptskip)
        return
    end
    disp(ptskip)
    ptdsnOut=['File opened for output: ', fileOut];
    
    % write job-headers info to file

    fprintf(fidO, ptskip);   fprintf(fidO, [pthdr,'\n']);
    fprintf(fidO, ptskip);
    
    fprintf(fidO, [DataTtl,'\n']); fprintf(fidO, ptskip);
    fprintf(fidO, [ptdsnIn,'\n']); fprintf(fidO, ptskip); 
    fprintf(fidO, ptskip);
end

% summarize information about data set

pt1=sprintf('Data array contains %.0f Rows and %.0f Columns', ...
             NRows, NCols);
if UseFrq == 0
   pt5=sprintf('Data in form of individual azimuths');
else
   pt5=sprintf(['Data in form of count frequencies of azimuth ', ...
                'class midpoints']);
   pt6=sprintf( 'Azimuths are in column %.0f of data file', AzFrq);
end
if DegRad == 0         
   pt2=sprintf('Azimuths are in Degrees');
else
   pt2=sprintf('Azimuths are in Radians');
end

disp(pt1); disp(ptskip); disp(pt5); 
if UseFrq > 0; disp(pt6); end;
disp(pt2); 

if fidO > 0
    fprintf(fidO, [pt1,'\n']); fprintf(fidO, ptskip); 
    fprintf(fidO, [pt5,'\n']); 
    if UseFrq > 0;  fprintf(fidO, [pt6,'\n']); end;
    fprintf(fidO, [pt2,'\n']);
end

% controls for output file

if fidO > 0
     disp(ptskip); disp(ptdsnOut); disp(ptskip); disp(ptskip);
    fprintf(fidO, ptskip); fprintf(fidO, ptskip);
    fprintf(fidO, [ptdsnOut,'\n']);  fprintf(fidO, ptskip); 
    fprintf(fidO, ptskip);    
end
    
% Specify calculations to be made

Vector_1way_SpecCalcsG_input     
if RtrnCode > 0
    ptstop=sprintf('JOB TERMINATING: ReturnCode = %.0f \n',RtrnCode);
    disp(ptskip); disp(ptstop); disp(pteq); disp(ptskip)
    if fidO > 0
        fclose(fidO)
    end
    return
end
flags = zeros(1:7);
flags(1) = Flag1A; flags(2) = Flag1B;
flags(3) = Flag2P;
flags(4) = Flag2A; 

% Controls for rose diagram

if Flag2P == 1
    Vector_Stats_RoseCtl_input
    if RtrnCode > 0
       ptstop=sprintf('JOB TERMINATING: ReturnCode = %.0f \n',RtrnCode);
       disp(ptskip); disp(ptstop); disp(pteq); disp(ptskip)
       if fidO > 0
           fclose(fidO)
       end
       return
    end
    
     % information on rose diagram
    
    ptminus=sprintf('-------------------------------------------------\n');
    pt1 = sprintf('Controls used to generate rose diagrams');
    pt2 = sprintf('   Number of classes = %.0f', NClasses);
    pt3 = sprintf('   Width of classes (degr.) = %.1f', 360/NClasses);
    pt4 = sprintf('   Origin of azimuths used for classes = %.1f', ...
                  AzOrigin);
    if LinSq == 0
       pt5 = sprintf('   Plot frequency for each class');
    else
       pt5 = sprintf('   Plot square-root(frequency) for each class');
    end
    
    disp(ptskip)
    disp(pt1); disp(ptskip)
    disp(pt2); disp(pt3); disp(pt4); disp(pt5); 
    
    if fidO > 0
       fprintf(fidO, ptskip); fprintf(fidO, ptminus); 
       fprintf(fidO, ptskip); 
       fprintf(fidO, [pt1,'\n']); fprintf(fidO, ptskip); 
       fprintf(fidO, [pt2,'\n']); fprintf(fidO, [pt3,'\n']); 
       fprintf(fidO, [pt4,'\n']); fprintf(fidO, [pt5,'\n']); 
       fprintf(fidO, ptskip); 
   end
else
    NClasses = 0; AzOrigin = 0; LinSq = 0;
end    

% Set up dataset (including for use with Class Frequencies) 
% and get basic statistics

q = NIndepX;
RtrnCode = Vector_1way_Analyze(AzData, IndepX, IndepName, ...
                          q, MaxIndep, AzFrq, UseFrq, MissData,...
                          DegRad, fidO, DataTtl, alfa, flags, ...
                          NClasses, AzOrigin, LinSq, NB, BSRS);

disp(' ');
if RtrnCode == 0 
    disp('JOB COMPLETED');
end
disp('======================================================')
disp(' ')
if fidO > 0
    fclose(fidO);
end



