function RtrnCode = Vector_Stats_Plots(Azims, cosvals, sinvals, ...
    ThetaHat, KappaHat, fidO, NColAz, NColFrq, AzData, DataTtl, ptplot, ...
    NClasses, AzOrigin, LinSq)    

%Vector_Stats_Plots.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Generate compass plots and rose diagrams                (Figures 1, 2)
% Generate Q-Q plots for uniform and vonMises distributions   (Figure 3)

% Input variables:
%   Azims: Azimuths to be processed, in radians
%   cosvals, sinvals; cosines and sines of azimuths
%   ThetaHat: Estimated vector mean direction (degrees)
%   KappaHat: Estimated concentration parameter
%   fidO: output file for writing calculations
%   NColAz: column in AzData containing azimuths
%   NColFrq: column in AzData containg frequencies
%   AzData: input data file
%   DataTtl: Title for data or job
%   ptplot: Text to put on data plots (simple statistics)
%   NClasses: number of classes in rose diagram
%   AzOrigin: Edge azimuth of first class in rose diagram
%   LinSq: plot rose with linear (0), or square root (1), of counts
% Output variable:
%   RtrnCode: Error return code

% Functions and scripts called from this module:
%   VectCircPlot2Az.m
%   VonMises_quantiles.m

RtrnCode = 0;
close all;

ThetaHatR = ThetaHat/57.3;
NTot = length(Azims);
pipi = 2*pi;

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% Plots showing directions of Azimuths 
% Compass plot and rose diagram

fig_cnt = 0;

pthdr = sprintf('Analysis of vectorial data: %s', DataTtl);
Vect_Az = Azims*57.3;
[RtrnCode, fig_cntx] = VectCircPlot2Az(2, fig_cnt, Vect_Az, ThetaHat, ...
                        NColAz, NColFrq, AzData, pthdr, ...
                        NClasses, AzOrigin, LinSq);
fig_cnt = fig_cntx;

text(-1.2, -1.05, ptplot)
axis off

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% Q-Q plots

fig_cnt = fig_cnt + 1;
figure(fig_cnt)

     % uniform distribution
     % Fisher, 1993, p. 65-66

subplot(2,1,1)

% get sample and uniform quantiles
yy = sort(Azims)/pipi;
xx = transpose(1:NTot)/(NTot + 1);

% plot
plot(xx, yy, 'x'), axis([0 1  0 1]), axis square
xlabel('uniform quantiles'), ylabel('sample quantiles')
line([0 1], [0 1])

pthdr = ['Q-Q plots of vectorial data: ', DataTtl];
title(pthdr, 'FontSize',12);
pt10 = sprintf('Uniform \ndistribution');
text(-0.9, 0.70, pt10)

pt10 = sprintf('von Mises \ndistribution');
text(-0.9, -0.70, pt10)

     % vonMises distribution
     % Fisher, 1993, p. 82-83, 53-54 (Note discussion for axial data)
     
subplot(2,1,2)     

% get sample and vonMises quantiles
if (ThetaHatR > 0.5*pi & ThetaHatR < 1.5*pi)
    yyy = 0.5*(Azims - ThetaHatR);  
else
    yyy = Azims;
    for iii = 1:NTot
       if yyy(iii) > pi
           yyy(iii) = yyy(iii) - pipi;
       end
    end
    Thetadj = ThetaHatR;
    if Thetadj > pi
        Thetadj = Thetadj - pipi;
    end
    yyy = 0.5*(yyy - Thetadj);
end
zz = sin(yyy);
yy = sort(zz);

q = VonMises_quantiles(NTot, KappaHat);
q = sin(0.5*q);
xx = sort(q);

% plot
plot(xx, yy, 'x'), axis([-1 1  -1 1]), axis square
xlabel('vonMises quantiles'), ylabel('sample quantiles')
line([-1 1], [-1 1])

clear xx yy zz yyy pipi iii q Vect_Az