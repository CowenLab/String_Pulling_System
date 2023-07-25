function [p_r,rm_s1] = Partial(qs1,qm,qs2, plotit)
%function [p_r,rm_s1] = Partial(qs1,qm,qs2, plotit)
%
% INPUT:
%    q matrices for each epoch.
%    an optional field to indicate whether to plot or not.
%
% OUPUT:
%    partial r, partialled for qs1
%    the r qm, qs1 (not partialled)

% cowen Thu Apr 15 16:17:26 1999 This is from bruce's code
% Sun Apr 18 17:37:17 1999 made it set NANs in the c matrix to 0

if nargin == 3
  plotit = 0;
else
  plotit = 1;
end

cs1  =[]; % these will contain the lower diag of the R matrices
cm  = [];
cs2 = [];


% compute the NxN R matrices
rs1 = corrcoef(qs1');
rm  = corrcoef(qm');
rs2 = corrcoef(qs2');

% extract the diagonals of the R matrices
% They become one large vector
[N,c] = size(qs1);
for k = 1:N-1
  cs1 = [cs1;diag(rs1,k)];
  cm = [cm;diag(rm,k)];
  cs2 = [cs2;diag(rs2,k)];
end

cs1(find(isnan(cs1))) = 0;
cm(find(isnan(cm))) = 0;
cs2(find(isnan(cs2))) = 0;

% Plot the correlations cs1 vs cm; cs2 vs m and diff vs m
if plotit
  figure; plot(cm,cs2,'ko'); axis([-.5,.5,-.5,.5]); title( 'post vs maze');xlabel('maze');ylabel('post');lsline % fit a line to the data
  [P4,S4] = polyfit(cm,cs2,1); % compute the slope and intercept of the line
  axis([-.15 .5 -.15 .5]);
  
  figure; plot(cm,cs1,'ko'); axis([-.5,.5,-.5,.5]); title( 'pre vs maze');xlabel('maze');ylabel('pre');lsline
  [P5,S5] = polyfit(cm,cs2,1);
  axis([-.15 .5 -.15 .5]);
  
  % This is not a partial
  figure; plot(cm,(cs2-cs1),'ko'); axis([-.5,.5,-.5,.5]);xlabel('maze');ylabel('post-pre'); title( 'post-prevs maze');lsline
  [P6,S6] = polyfit(cm,cs2,1);
  axis([-.15 .5 -.15 .5]);
end

% compute the correlations of the correlations
rm_s2 = diag(corrcoef(cs2,cm),1);
rm_s1 = diag(corrcoef(cs1,cm),1);
rs1_s2 = diag(corrcoef(cs1, cs2),1);
% compute the explained variance (EV) for m,s2|s1
a = sqrt((1 - rm_s1.^2).* (1 - rs1_s2.^2));
p_r = (rm_s2 - rm_s1.*rs1_s2) ./ a; 	% partial correlation coeff (r)  
                                        % of m_s2|s1 r^2 is explained variance.

%O = ones(size(cs1));
%[b1,bint1,r1,rint1,stats1] = regress(cm,[O, full(cs1), full(cs2)]);
%[b2,bint2,r2,rint2,stats2] = regress(cm,[O, full(cs1)]);
%[b3,bint3,r3,rint3,stats3] = regress(cm,[O, full(cs2)]);

%disp(['R^2 m|s1,s2 = ' num2str(stats1(1)) ' p = ' num2str(stats1(3))]);
%disp(['R^2 m|s1    = ' num2str(stats2(1)) ' p = ' num2str(stats2(3))]);
%disp(['R^2 m|s2    = ' num2str(stats3(1)) ' p = ' num2str(stats3(3))]);

%[values,partial_F]= partialF_full(full([0; cs1; cs2]),cm)

