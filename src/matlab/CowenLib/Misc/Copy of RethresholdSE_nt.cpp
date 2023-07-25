/*---------------------------------
* RethresholdSE_nt
* MEX file
* * Rethreshold the data. -- you can specify a range to rethreshold if you wish.
* input:
*    fn_in = input file name string
*    fn_out = output file name string
*    lower thresholds = a vector of length npts in wave that specifies the new lower thresholds.
*    upper thresholds = a vector of length npts in wave that specifies the new upper thresholds.
*    logic = 1 = positive logic. All points outside of range are eliminated. Anything else is
*      negative logic which means that only waveforms that fall within the range(every point must 
*      fall within the range) will be eliminated.
*
* output:
*    Just the waveforms in the output file
*
* version 5.1
*
* Reads both sun TTfiles and NT-TTfiles and distinguishes them
* by checking if a header exists (for sun TTfiles) or not (for NT-TTfiles)
*
* Checks for standard Neuralynx header if present (in Cheeath versions >= 1.3)
* and automatically skips header.
*
*
* TO DO: Do the binsearch on the file and not on the entire array of timestamps.
*
* cowen 4/14/01: Modified to allow partial loading.
* PL Sept 2000 
*--------------------------------*/

#include "mex.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <matrix.h>
#include <share.h> // for _fsopen flag.

#ifdef __GNUC__
#define __int64 long long 
#endif

#define POSITIVE 1
#define NEGATIVE -1
#define WV_PTS 32
#define HEADER_SIZE 16384

//___________________________________________________________________________________
void mexFunction(int nOUT, mxArray *pOUT[],
				 int nINP, const mxArray *pINP[])
{
	int i,n_written=0 ,n_total = 0;
	double *lower_thresholds,*upper_thresholds,logic = 1;
	int errorstatus;
	// NT SE record
	__int64  qwTimeStamp0;
	long dwParams[10];
	short snData[WV_PTS],pt;
	// check number of arguments: expects 1 input */
	if (nINP != 4 && nINP != 5)
				mexErrMsgTxt("4 or 5 inputs");
	if (nOUT > 0)
				mexErrMsgTxt("Requires 0 outputs.");


	/* read inputs */
	int fnlen_in = (mxGetM(pINP[0]) * mxGetN(pINP[0])) + 1;
	char *fn_in = (char *) mxCalloc(fnlen_in, sizeof(char)); 
	if (!fn_in)
		mexErrMsgTxt("Not enough heap space to hold converted string.");
	errorstatus = mxGetString(pINP[0], fn_in,fnlen_in);    
	if (errorstatus)
		mexErrMsgTxt("Could not convert string data.");

	int fnlen = (mxGetM(pINP[1]) * mxGetN(pINP[1])) + 1;
	char *fn_out = (char *) mxCalloc(fnlen, sizeof(char)); 
	if (!fn_out)
		mexErrMsgTxt("Not enough heap space to hold converted string.");
	errorstatus = mxGetString(pINP[1], fn_out,fnlen);    
	if (errorstatus)
		mexErrMsgTxt("Could not convert string data.");

	lower_thresholds    = mxGetPr(pINP[2]);
	upper_thresholds    = mxGetPr(pINP[3]);
	if (nINP == 4)
		logic = POSITIVE;
	else
		logic = mxGetScalar(pINP[4]);

	///////////////////////////////////////////////////////////////////
	// The code starts here
	///////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////
	// open files
	///////////////////////////////////////////////////////////////////
	// using _fsopen instead of fopen allows you to open a file that is 
	// currently being written.
	///////////////////////////////////////////////////////////////////
	FILE *fp_in = _fsopen(fn_in, "rb",_SH_DENYNO );
	if (!fp_in)
		mexErrMsgTxt("ERROR: Could not open input file.");
	FILE *fp_out = fopen(fn_out, "wb");
	if (!fp_out)
		mexErrMsgTxt("ERROR: Could not open output file.");

	///////////////////////////////////////////////////////////////////
	// Read the header into memory and write it to the destination file
	///////////////////////////////////////////////////////////////////
	char* header_ptr = (char *) calloc(HEADER_SIZE, sizeof(char));
	fread(header_ptr, sizeof(char), HEADER_SIZE, fp_in);
	fwrite(header_ptr, sizeof(char), HEADER_SIZE, fp_out);

	while(fread(&qwTimeStamp0,  sizeof(char),   8, fp_in))
	{
		n_total++;
		if (!fread(dwParams,       sizeof(char),  40, fp_in)){
			mexPrintf("%I64i Could not read record.\n",qwTimeStamp0);
			break;
		}
		if (!fread(snData  ,       sizeof(char),  WV_PTS*2,  fp_in)){
			mexPrintf("%I64i Could not read record.\n",qwTimeStamp0);
			break;
		}
		i = 0;
		int out_of_bounds = 0;
		int inside_bound_count = 0;
		while(out_of_bounds == 0 && i < WV_PTS)
		{
			pt = snData[i];

			if (logic == POSITIVE){
				// Remove it if it falls outside the upper and lower limit.
				if((pt < (short) lower_thresholds[i]) || (pt > (short) upper_thresholds[i]))
					out_of_bounds = 1;
			}else
			{   // Untested
				// Remove it if it falls within the upper and lower limit.
				if((pt > (short) lower_thresholds[i]) && (pt < (short) upper_thresholds[i]))
					inside_bound_count++;
			}
			i++;

		}

		if (logic != POSITIVE){
			// If it falls outside of the inner boundary, keep it and throw
			// away everything inside. Good for getting rid of noise.
			if(inside_bound_count != WV_PTS)
				out_of_bounds= 0;
			else
				out_of_bounds= 1;
		}

		if(out_of_bounds == 0){
			// Write to the outfile
			fwrite(&qwTimeStamp0,	sizeof(char),   8,	fp_out);
			fwrite(dwParams,		sizeof(char),   40, fp_out);
			fwrite(snData,			sizeof(char),   WV_PTS*2, fp_out);
			n_written++;
		}
	}
	
	///////////////////////////////////////////////////////////////////
	// cleanup
	///////////////////////////////////////////////////////////////////
	mexPrintf(" Wrote %i of %i original records. \n",n_written,n_total);
	fclose(fp_out);
	fclose(fp_in);
	mxFree(fn_in);
	mxFree(fn_out);
}

