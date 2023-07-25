function [COEF, Rsq_full, Fval_full, TTAB, FITS, RES, Rsq_part, Fval_part] = lregress_partial(Y,X)

% LREGRESS_PARTIAL  Performs multiple linear regression analysis of Y on X
%           and provides partial F and partial R-squared values.
%           The partial tests in this function
%           leave one variable out of the model and then
%           look at the incremental increase in predictive power as that
%           variable is brought into the model, assuming all other
%           variables are already included.  We do this for each variable
%           (i.e., column) of the X input array.
%
%           The partial F tests the null hypothesis that the jth coefficient = 0.
%           Rejection of this hypothesis implies that Xj makes a
%           significant contribution to the predictability of Y when added
%           to the other variables in the equation.
%
%           Coefficient of partial determination, Rsq_part, measures the
%           marginal contribution of one X variable, when all others are
%           already included in the model.  Note that this number is the square 
%           of the coefficient of partial correlation.
%
%           Usage:
%
%           [COEF, Rsq_full, Fval_full, TTAB, FITS, RES, Rsq_part, Fval_part] = lregress_partial(Y,X)
%
%           Returns:
%
%           COEF - Coefficients COEF(1)=intercept
%                               COEF(2)=coef for first variable, etc
%           Rsq_full  - R-squared for full model
%           Fval_full - F-value for full model, probability of given F 
%           TTAB - Coefficients, standard deviations, T-values, two-tailed p values
%           FITS - Fitted values
%           RES  - Residuals
%           Rsq_part  - partial R-squared for each variable, taking into
%                       account all other variables in the model
%           Fval_part - partial F-value, probability of given partial F 
%                       the i-th row is an F value and associated p-value
%                       for the incremental increase in 
%                       explained variance when the i-th variable was added 
%                       into the model, assuming all others are already included.
%
% note: overall F is test of the hypothesis b0 = b1 = b2 = ... = bn = 0
%       hence, if it is significant, one of the coefficients is significantly 
%       different from zero.  It tells you there is *some* relationship between
%       the independent variables, Xi, and the dependent variable Y.
%       Serr is the root of the MSE, not sure what it means
%       I validated this routine, including the probability estimates
%       against SAS and numbers matched.  
% to plot data and overlaying regress line, simply omit return variables.

%  I use nomenclature and formulas from 
%       Neter, Wasserman and Kutner (1989)
%       Applied Linear Regression Models
%       Second Edition, 
%       Published by Irwin, Homewood, IL

% altered by david euston on 8/14/06.  Major revision of lregress using new
% formulas from above reference and including partial f statistic and
% determinant of partial correlation
% original lregress by: 
% M J Chlond - Nov 93
% m.chlond@uclan.ac.uk

% euston


% turn x and y into row vectors, to avoid confusion
	[n k] = size(X);
	if (k>n) X = X'; end;
	[n2 k2] = size(Y);
	if (k2>n2) Y = Y'; end;


%  identify dimensions

    [n k] = size(X) ;
    p = k+1;

%  solve normal equations

    X = [ ones(n,1) X ]   ;
    XTXI = inv(X'*X);
    COEF = XTXI*X'*Y ;

%  calculate sum of squares and mean squares
%  see page 240 of Neter et al.

    SSTO = Y'*Y - (1/n)*(Y'*ones(n,n)*Y);
    SSE = Y'*Y - COEF'*X'*Y;
    SSR = COEF'*X'*Y - (1/n)*(Y'*ones(n,n)*Y);
    MSR = SSR/(p-1);
    MSE = SSE/(n - p);
    
    
%  F and R-squared total

    Rsq_full = SSR/SSTO;
    f = MSR/MSE;
    p_fval = fdist(f,p-1,n-p);
    Fval_full = [f p_fval];

%  fitted values

    FITS = X*COEF ;

%  residuals

    RES = Y - FITS;
    
%  coeffs, s.d. of slopes and t-values

    Serr = (RES'*RES/(n-k-1))^.5 ;
    C = Serr^2*inv(X'*X)         ;
    C = sqrt(diag(C,0))       ;
    TTAB = [ COEF,C,COEF./C ] ;
    tvals = TTAB(:,3);
    for i = 1:length(tvals)
       pvals(i,1) = t2p(tvals(i),n-k);  
    end;
    TTAB = [TTAB pvals];

%  end of procedure

if k>1
    f_part = zeros(k,1);
    p_fval_part = zeros(k,1);
    Rsq_part = zeros(k,1);
    for i = 1:k
        red_coli = true(1,k+1);
        red_coli(i+1) = false;  % column 1 is all ones for intercept
        Xred = X(:,red_coli);
        
        XTXIred = inv(Xred'*Xred);
        COEFred = XTXIred*Xred'*Y ;

        SSEred = Y'*Y - COEFred'*Xred'*Y;
        SSExtra = (SSEred - SSE);  % extra sum of squares e.g., SSR(X1 | X2 X3)
                                   % this is the difference in sum of
                                   % squares when the one excluded variable
                                   % is added to the model
        f_part(i) = (SSExtra)/MSE;  % note numerator is divided by 1 df
        p_fval_part(i) = fdist(f_part(i),1,n-p);
        Rsq_part(i) = SSExtra/SSEred;
        
    end;
    Fval_part = [f_part p_fval_part];
else
    Rsq_part = [];
    Fval_part = [];
end;

% plot results
if (nargout==0 & size(X,2)==2)
   plot(X(:,2),Y,'o'); hold on;
   plot(X(:,2),FITS,'r');
   hold off;
end;
