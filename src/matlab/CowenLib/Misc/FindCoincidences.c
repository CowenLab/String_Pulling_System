/* Noise = FindCoincidences(TST, Nevents, precision)
 * Find All the points that come in groups of at least Nevents within
 *  a precision of precision 
 * INPUTS: 
 * TST: sorted list of timestamps
 * Nevents: Number of events
 * precision: precision fo the coincidence
 *
 * OUTPUTS: 
 * Noise: index in TST of the coinciding points
 * 
 * batta 2000 
 * UNDER DEVELOPMENT
 */


#include "mex.h"
#include <math.h>
#include <matrix.h>
#include <string.h>

void mexFunction(
  int nOUT, mxArray *pOUT[],
  int nINP, const mxArray *pINP[])
{

  int  Nevents, i, j, start_block, n_elem;
  double *d, precision;
  double *data, *badpts;
  int Ndata, Nbad = 0;
  





  /* check number of arguments: expects 3 inputs, 1 output */
  if (nINP != 3)
    mexErrMsgTxt("Call with TST, Nevents, precision as inputs.");
  if (nOUT != 1)
    mexErrMsgTxt("Requires one output.");

  /* Check validity */

  if (mxGetM(pINP[0]) != 1 && mxGetN(pINP[0]) != 1)
    mexErrMsgTxt("TST must be a row or column vector");
  

  if (mxGetM(pINP[1]) * mxGetN(pINP[1]) != 1)
    mexErrMsgTxt("Nevents must be scalar");

  if (mxGetM(pINP[2]) * mxGetN(pINP[2]) != 1)
    mexErrMsgTxt("precision must be scalar");

  
  /* unpack inputs */
  Ndata = mxGetM(pINP[0]) * mxGetN(pINP[0]);
  data = (double *)mxGetPr(pINP[0]);
  
  d = (double *)mxGetPr(pINP[1]);
  Nevents = (int) *d;
  d = (double *)mxGetPr(pINP[2]);
  precision = *d;
  
  badpts = mxCalloc(Ndata, sizeof(double));
  
  i = 0;
  
  while(i < Ndata-1)
    {
      if((data[i+1] - data[i]) < precision) /* starts a block */
	{

	  
	  start_block = i;
	  n_elem = 2;
	  i++;
	  
	  
	  while((data[i+1] - data[start_block]) < precision && i < Ndata - 2)
	    {
	      i++;
	      n_elem++;
	    }
	  
	  if(n_elem >= Nevents)
	    {
	      	  mexPrintf("Found block at %d.\n", start_block);
	      for(j = 0; j < n_elem; j++)
		{
		  badpts[Nbad+j] = (double)(start_block + j + 1);
		}
	      Nbad += n_elem;
	    }
	}
      i++;
      
    }
  


  pOUT[0] = mxCreateDoubleMatrix(1, Nbad, mxREAL);

  d  = (double *) mxGetPr(pOUT[0]);
  memcpy(d, badpts, Nbad * sizeof(double));
  mxFree(badpts);
  



  
}
