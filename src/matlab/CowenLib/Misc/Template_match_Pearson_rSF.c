/*-----------------------------------
* Template match. SF is for SUPERFAST
* R = Template_match(Data,Templates)
* MEX file
* Data = each column is data (n_rows = n_samples) for a particular trial or channel, etc...
* Templates = a single vector of templates. For now. In the future, I would like to pass multiple templates.
* R = the Pearson's r, Rows = data, Cols = 
* For each column in Data, this program calculates the Pearson's r between the column to the templates in Templates. If
* more than one template is specified, then each column of R corresponds to the values produced to each of those templates.
* If Data and Tamplates have more than one

*
-----------------------------------*/

#include "mex.h"
#include <math.h>
#define TINY 1.0e-20
#define MAXIT 100
#define EPS 3.0e-7
#define FPMIN 1.0e-30

void pearsn_r(double *x, double *y, double ax, double ay, unsigned long n, double *r)
/*Given two arrays x[1..n] and y[1..n], this routine computes their correlation
coefficient r (returned as r), the significance level at which the null hypothesis of zero
correlation is disproved (prob whose small value indicates a significant correlation), and
Fisher?s z (returned as z), whose value can be used in further statistical tests as described above. */
{	
	unsigned long j;
	double yt=0,xt=0;
	double syy=0.0,sxy=0.0,sxx=0.0;
// WE COULD MAKE THIS SUUUUPER FAST IF WE KEEP THE LAST VALUES FOR Sxx Syy and Sxy and then subtract the first and add the most recent (like a ring buffer), just like I am doing with the mean.
	for (j=0; j<n ; j++) { //Compute the correlation coefficient.
		xt=x[j]-ax;
		//yt=y[j]-ay; // I should not do this as I already know the template value.
		sxx += xt*xt;
		syy += y[j]*y[j];
		sxy += xt*y[j];
		//mexPrintf("x%g y%g  ax %g ay %g xt %g yt %g sXX %g sYY %g sXY %g\n",x[j],y[j],ax,ay,xt,yt,sxx,syy,sxy);
	}
	*r = sxy / (sqrt(sxx * syy) + TINY);
}


void pearsn_r_with_prob(double *x, double *y, double ax, double ay, unsigned long n, double *r, double *prob, double *z)
/*Given two arrays x[1..n] and y[1..n], this routine computes their correlation
coefficient r (returned as r), the significance level at which the null hypothesis of zero
correlation is disproved (prob whose small value indicates a significant correlation), and
Fisher?s z (returned as z), whose value can be used in further statistical tests as described above. */
{	
	unsigned long j;
	double yt=0,xt=0,t,df;
	double syy=0.0,sxy=0.0,sxx=0.0;

	for (j=0; j<n ; j++) { //Compute the correlation coefficient.
		xt=x[j]-ax;
		//yt=y[j]-ay;
		sxx += xt*xt;
		syy += y[j]*y[j];
		sxy += xt*y[j];
		//mexPrintf("x%g y%g  ax %g ay %g xt %g yt %g sXX %g sYY %g sXY %g\n",x[j],y[j],ax,ay,xt,yt,sxx,syy,sxy);
	}

	*r = sxy / (sqrt(sxx * syy) + TINY);

	*z=0.5*log((1.0+(*r)+TINY)/(1.0-(*r)+TINY)); // Fisher’s z transformation.
	df=n-2;
	t=(*r)*sqrt(df/((1.0-(*r)+TINY)*(1.0+(*r)+TINY))); // Equation (14.5.5).
	*prob=betai(0.5*df,0.5,df/(df+t*t)); // Student’s t probability.
	/* *prob=erfcc(fabs((*z)*sqrt(n-1.0))/1.4142136) */
	// For large n, this easier computation of prob, using the short routine erfcc, would give approximately

	//mexPrintf("r %g\n",r);

}


float gammln(float xx)
//Returns the value ln[G(xx)] for xx > 0.
{
	double x,y,tmp,ser;
	static double cof[6]={76.18009172947146,-86.50532032941677,24.01409824083091,-1.231739572450155,0.1208650973866179e-2,-0.5395239384953e-5};
	int j;
	y=x=xx;
	tmp=x+5.5;
	tmp -= (x+0.5)*log(tmp);
	ser=1.000000000190015;
	for (j=0;j<=5;j++) ser += cof[j]/++y;
	return -tmp+log(2.5066282746310005*ser/x);
}
float factln(int n)
//Returns ln(n!).
{
	float gammln(float xx);
	//void nrerror(char error_text[]);
	static float a[101]; //A static array is automatically initialized to zero.
	if (n < 0) //nrerror("Negative factorial in routine factln");
	if (n <= 1) return 0.0;
	if (n <= 100) return a[n] ? a[n] : (a[n]=gammln(n+1.0)); //In range of table.
	else return gammln(n+1.0); //Out of range of table.
}
float betai(float a, float b, float x)
//Returns the incomplete beta function Ix(a, b).
{
	float betacf(float a, float b, float x);
	float gammln(float xx);
	//void nrerror(char error_text[]);
	float bt;
	if (x < 0.0 || x > 1.0) //nrerror("Bad x in routine betai");
	if (x == 0.0 || x == 1.0) bt=0.0;
	else //Factors in front of the continued fraction.
	bt=exp(gammln(a+b)-gammln(a)-gammln(b)+a*log(x)+b*log(1.0-x));
	if (x < (a+1.0)/(a+b+2.0)) // Use continued fraction directly.
	return bt*betacf(a,b,x)/a;
	else //Use continued fraction after making the symmetry transformation. 
	return 1.0-bt*betacf(b,a,1.0-x)/b;
}

float betacf(float a, float b, float x)
//Used by betai: Evaluates continued fraction for incomplete beta function by modified Lentz’s method (§5.2).
{
	//void nrerror(char error_text[]);

	int m,m2;
	float aa,c,d,del,h,qab,qam,qap;
	qab=a+b; // These q’s will be used in factors that occur in the coefficients (6.4.6). qap=a+1.0;
	qam=a-1.0;
	c=1.0; // First step of Lentz’s method.
	d=1.0-qab*x/qap;
	if (fabs(d) < FPMIN) d=FPMIN;
	d=1.0/d;
	h=d;
	for (m=1;m<=MAXIT;m++) {
		m2=2*m;
		aa=m*(b-m)*x/((qam+m2)*(a+m2));
		d=1.0+aa*d; // One step (the even one) of the recurrence.
		if (fabs(d) < FPMIN) d=FPMIN;
		c=1.0+aa/c;
		if (fabs(c) < FPMIN) c=FPMIN;
		d=1.0/d;
		h *= d*c;
		aa = -(a+m)*(qab+m)*x/((a+m2)*(qap+m2));
		d=1.0+aa*d; // Next step of the recurrence (the odd one).
		if (fabs(d) < FPMIN) d=FPMIN;
		c=1.0+aa/c;
		if (fabs(c) < FPMIN) c=FPMIN;
		d=1.0/d;
		del=d*c;
		h *= del;
		if (fabs(del-1.0) < EPS) break; //Are we done?
	}
	//if (m > MAXIT) nrerror("a or b too big, or MAXIT too small in betacf");
	return h;
}

//___________________________________________________________________________________


void mexFunction(
				 int nOUT, mxArray *pOUT[],
				 int nINP, const mxArray *pINP[])
{
	unsigned long i, Template_length, Data_length, Output_rows;
	double *OUT_r, *OUT_p, *OUT_z, *Data, *Template;
	/*********************************************************/
	double Template_mean = 0;
	double Data_mean = 0;
	double Data_sum = 0;

	/*********************************************************/
	/* check number of arguments: expects 2 inputs, 1 output */
	/*********************************************************/
	if (nINP != 2)
		mexErrMsgTxt("Call with Data matrix (n x vbl) and Template vector)");
	if (nOUT != 1 && nOUT !=3)
		mexErrMsgTxt("Requires 1 or 3 outputs");
	
	/*******************/
	/*  unpack inputs  */
	/*******************/
	Data = (double *) mxGetPr(pINP[0]);	
	Data_length	= (unsigned long ) mxGetNumberOfElements(pINP[0]);
	Template = (double *) mxGetPr(pINP[1]);	
	Template_length	= (unsigned long ) mxGetNumberOfElements(pINP[1]);
	//Data_rows       = (unsigned long ) mxGetM(pINP[0]);
	//Data_cols       = (unsigned long ) mxGetN(pINP[0]);
	Output_rows     = Data_length - Template_length + 1;
	/****************/
	/* pack outputs *
	/****************/
	pOUT[0] = mxCreateDoubleMatrix(Output_rows, 1, mxREAL);
	if (!pOUT[0]) 
		mexErrMsgTxt("Cannot create output array. Probably out of memory.");	
	
	OUT_r = (double *) mxGetPr(pOUT[0]);
	// If nothing is passed in, just return a vector of 0s.
	if (mxIsEmpty(pINP[0]) || mxIsEmpty(pINP[1]))
		return;
	// Determine the mean of the template
	Template_mean = 0;
	for (i=0;i<Template_length;i++){
		Template_mean = Template_mean + Template[i];
		//mexPrintf("%g ",Template[i]); 
	}
	Template_mean = Template_mean/Template_length;
	// Subtract the mean from the template. This way I do not need to do it each time when I 
        // compute the correlation coefficient. It will speed things up.
	for (i=0;i<Template_length;i++){
		Template[i] = Template[i] - Template_mean;
		//mexPrintf("%g ",Template[i]); 
	}


//	mexPrintf(" SUM %g ",Template_mean); 
//	mexPrintf("Out rows %i, tm mn %g n %i", Output_rows, Template_mean, Template_length);

	// Determine the mean of the data for the first match
	Data_sum = 0;
	for (i=0;i<Template_length;i++){
		Data_sum = Data_sum + Data[i];
	}
	Data_mean = Data_sum / Template_length;

	if (nOUT == 1)
	{ // simple correlation template match.
		pearsn_r(&Data[0], &Template[0], Data_mean, Template_mean, Template_length, &OUT_r[0]);
		// Slide over the data and calculate the r value...
		// This is very efficient as it only subtracts the last element and adds the next,
		// ignoring all in between.
		for (i=1;i < (Data_length - Template_length + 1);i++){
			Data_sum = Data_sum - Data[i-1] + Data[i + Template_length - 1];
			Data_mean = Data_sum/Template_length;
			// WE COULD MAKE THIS SUUUUPER FAST IF WE KEEP THE LAST VALUES FOR Sxx Syy and Sxy and then subtract the first and add the most recent (like a ring buffer), just like I am doing with the mean.

			pearsn_r(&Data[i], &Template[0], Data_mean, Template_mean, Template_length, &OUT_r[i]);
		}
	}else if (nOUT == 3)
	{ // return some estimate of confidence.
		pOUT[1] = mxCreateDoubleMatrix(Output_rows, 1, mxREAL);
		if (!pOUT[1]) 
			mexErrMsgTxt("Cannot create output array. Probably out of memory.");	
		pOUT[2] = mxCreateDoubleMatrix(Output_rows, 1, mxREAL);
		if (!pOUT[2]) 
			mexErrMsgTxt("Cannot create output array. Probably out of memory.");	
	
		OUT_p = (double *) mxGetPr(pOUT[1]);
		OUT_z = (double *) mxGetPr(pOUT[2]);

		pearsn_r_with_prob(&Data[0], &Template[0], Data_mean, Template_mean, Template_length, &OUT_r[0], &OUT_p[0], &OUT_z[0]);
		// Slide over the data and calculate the r value...
		// This is very efficient as it only subtracts the last element and adds the next,
		// ignoring all in between.
		for (i=1;i < (Data_length - Template_length + 1);i++){
			Data_sum = Data_sum - Data[i-1] + Data[i + Template_length - 1];
			Data_mean = Data_sum/Template_length;
			pearsn_r_with_prob(&Data[i], &Template[0], Data_mean, Template_mean, Template_length, &OUT_r[i], &OUT_p[i], &OUT_z[i]);
		}

	}


}
