/*---------------------------------
* Subsample_nlx_wavefile(fname1,fname2,timestamps, logic,filetype)
* Subsample a TT or SE file, saving only the timestamps in the passed in list (or removing the timestamps
* in the passed in list.
* MEX file
*
*
* input:
*    fname1 - file to subsample
 *   fname2 -destimation file
 *   timestamps - timestamps for subsampling
 *   logic - 1 = save the timestamps passed in, 0 = exclude the timestamps passed in.
* 
* output:
 *   the file fname2
*  version 0.0 (cowen)
--------------------------------*/
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

//#define WV_PTS 128
#define HEADER_SIZE 16384


int binsearch(int n, double* data, double key, int start)
{
	// n = number of records in data.
	// data is an array of records to search
	// key is the value to find.
	// start is where to start searching (an index)
	//
	// binsearch returns the index of the closest item in data
	//
	// from ADR adapted by cowen. 
	// fixed to return always the lower integreal timestamp (floor(*data)) if key is not integral (PL)
	
	int end = 0; 
	int mid = 0;
	double tmp;
	
	// binary search 
	end = n-1;   //-1;
	while (start < (end-1))
	{
		mid = (int) floor((start + end)/2);
 		//tmp = floor(data[mid]); DO NOT FLOOR THE DATA. IT WILL SCREW UP ANY fp DATA YOU PASS IN.
		tmp = data[mid];
		if (key == tmp)
			start = end = mid;
		if (key < tmp)
			end = mid;
		if (key > tmp)
			start = mid;
	}
	// Return the CLOSEST value.
//	if ((key - data[start]) > (data[end] - key))/
		//start = end;

	return start;
}


//___________________________________________________________________________________
void mexFunction(int nOUT, mxArray *pOUT[],
				 int nINP, const mxArray *pINP[])
{
	int i,n_written=0 ,n_total=0,n_limits = 0,timestamps_length=0,fnlen_in,fnlen,start=0,ix=0,keep_it=0,wv_pts = 128,file_type;
	double *timestamps, logic = 1;
	int errorstatus=0;
	// NT SE record
	__int64  qwTimeStamp0=0;
	long dwScNumber=0;
	long dwCellNumber=0;
	long dwParams[8];
	//short snData; //snData[WV_PTS],pt=0;
	short snData[128],pt=0;
    char *fn_in, *fn_out;
    char header_ptr[HEADER_SIZE];
	FILE *fp_in;
	FILE *fp_out;

	// check number of arguments: expects 1 input */
	if (nINP != 5 )
				mexErrMsgTxt("5 inputs * Subsample_nlx_wavefile(fname1,fname2,timestamps, logic,filetype)");
	if (nOUT > 0)
				mexErrMsgTxt("Requires 0 outputs.");


	/* read inputs */
	fnlen_in = (mxGetM(pINP[0]) * mxGetN(pINP[0])) + 1;
	fn_in = (char *) mxCalloc(fnlen_in, sizeof(char)); 
	if (!fn_in)
		mexErrMsgTxt("Not enough heap space to hold converted string.");
	errorstatus = mxGetString(pINP[0], fn_in,fnlen_in);    
	if (errorstatus)
		mexErrMsgTxt("Could not convert string data.");

	fnlen = (mxGetM(pINP[1]) * mxGetN(pINP[1])) + 1;
	fn_out = (char *) mxCalloc(fnlen, sizeof(char)); 
	if (!fn_out)
		mexErrMsgTxt("Not enough heap space to hold converted string.");
	errorstatus = mxGetString(pINP[1], fn_out,fnlen); 
    
	if (errorstatus)
		mexErrMsgTxt("Could not convert string data.");
	timestamps    = mxGetPr(pINP[2]);
	timestamps_length = (mxGetM(pINP[2]) * mxGetN(pINP[2]));

    logic = mxGetScalar(pINP[3]);
    file_type = mxGetScalar(pINP[4]);
    if (file_type == 1)
        wv_pts = 32;
    else if (file_type ==2)
        wv_pts = 64;
    else if (file_type ==3)
        wv_pts = 128;
    
    //snData = (short *) mxCalloc(wv_pts, sizeof(short));
//mexPrintf("0");

	///////////////////////////////////////////////////////////////////
	// open files
	///////////////////////////////////////////////////////////////////
	// using _fsopen instead of fopen allows you to open a file that is 
	// currently being written.
	///////////////////////////////////////////////////////////////////
	fp_in = _fsopen(fn_in, "rb",_SH_DENYNO );
	if (!fp_in)
		mexErrMsgTxt("ERROR: Could not open input file.");
//mexPrintf(".");
	//header_ptr = (char *) calloc(HEADER_SIZE, sizeof(char));
    //mexPrintf(";");

	fread(header_ptr, sizeof(char), HEADER_SIZE, fp_in);
    //mexPrintf("+");

    fp_out = fopen(fn_out, "wb");
    //mexPrintf("x");

    fwrite(header_ptr, sizeof(char), HEADER_SIZE, fp_out);
  //  mexPrintf(">");

	if (!fp_out)
		mexErrMsgTxt("ERROR: Could not open output file.");
//mexPrintf("1");
	///////////////////////////////////////////////////////////////////
	// The logic. Go through each timestamp. Search for it in the timestamp array.
    // If found or not found either keep it or don't keep it depending on the logic.
	///////////////////////////////////////////////////////////////////
    start = 0;
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

		if (!fread(snData  ,       sizeof(char),  wv_pts*2,  fp_in)){
			mexPrintf("%I64i Data: Could not read record.\n",qwTimeStamp0);
			break;
		}

        ix = binsearch(timestamps_length,timestamps,(double) qwTimeStamp0,start);

        start = ix;
        keep_it = 0; // by defualt, don't keep this spike.
        if (timestamps[ix] == (double) qwTimeStamp0)
            keep_it = logic;
        else
            keep_it = !logic;
  //      else
//        if (logic == 1)
 //           if (timestamps[ix] == (double) qwTimeStamp0)
 //               keep_it = 1;
  //      else
  //          if (timestamps[ix] != (double) qwTimeStamp0)
  //              keep_it = 1;
          
		// Write out a binary version of the file.
		if(keep_it == 1){
				// Write to the outfile

				fwrite(&qwTimeStamp0,	sizeof(char),   8,	fp_out);
				fwrite(&dwScNumber,		sizeof(char),   4, fp_out);
				fwrite(&dwCellNumber,	sizeof(char),   4, fp_out);
				fwrite(dwParams,		sizeof(char),   32, fp_out);
				fwrite(snData,			sizeof(char),   wv_pts*2, fp_out);
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

