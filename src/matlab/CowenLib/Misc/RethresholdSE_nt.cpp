/*---------------------------------
* RethresholdSE_nt
* MEX file
* * Rethreshold the data. -- you can specify a range to rethreshold if you wish.
* input:
*    fn_in = input file name string
*    fn_out = output file name string
*    limit_array = an array of limits (3tuples) where the first number specifies the limit and the next two
*     specify the lower and upper bound respectively. For instance 3 -100 200 would eliminate all waves which, 
*     at point 3, were outside this range (assuming positive logic)
*    logic = 1 = positive logic. All points outside of range are eliminated. Anything else is
*      negative logic which means that only waveforms that fall within the range(every point must 
*      fall within the range) will be eliminated.
*    output type = can be another SE file (0) or a text file (1) or a .t file (.1msec, binary) (2)
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
	int i,n_written=0 ,n_total=0,n_limits = 0,limit_array_length=0;
	double *limit_array, logic = 1,output_file_type=0;
	int errorstatus=0;
	// NT SE record
	__int64  qwTimeStamp0=0;
	long dwScNumber=0;
	long dwCellNumber=0;
	long dwParams[8];
	short snData[WV_PTS],pt=0;
	FILE *fp_in;
	FILE *fp_out;

	// check number of arguments: expects 1 input */
	if (nINP != 3 && nINP != 4 && nINP != 5)
				mexErrMsgTxt("3, 4 or 5 inputs");
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
	limit_array    = mxGetPr(pINP[2]);
	limit_array_length = (mxGetM(pINP[2]) * mxGetN(pINP[2]));
	n_limits = (mxGetM(pINP[2]) * mxGetN(pINP[2]))/3;

	if (nINP <= 3)
		logic = POSITIVE;
	else
		logic = mxGetScalar(pINP[3]);
    //
	if (nINP <= 4)
		output_file_type = 0;
	else
		output_file_type = mxGetScalar(pINP[4]);

	///////////////////////////////////////////////////////////////////
	// The code starts here
	///////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////
	// open files
	///////////////////////////////////////////////////////////////////
	// using _fsopen instead of fopen allows you to open a file that is 
	// currently being written.
	///////////////////////////////////////////////////////////////////
	fp_in = _fsopen(fn_in, "rb",_SH_DENYNO );
	if (!fp_in)
		mexErrMsgTxt("ERROR: Could not open input file.");

	char* header_ptr = (char *) calloc(HEADER_SIZE, sizeof(char));
	fread(header_ptr, sizeof(char), HEADER_SIZE, fp_in);

	if (output_file_type ==1){
		fp_out = fopen(fn_out, "w+");
		mexPrintf("TEXT FILE ");
	}
	else{
		mexPrintf("BINARY FILE ");
		fp_out = fopen(fn_out, "wb");
		fwrite(header_ptr, sizeof(char), HEADER_SIZE, fp_out);
	}
	if (!fp_out)
		mexErrMsgTxt("ERROR: Could not open output file.");


	///////////////////////////////////////////////////////////////////
	// Read the header into memory and write it to the destination file
	///////////////////////////////////////////////////////////////////

	while(fread(&qwTimeStamp0,  sizeof(char),   8, fp_in))
	{
		n_total++;
		if (!fread(&dwScNumber, sizeof(char),  4, fp_in)){
			mexPrintf("%I64i SC: Could not read record.\n",qwTimeStamp0);
			break;
		}
		if (!fread(&dwCellNumber,       sizeof(char),  4, fp_in)){
			mexPrintf("%I64i Cell: Could not read record.\n",qwTimeStamp0);
			break;
		}
		if (!fread(dwParams,       sizeof(char),  32, fp_in)){
			mexPrintf("%I64i Params: Could not read record.\n",qwTimeStamp0);
			break;
		}
		if (!fread(snData  ,       sizeof(char),  WV_PTS*2,  fp_in)){
			mexPrintf("%I64i Data: Could not read record.\n",qwTimeStamp0);
			break;
		}
		i = 0;
		int out_of_bounds = 0;
		int inside_bound_count = 0;
		while(out_of_bounds == 0 && i < limit_array_length)
		{
			if (limit_array[i] > 0)
				pt = snData[(int) limit_array[i] - 1];
			else
			{

				pt = dwParams[(-1 * (int) limit_array[i]) - 1];
				//mexPrintf("%I64i %g found negative limit.  pt %i \n",qwTimeStamp0,limit_array[i],pt);
			}

			if (logic == POSITIVE){
				// Remove it if it falls outside the upper and lower limit.
				if((pt < (short) limit_array[i+1]) || (pt > (short) limit_array[i+2]))
					out_of_bounds = 1;
			}else
			{   // Untested
				// Remove it if it falls within the upper and lower limit.
				if((pt > (short) limit_array[i+1]) && (pt < (short) limit_array[i+2]))
					inside_bound_count++;
			}
			i = i + 3;

		}

		if (logic != POSITIVE){
			// If it falls outside of the inner boundary, keep it and throw
			// away everything inside. Good for getting rid of noise.
			if(inside_bound_count != WV_PTS)
				out_of_bounds= 0;
			else
				out_of_bounds= 1;
		}

		// Write out a binary version of the file.
		if(out_of_bounds == 0){
			if (output_file_type==1){
				// just write out a text file.
				fprintf(fp_out,"%I64i\n", qwTimeStamp0);
				n_written++;
			}else{
				// Write to the outfile
				fwrite(&qwTimeStamp0,	sizeof(char),   8,	fp_out);
				fwrite(&dwScNumber,		sizeof(char),   4, fp_out);
				fwrite(&dwCellNumber,	sizeof(char),   4, fp_out);
				fwrite(dwParams,		sizeof(char),   32, fp_out);
				fwrite(snData,			sizeof(char),   WV_PTS*2, fp_out);
				n_written++;
			}
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

