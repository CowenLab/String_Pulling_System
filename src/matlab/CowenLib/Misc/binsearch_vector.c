 /*-----------------------------------
 * binary search and a VECTOR of keys. - useful for very large data vectors that you don't want to reload for every elemnet in the key.
 * MEX file
  *cowen 2011 - added a check for an empty input matrix (input 1) as an empty matrix will cause it to fail.
   cowen 2006 - Goes sequentially through a sorted list of keys (input 2) and finds
    the matches in the reference data (input 1).
 * cowen 2003 - made it return the closest value.
 * binsearch.c ADR 1998
 * 
 * input: Data -- n x 1, assumed to be sorted
 *        key -- a sorted VECTOR (unlike binsearch.c)
 * output: indices into Data of the CLOSEST member.
 *
 * version 1.0 cowen
 -----------------------------------*/

#include "mex.h"
#include <math.h>
#include <matrix.h>

void mexFunction(int nOUT, mxArray *pOUT[],int nINP, const mxArray *pINP[])
{
  int n,nk,i;
  int start, end, mid;
  double *input,*key;
  double *data;
  double *result;
  
  /* check number of arguments: expects 2 inputs, 1 output */
  if (nINP != 2)
    mexErrMsgTxt("Call with Data, key as inputs.");
  if (nOUT != 1)
    mexErrMsgTxt("Requires one output.");

   /* unpack inputs */
  n = mxGetM(pINP[0]) * mxGetN(pINP[0]);
  if (n < 1)
    mexErrMsgTxt("EMPTY PATRIX PASSED IN AS ARG 1."); 
  
  
  data = (double *)mxGetPr(pINP[0]);
  input = (double *)mxGetPr(pINP[1]);
  nk = mxGetM(pINP[1]) * mxGetN(pINP[1]);
  pOUT[0] = mxCreateDoubleMatrix(mxGetM(pINP[1]), mxGetN(pINP[1]), mxREAL);
  key = (double *) mxGetPr(pOUT[0]);
  
  for (i=0;i<nk;i++)
      key[i] = input[i];

  /* binary search */
  start = 0;
  for (i=0;i<nk;i++)
  {
      end = n-1;
      while (start < (end-1))
      {
          mid = floor((start + end)/2);
          ///////////////////////////////
          /*fprintf(stderr, "binsearch (%.0f): %d(%.0f) %d(%.0f) %d(%.0f)\n",
           *key, start, data[start], mid, data[mid], end, data[end]);*/
          ///////////////////////////////
          if (key[i] == data[mid])
              start = end = mid;
          if (key[i] < data[mid])
              end = mid;
          if (key[i] > data[mid])
              start = mid;
      }
      ///////////////////////////////
      // Return the CLOSEST value. THIS IS NOT WORKING - well sometimes, but it is not consistent!!!
      ///////////////////////////////
      if ((key[i] - data[start]) > (data[end] - key[i]))
          start = end;
     // mexPrintf("k%g d%g",key[i],data[mid]);
      key[i] = start + 1;
     // mexPrintf("x%g ",key[i]);
  }
 
}

/*

  if (mxIsFinite(*key))
   {
    //binary search
	start = 0;
	end = n-1;
	while (start < (end-1))
		{
		mid = floor((start + end)/2);
		//fprintf(stderr, "binsearch (%.0f): %d(%.0f) %d(%.0f) %d(%.0f)\n",
		//key, start, data[start], mid, data[mid], end, data[end]);
		if ((*key) == data[mid])
			start = end = mid;
		if ((*key) < data[mid])
			end = mid;
		if ((*key) > data[mid])
			start = mid;
		}
	if (((*key) - data[start]) <= (data[end] - (*key)))
		*result = start + 1;
	else	
		*result = end + 1;
  }
  else //NaN or Inf
	  *result = mxGetNaN();

		 
*/
          

