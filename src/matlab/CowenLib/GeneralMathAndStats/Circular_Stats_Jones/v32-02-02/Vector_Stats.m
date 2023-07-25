%Vector_Stats.m

% This script is described in the Computers & Geosciences paper:
%   MATLAB functions to analyze directional (azimuthal) data.
%   I. Single-sample inference
%   by Thomas A. Jones

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Calculates descriptive and inferential statistics for data that
% represent vectors over a circle.  The vectors input are in degrees,
% defined over the interval (0, 360) (equivalent to (0, 2PI) radians).

% User controls primarily are specified via a GUI.

% Vector data may be read from an external ascii file, or in a
% 2D data already in Matlab memory.  For both cases, Rows represent the 
% various data values (observations), and one of the columns contains 
% the Azimuth data.  A second column may optionally be used for grouped
% data, where the contents of the column are the class frequencies.

% Calculations include:
%   Plots of the vectors (rose diagrams and compass plots)
%   Q-Q plots of the data versus uniform and vonMises distributions 
%   Tests of hypothesis that the data are from the uniform distribution
%   Tests of hypothesis that the data are from the vonMises distribution
%   Tests of hypothesis regarding the vector mean direction
%   Confidence interval on the vector mean direction
%   Confidence interval on the concentration parameter
%   Separate the two vonMises distribution in a mixture

% Commonly used variables in the functions include:
%   Theta, ThetaHat, MeanKnown: relate to vector mean direction
%   Kappa, KappaHat, KappaKnown: relate to concentration parameter
%   Azims: data vector used for calculations (in radians)
%   NTot: N, sample size
%   NB: number of resampling iterations
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
%   Vector_Stats_CntlsG_input.m
%   Read_Reals_File.m
%   Vector_Stats_SpecCalcsG_input.m
%   Vector_Stats_RoseCtl_input.m
%   Vector_Stats_Setup.m
%   Vector_Stats_Calcs.m


% set up for job and printing

RtrnCode = 0;
fclose all;
NB = 200;     % number of bootstrap iterations

pthdr=sprintf('STATISTICAL ANALYSIS FOR VECTORIAL DATA\n');
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

   [fileIn,pathIn] = uigetfile('*.txt','Files of type txt',10,10);
   if ~isstr(fileIn)
       disp('No external file specified')
       RtrnCode=7;
       ptstop=sprintf('JOB TERMINATING: ReturnCode = %.0f \n',RtrnCode);
       disp(ptskip); disp(ptstop); disp(pteq); disp(ptskip)
       return
   end
end

% Input general controls on data set to be used  
    
Vector_Stats_CntlsG_input
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
    
% write job headers info to file

    fprintf(fidO, ptskip);   fprintf(fidO, pthdr);
    fprintf(fidO, ptskip);
    
    fprintf(fidO, [DataTtl,'\n']); fprintf(fidO, ptskip);
    fprintf(fidO, ptdsnIn);        fprintf(fidO, ptskip); 
    fprintf(fidO, ptskip);
end

% summarize information about data set

pt1=sprintf('Data array contains %.0f Rows and %.0f Columns\n', ...
             NRows, NCols);
if DegRad == 0         
   pt2=sprintf('Column %.0f contains Azimuths in Degrees\n', NColAz);
else
   pt2=sprintf('Column %.0f contains Azimuths in Radians\n', NColAz);
end
disp(pt1); disp(pt2);
if fidO > 0
    fprintf(fidO, pt1);    fprintf(fidO, pt2);
end
if NColFrq > 0
    pt3=sprintf('Column %.0f contains Class Frequencies\n', NColFrq); 
    disp(pt3);
    if fidO > 0
        fprintf(fidO, pt3);
    end
end

if fidO > 0
    disp(ptskip); disp(ptdsnOut); disp(ptskip)
    fprintf(fidO, ptskip);
    fprintf(fidO, ptdsnOut);       fprintf(fidO, ptskip); 
    fprintf(fidO, ptskip);    
end
    
% Specify calculations to be made

Vector_Stats_SpecCalcsG_input     
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
flags(4) = Flag2A; flags(5) = Flag2B; flags(6) = Flag2C;
flags(7) = Flag4A;

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
else
    NClasses = 0; AzOrigin = 0; LinSq = 0;
end    

% Set up dataset, including for use with Class Frequencies

Azims = Vector_Stats_Setup(AzData, NColAz, NColFrq, DegRad);
NR = length(Azims);

pt22 = sprintf('\nSample size: N = %.0f\n', NR);
disp(pt22)
if fidO > 0 
    fprintf(fidO, pt22);
end

% Compute statistics and tests

init_guesses = [InitKappa1, InitMean1/57.3, ... 
                InitKappa2, InitMean2/57.3, Propor1];
RtrnCode = Vector_Stats_Calcs(Azims, MeanKnown, KappaKnown, ...
    fidO, DataTtl, alfa, flags, init_guesses, MaxItr, TolerX, ...
    NColAz, NColFrq, AzData, NClasses, AzOrigin, LinSq, NB);

disp(' ');
if RtrnCode == 0 
    disp('JOB COMPLETED');
end
disp('==================================================')
disp(' ')
if fidO > 0
    fclose(fidO);
end



