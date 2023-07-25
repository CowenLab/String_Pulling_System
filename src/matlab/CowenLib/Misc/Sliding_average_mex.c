/*-----------------------------------
* sliding average.
* MEX file
* 

*
-----------------------------------*/

#include "mex.h"
#include <math.h>
#include <matrix.h>
//___________________________________________________________________________________
void moment(double data[], int n, double *ave, double *adev, double *sdev, double *var)
{
	//Given an array of data[1..n], this routine returns its mean ave, average deviation adev,
	//standard deviation sdev, variance var, skewness skew, and kurtosis curt. 
	// Numerical Recipes
	// It ignores any Nans in the data (they do not become part of the window sample size.)
	//void nrerror(char error_text[]);
	int j, actual_n = 0;
	double ep=0.0,s,p,ignore_code;
	//if (n <= 1) nrerror("n must be at least 2 in moment");
	//ignore_code = mxGetNaN();
	s=0.0; //First pass to get the mean.
	for (j=0;j<n;j++){ 
		if (!mxIsNaN(data[j])){
			s += data[j];
			actual_n++;
		}
	}
	*ave=s/actual_n;
	*adev=(*var)=0.0; //Second pass to get the first (absolute), second, third, and fourth moments of the deviation from the mean.
	for (j=0;j<n;j++) {
		if (!mxIsNaN(data[j])){
			*adev += abs(s=data[j]-(*ave));
			ep += s;
			*var += (p=s*s);
		}
	}
	*adev /= actual_n;
	*var=(*var-ep*ep/actual_n)/(actual_n-1); // Corrected two-pass formula.
	*sdev= sqrt(*var); // Put the pieces together according to the conventional definitions. 
}

void mexFunction(
				 int nOUT, mxArray *pOUT[],
				 int nINP, const mxArray *pINP[])
{
	int i,count;
	double *OUT_MN,*OUT_SD,*OUT_IX;
	double *IN;
	double ave,adev,sdev,var;
	int IN_length = 0;
	int edge_points;
	int OUT_length;
	int window_size;	
	int shift_amount;
	int last_pt;
	/*********************************************************/
	/* check number of arguments: expects 2 inputs, 1 output */
	/*********************************************************/
	if (nINP != 2 && nINP != 3)
		mexErrMsgTxt("Call with vector, windowsize,shiftamount. It will then move ahead by binsize bins.");
	if (nOUT != 3)
		mexErrMsgTxt("Requires 3 outputs: mn, sd, idx");
	
	/*******************/
	/*  unpack inputs  */
	/*******************/
	IN_length	= (int) mxGetNumberOfElements(pINP[0]);
	window_size = (int) mxGetScalar(pINP[1]);
	shift_amount = (int) mxGetScalar(pINP[2]);
		
	/****************/
	/* pack outputs *
	/****************/
	edge_points = (int) ceil(window_size/shift_amount) -1;
	OUT_length  = floor(1+(IN_length-window_size)/shift_amount) + 2*edge_points;
	pOUT[0] = mxCreateDoubleMatrix(OUT_length, 1, mxREAL);
	pOUT[1] = mxCreateDoubleMatrix(OUT_length, 1, mxREAL);
	pOUT[2] = mxCreateDoubleMatrix(OUT_length, 1, mxREAL);
	
	if (!pOUT[0]) 
		mexErrMsgTxt("Cannot create output array. Probably out of memory.");	

	IN = (double *) mxGetPr(pINP[0]);	
	OUT_MN = (double *) mxGetPr(pOUT[0]);
	OUT_SD = (double *) mxGetPr(pOUT[1]);
	OUT_IX = (double *) mxGetPr(pOUT[2]); // Index in original record (assuming average is from preceeding data)
	
	// If nothing is passed in, just return a vector of 0s.
	if (mxIsEmpty(pINP[0]) || mxIsEmpty(pINP[1]))
		return;
	
	// Start at the front and get the sub averages up to this point.
	for (i=0;i<edge_points;i++){
		moment(IN,(i+1)*shift_amount,&OUT_MN[i],&adev,&OUT_SD[i],&var );
		OUT_IX[i] = (i+1)*shift_amount;
	}
	// Start at the front and get the sub averages up to this point.
	i = 0;
	count =0;

	while(i < IN_length-window_size+1){
		moment(&IN[i],window_size,&OUT_MN[count+edge_points],&adev,&OUT_SD[count+edge_points],&var );
		OUT_IX[count+edge_points] = i+window_size;
		i = i + shift_amount;
		count++;
	}
	last_pt = i;
	// Start at the front and get the sub averages up to this point.
	for (i=0;i<edge_points;i++){
		moment(&IN[last_pt + i*shift_amount], window_size - (i+1)*shift_amount, &OUT_MN[i+count+edge_points], &adev, &OUT_SD[i+count+edge_points], &var );
		OUT_IX[i+count+edge_points] = last_pt + i*shift_amount+window_size - (i+1)*shift_amount;
	}

}
