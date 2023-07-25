function  RaylValue = RaylTest(N, alfa, flag)

%RaylTest.m

% Copyright C 2004  Thomas A. Jones.  All rights reserved.
% Everyone is granted permission to copy, modify, and redistribute
% this program, but under the condition that this copyright notice
% remain intact and the Computers & Geosciences source be referenced. 
% This software has been tested extensively, but is distributed 
% WITHOUT ANY WARRANTY.  The author does not accept responsibility
% for any possible consequences of using it.

%Look up cutoff values for Rayleigh R or C tests for uniformity

% Variables input:
%   N: sample size
%   alfa: signficance level to use
%   flag: =1 Rbar test for mean unknown    =2 Cbar test for mean known
% Variable output:
%   RaylValue:  Cutoff value for Rayleigh test (R or Cbar)

% -----------------------------------------------------------

if flag == 1

%TableR contains N in col.1, cutoffs for various alfa in col.2-6
%  Alfa values are 0.10, 0.05, 0.025, 0.01, 0.001 
%  (from Mardia, 1972, p. 300)

TableR = [5 .677 .754 .816 .879 .991; 
          6 .618 .690 .753 .825 .940;
          7 .572 .642 .702 .771 .891;
          8 .535 .602 .660 .725 .847;
          9 .504 .569 .624 .687 .808;
         10 .478 .540 .594 .655 .775;
         11 .456 .516 .567 .627 .743;
         12 .437 .494 .544 .602 .716;
         13 .420 .475 .524 .580 .692;
         14 .405 .458 .505 .560 .669;
         15 .391 .443 .489 .542 .649;
         16 .379 .429 .474 .525 .630;
         17 .367 .417 .460 .510 .613;
         18 .357 .405 .447 .496 .597;
         19 .348 .394 .436 .484 .583;
         20 .339 .385 .425 .472 .569;
         21 .331 .375 .415 .461 .556;
         22 .323 .367 .405 .451 .544;
         23 .316 .359 .397 .441 .533;
         24 .309 .351 .389 .432 .522;
         25 .303 .344 .381 .423 .512;
         30 .277 .315 .348 .387 .470;
         35 .256 .292 .323 .359 .436;
         40 .240 .273 .302 .336 .409;
         45 .226 .257 .285 .318 .386;
         50 .214 .244 .270 .301 .367;
        100 .15  .17  .19  .21  .26 ]; 
 
   RaylValue = -999;

   % determine which alfa column to use
   alfacol = 0;
   if alfa == 0.10
       alfacol = 2;
   else if alfa == 0.05
       alfacol = 3;
   else if alfa == 0.025
           alfacol = 4;
       else if alfa == 0.01
               alfacol = 5;
           else if alfa == 0.001
               alfacol = 6;
           end
           end
       end
   end
   end

   % get and return cutoff value for given N and alfa        

   if N <= 100    
       if alfacol > 0 
          RaylValue = interp1(TableR(:,1), TableR(:,alfacol), N, 'cubic'); 
       else
          return
       end
   else
       RaylValue = sqrt(chi2inv(1 - alfa, 2)/(2*N)); 
   end  

% ------------------------------------------------------------------

else
 
%TableC contains N in col.1, cutoffs for various alfa in col.2-5
%  Alfa values are 0.10, 0.05, 0.025, 0.01
%  (from Mardia and Jupp, 2000, p. 300)

TableC = [5 .413 .522 .611 .709; 
          6 .376 .476 .560 .652;
          7 .347 .441 .519 .607;
          8 .324 .412 .486 .569;
          9 .305 .388 .459 .538;
         10 .289 .368 .436 .512;
         11 .275 .351 .416 .489;
         12 .264 .336 .398 .468;
         13 .253 .323 .383 .451;
         14 .244 .311 .369 .435;
         15 .235 .301 .357 .420;
         16 .228 .291 .345 .407;
         17 .221 .282 .335 .395;
         18 .215 .274 .326 .384;
         19 .209 .267 .317 .374;
         20 .204 .260 .309 .365;
         21 .199 .254 .302 .356;
         22 .194 .248 .295 .348;
         23 .190 .243 .288 .341;
         24 .186 .238 .282 .334;
         25 .182 .233 .277 .327;
         30 .17  .21  .25  .30 ;
         35 .15  .20  .23  .28 ;
         40 .14  .18  .22  .26 ;
         45 .14  .17  .21  .25 ;
         50 .13  .16  .20  .23 ];
 
   RaylValue = -999;

   % determine which alfa column to use
   alfacol = 0;
   if alfa == 0.10
       alfacol = 2;
   else if alfa == 0.05
       alfacol = 3;
   else if alfa == 0.025
           alfacol = 4;
       else if alfa == 0.01
           alfacol = 5;
       end
       end
   end
   end

   % get and return cutoff value for given N and alfa        

   if N <= 50  
       if alfacol > 0
         RaylValue = interp1(TableC(:,1), TableC(:,alfacol), N, 'cubic');
       else
         return
       end
   else
       RaylValue = sqrt(chi2inv(1 - alfa, 1)/(2*N)); 
   end  
   
end    
     