function RtrnCode = Vector_1way_Analyze(AzData, IndepX, IndepName, ...
                                q, MaxIndep, AzFrq, UseFrq, MissData, ...
                                DegRad, fidO, DataTtl, alfa, flags, ...
                                NClasses, AzOrigin, LinSq, NB, BSRS)    

%Vector_1way_Analyze.m

% Copyright C 2009  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Extracts the data columns that are specified for the samples to be used
% in the calculations.  Puts them into array Azims for all use later in
% the script and converts to radians.  Does this for either azimuth 
% input or count-frequency data.
% Then calculates summary statistics and saves them in SummaryStats 
% for each sample and the total sample.  Calls routine to print the
% summaries.
% Calls routine that performs all the calculations.

% Input variables:
%   AzData: input data file, in degrees or radians
%   IndepX: sample col. numbers, ordered for the q columns of Azims
%   IndepName: identifiers of the samples
%   q: number of samples to be analyzed
%   MaxIndep: maximum column number input
%   AzFrq: number of column containing azimuths when UseFrq = 1
%   UseFrq: 0 = data input as individual azimuths
%           1 = data input as azimuth column, plus q columns of counts
%   MissData: Missing data code for samples having different N
%   DegRad: input azimuths input as degrees (0) or radians(1)
%   fidO: output file for writing calculations if fidO > 0
%   DataTtl: Title for data or job
%   alfa: Level of significance for tests: must be 0.1, 0.05, 0.025, 0.01
%         for tests of distributional form
%   flags: List of which calculations are to be made
%   NClasses: number of classes in rose diagram
%   AzOrigin: Edge azimuth of first class in rose diagram
%   LinSq: plot rose with linear (0), or square root (1), of counts
%   NB: number of bootstrap iterations
%   BSRS: do bootstraps even if not required by N (1) - else dont (0)
% Output variable:
%   RtrnCode: return code
% Generated variables:
%   Azims: Array of azimuths to be processed, in radians
%   CatName: Array of positions in IndepName list that corresponds to 
%            columns in Azims
%   SummaryStats: array of size q+1,8 containing calculated summary stats
%         for each of q samples and total combined sample (row q+1)
%         Columns contain:  1) sum(sines)     2) sum(cosines)     3) N
%            4) R-squared     5) R      6) R-bar    
%            7) Vector mean, theta (degrees)   8) Concentration (kappa) 

% Functions and scripts called from this module:
%   VectMean_arctan.m
%   CalcKappa.m
%   Vector_1way_Summary.m
%   Vector_1way_Calcs.m

RtrnCode = 0;

% set up arrays for holding summaries of data

[NR, NC] = size(AzData);

CatN = zeros(1,q);  CatC = zeros(1,q);  CatS = zeros(1,q);   
CatName = zeros(1,q); CorrK = zeros(1,q+1);
SummaryStats = zeros(q+1, 8);
if UseFrq > 0
    Azims = zeros(NR, q+1);
else
    Azims = zeros(NR, q);
end

% calculate information for the categories

if UseFrq == 0
    
    % input individual azimuths
  jjj = 0;
  for iii = 1:MaxIndep
    jj = IndepX(iii);
    if jj > 0
        jjj = jjj + 1;
        CatName(jjj) = iii;
        NNN = 0;  CS = 0;  CC = 0;
        for k = 1:NR
            if AzData(k, jj) > MissData
                NNN = NNN + 1;
                Az = AzData(k, jj);
                if DegRad == 0
                    Az = Az/57.3;
                end
                Azims(k, jjj) = Az;
                CC = CC + cos(Az);   CS = CS + sin(Az);
            else
                break
            end
        end
        CatN(jjj) = NNN;  CatS(jjj) = CS;   CatC(jjj) = CC;
    end   
  end

else
    
    % input class frequency data
  for k = 1:NR
       Az = AzData(k, AzFrq);
       if DegRad == 0;  Az = Az/57.3;  end;
       Azims(k, q+1) = Az;
  end
  
  jjj = 0;
  for iii = 1:MaxIndep
    jj = IndepX(iii);
    if jj > 0
        jjj = jjj + 1;
        CatName(jjj) = iii;
        NNN = 0;  CS = 0;  CC = 0;
        for k = 1:NR
            Frq = AzData(k, jj);
            if Frq > MissData
                NNN = NNN + Frq;
                Azims(k, jjj) = Frq;
                Az = Azims(k, q+1);
                CC = CC + Frq*cos(Az);   CS = CS + Frq*sin(Az);
            end
        end
        CatN(jjj) = NNN;  CatS(jjj) = CS;   CatC(jjj) = CC;
    end   
  end  
      
end

% compute and save basic statistics for categories

for jjj = 1:q
    CS = CatS(jjj);     CC = CatC(jjj);     NNN = CatN(jjj);
    R2 = CS^2 + CC^2;
    SummaryStats(jjj, 1) = CS;  SummaryStats(jjj, 2) = CC; 
    SummaryStats(jjj, 3) = NNN;
    SummaryStats(jjj, 4) = R2;  SummaryStats(jjj, 5) = sqrt(R2);
    SummaryStats(jjj, 6) = SummaryStats(jjj, 5)/NNN;
    SummaryStats(jjj, 7) = VectMean_arctan(CS, CC);
    Kap = CalcKappa(SummaryStats(jjj, 6), 0);
    %correction for bias and small sample - Fisher, 1993, p. 88 (4.41)
    if NNN < 18
       CorrK(jjj) = 1; 
       if Kap < 2
         KK = Kap - 2/(NNN*Kap);  
         if KK > 0; Kap = KK; else; Kap = 0.1; end
 %        Kap = max(Kap - 2/(NNN*Kap), 0);  problem if <= 0
       else
         Kap = Kap*(NNN - 1)^3 / (NNN + NNN^3);
       end
    end
    SummaryStats(jjj, 8) = Kap;
end

% compute and save basic statistics for Combined (total) samples

TotS = sum(CatS);    TotC = sum(CatC);    TotN = sum(CatN);
TotR2 = TotS^2 + TotC^2;  TotR = sqrt(TotR2);   
SummaryStats(q+1, 1) = TotS;   SummaryStats(q+1, 2) = TotC; 
SummaryStats(q+1, 3) = TotN;
SummaryStats(q+1, 4) = TotR2;  SummaryStats(q+1, 5) = TotR;
SummaryStats(q+1, 6) = TotR/TotN;
SummaryStats(q+1, 7) = VectMean_arctan(TotS, TotC);
Kap = CalcKappa(TotR/TotN, 0);
%correction for bias and small sample - Fisher, 1993, p. 88 (4.41)
if TotN < 18
   CorrK(q+1) = 1; 
   if Kap < 2
     Kap = max(Kap - 2/(TotN*Kap), 0);
   else
     Kap = Kap*(TotN - 1)^3 / (TotN + TotN^3);
   end
end
SummaryStats(q+1, 8) = Kap;

% output basic statistics 

RtrnCode = Vector_1way_Summary(IndepX, IndepName, q, ...
                               MaxIndep, CatName, SummaryStats, ...
                               CorrK, UseFrq, Azims, DataTtl, flags, ...
                               NClasses, AzOrigin, LinSq, fidO);

if RtrnCode == 15;  return;  end

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% NOTE: If you are inputting axial data, rather than vectorial, 
%       divide the vector means by two to get back to correct
%       orientation.  Most tests will be OK here, but some 
%       (including bootstrap) may not be handled completely by 
%       this single fix.

%SummaryStats(:,7)=SummaryStats(:,7)/2


% do the calculations
    
 RtrnCode = Vector_1way_Calcs(q, UseFrq, Azims, SummaryStats, flags, ...
                              NB, BSRS, ...
                              IndepName, CatName, alfa, fidO);
 

clear Azims CatName CatN CatS CatC SummaryStats
