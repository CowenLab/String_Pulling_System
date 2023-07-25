
function  [RtrnCode, fig_cntx] = VectCircPlot2Az(typeplot, fig_cnt, ...
                 Vect_Az, VectorMean, NColAz, NColFrq, AzData, ...
                 DataLbl, NClasses, AzOrigin, LinSq)

%VectCircPlot2Az.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

% Generate circular plots for azimuthal data
%     Compass plot showing individual vectors
%     Rose diagram
% Plots are set up for Azimuths, with North = 0 and East = 90 degrees, etc
% Distinct from VectCircPlot2Cy for general cyclical data

% Input variables:
%   typeplot: 0=compass plot   1=rose diagram   2=both
%   fig_cnt: current count of figure number
%   Vect_Az: Vector of Azimuths to be processed, in degrees
%   VectorMean: Estimated Theta-hat (preferred direction), degr.
%   NColAz: column in AzData containing azimuths
%   NColFrq: column in AzData containg frequencies
%   AzData: input data file
%   DataLbl: Title for data or job
%   NClasses: number of classes in rose diagram
%   AzOrigin: Edge azimuth of first class in rose diagram
%   LinSq: plot rose with linear (0), or square root (1), of counts
% Output variable:
%   RtrnCode: Error return
%   fig_cntx: Returned count on figures (figure number of last)

RtrnCode = 0;
NSpokes = 12;
ClassInc = 360/NClasses;

% SET UP BASICS FOR BOTH TYPES OF PLOT

radius = 0.7;

% define circle

circleX = zeros(361,1);              circleY = zeros(361,1);
for iii = 1:361
    a = iii/57.3;
    circleX(iii) = sin(a)*radius;    circleY(iii) = cos(a)*radius;
end

% define ribs every 360/NSpokes degrees

ribsX = zeros(2*NSpokes,1);
ribsY = zeros(2*NSpokes,1);
AngInc = 360/NSpokes;
jjj = 1;
for iii = 1:NSpokes
    a = AngInc*(iii-1)/57.3;
    ribsX(jjj) = 0;                  ribsY(jjj) = 0;
    ribsX(jjj+1) = sin(a)*radius;    ribsY(jjj+1) = cos(a)*radius;
    jjj = jjj + 2;
end

% set up labels for azimuth values of ribs

Alblnum = 0: AngInc: 360-AngInc;
azlblX = zeros(NSpokes,1);
azlblY = zeros(NSpokes,1);
radiusx = radius*1.1;
for iii = 1:NSpokes
    a = AngInc*(iii-1)/57.3;
    azlblX(iii) = sin(a)*radiusx - 0.06;
    azlblY(iii) = cos(a)*radiusx;
end

% set up for Vector Mean

vmX = zeros(3,1);  vmY = zeros(3,1);
vmX(1) = sin((VectorMean - 1.5)/57.3)*radius;
vmY(1) = cos((VectorMean - 1.5)/57.3)*radius;
vmX(2) = sin((VectorMean)/57.3)*radius*1.15;
vmY(2) = cos((VectorMean)/57.3)*radius*1.15;
vmX(3) = sin((VectorMean + 1.5)/57.3)*radius;
vmY(3) = cos((VectorMean + 1.5)/57.3)*radius;

% --------------------------------------------------------

if typeplot > 0

% COMPASS PLOT    
    
   % set up data 

   sr = 0.90*radius;
   del = 1.25/57.3;
   if NColFrq == 0
      Nd = length(Vect_Az);
   else
      Nd = length(AzData);
      dela = 3./57.3;
      sra = 0.75*radius;
      acntX = zeros(Nd,1);     acntY = zeros(Nd, 1);
   end
   vectsX = zeros(5*Nd,1);     vectsY = zeros(5*Nd,1);
   jjj = 1;
   for iii = 1:Nd
      if NColFrq == 0 
         a = Vect_Az(iii)/57.3;
      else
         a = AzData(iii, NColAz)/57.3;
      end
      x = sin(a)*radius;
      y = cos(a)*radius;
      vectsX(jjj) = 0;
      vectsY(jjj) = 0;
      vectsX(jjj+1) = x;
      vectsY(jjj+1) = y;
      vectsX(jjj+2) = sin(a - del)*sr;
      vectsY(jjj+2) = cos(a - del)*sr;
      vectsX(jjj+3) = sin(a + del)*sr;
      vectsY(jjj+3) = cos(a + del)*sr;
      vectsX(jjj+4) = x;
      vectsY(jjj+4) = y;
      jjj = jjj + 5;
      if NColFrq > 0
         if a > 1.571 & a < 4.712
          acntX(iii) = sin(a - dela)*sra;
          acntY(iii) = cos(a - dela)*sra;
         else
          acntX(iii) = sin(a + dela)*sra;
          acntY(iii) = cos(a + dela)*sra;
         end
      end
   end

   % plot compass diagram

   fig_cnt = fig_cnt + 1;
   figure(fig_cnt)

   plot(0, 0, 'ko')
   axis([-1 1  -1 1]),  axis square
   line(circleX, circleY, 'Linestyle', '-', 'Color' , [0 0 0])
   line(ribsX, ribsY, 'Linestyle', ':', 'Color', [0 0 1])
   for iii = 1:NSpokes
       azlbl = num2str(Alblnum(iii));
       text(azlblX(iii), azlblY(iii), azlbl, 'Color', [0 0 0])
   end
   line(vmX, vmY, 'LineWidth', 3, 'Color', [0 0 0])
   line(vectsX, vectsY, 'Linestyle', '-', 'Color' , [0 0 0])
   if NColFrq > 0
       for iii = 1:Nd
           azlbl = num2str(AzData(iii, NColFrq));
           text(acntX(iii), acntY(iii), azlbl, 'Color', [0 0 1]);
       end
   end
   axis off
   title(DataLbl);
   
   clear vectsX vectsY acntX acntY

end

% ------------------------------------------------------------

if typeplot == 0 | typeplot == 2
    
% ROSE DIAGRAM    

   % set up data for rose sectors

   if AzOrigin == 0
         %   Origin of first class = 0
      Edges = transpose(0: ClassInc: 360);
      NCnt = histc(Vect_Az, Edges);   
   else
         %   Origin of first class not 0  
      if AzOrigin >= ClassInc
          del = fix(AzOrigin/ClassInc);
          if del > 0
              AzOrigin = AzOrigin - del*ClassInc;
          end
      end
      Edges = transpose(AzOrigin: ClassInc: AzOrigin+ClassInc*NClasses);
      NCnt = zeros(NClasses,1);
      for jjj = 1:length(Vect_Az)
          a = Vect_Az(jjj);
          if a < AzOrigin & a >= 0
              a = a + 360;
          end
          del = fix((a - AzOrigin)/ClassInc) + 1;
          NCnt(del) = NCnt(del) + 1;
      end
   end  
   
   %  set up for linear vs logarithms
   
   if LinSq == 0
       NM = max(NCnt); Nmax = fix(NM/10)*10 + 10;
   else
       NM = sqrt(max(NCnt)); Nmax = fix(NM/5)*5 + 5;     
   end
  
   %   put together the vectors for classes
   
   ndiminc = (2 + fix(1+ClassInc))*NClasses;
   roseX = zeros(ndiminc,1);      roseY = zeros(ndiminc,1);
   jjj = 1;
   for iii = 1:length(Edges)-1
      if NCnt(iii) > 0 
         Edg1 = Edges(iii); Edg2 = Edges(iii+1);
         roseX(jjj) = 0;   roseY(jjj) = 0;
         jjj = jjj + 1;
         if LinSq == 0
            radN = NCnt(iii)*radius/Nmax;
         else
            radN = sqrt(NCnt(iii))*radius/Nmax;
         end
         for ii = Edg1:Edg2
            a = ii/57.3;         
            roseX(jjj) = sin(a)*radN;     roseY(jjj) = cos(a)*radN;
            jjj = jjj + 1;
         end
      end
   end
   roseX(jjj) = 0;          roseY(jjj) = 0;

   % define inner circle for rose diagram

   circle2X = zeros(361,1);     circle2Y = zeros(361,1);
   radius2 = radius/2;
   for iii = 1:361
      a = iii/57.3;
      circle2X(iii,1) = sin(a)*radius2;
      circle2Y(iii,1) = cos(a)*radius2;
   end
   
   % set up to label circles
   
   clblX1 = 0.707*radiusx;     clblY1 = 0.707*radiusx;
   clblX2 = 0.707*radiusx/2;   clblY2 = 0.707*radiusx/2;
   clbl1 = sprintf('%.0f', Nmax);
   if LinSq == 0
      clbl2 = sprintf('%.0f', Nmax/2);
   else
      clbl2 = sprintf('%.1f', Nmax/2);
   end

   % plot rose diagram
  
   fig_cnt = fig_cnt + 1;
   figure(fig_cnt)
   
   plot(0, 0, 'ko')
   axis([-1 1  -1 1]),  axis square
   line(circleX, circleY, 'Color' , [0 0 0])
   line(ribsX, ribsY, 'Linestyle', ':', 'Color' , [0 0 1])
   for iii = 1:NSpokes
      azlbl = num2str(Alblnum(iii));
      text(azlblX(iii), azlblY(iii), azlbl, 'Color' , [0 0 0])
   end
   line(vmX, vmY, 'LineWidth', 3, 'Color' , [0 0 0])
   line(circle2X, circle2Y, 'Linestyle', ':', 'Color' , [0 0 1])
   text(clblX1, clblY1, clbl1, 'Color' , [0 0 1])
   text(clblX2, clblY2, clbl2, 'Color' , [0 0 1]) 
   line(roseX, roseY, 'Color' , [0 0 0])   
   if LinSq == 0
       text(0., -0.95, 'Frequencies plotted')
   else
       text(0., -0.95, 'Square-root(Freqs.) plotted')
   end

   axis off
   title(DataLbl);
   
   clear roseX roseY circle2X circle2Y NM
   
end

fig_cntx = fig_cnt;

clear circleX circleY ribsX ribsY azlblX azlblY 

