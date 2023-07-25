/*-----------------------------------
* binning by interval
* MEX file
* 
* cowen 2002
* 
* input: 1: Spike or other timestamped data -- n_spikes x 1, assumed to be sorted
* input: 2: interval starts
  input: 3: interval ends 

 it used to be n_intervals x 2 matrix of intervals. The spike times will be binned into 
 these intervals. Also assumed to be sorted. The spikes are counted from 
 the values in col 1 up to but NOT including the values in col 2. I changed it because working with matrix
 indices in the mex file can be confusing - and I had mysterious seg faults so I needed to make 
  this as simple as possible.
* output: A vector of length n_intervals that contains the spike counts to each element in the bin.

* BUGGGG: IT SEEMS TO CUT OFF A RANDOM NUMBER OF POINTS OFF THE RIGHTWARD EDGE!
 * 
 *
  * NOTE: ASSUMES TIMESTAMPS ARE SORTED AND THE INTERVALS ARE SORTED BY THE FIRST COLUMN.

  cowen 2003 Fixed prblem with binsearch-- would not find the closest
             problems with by_timestamp so disabling the by_timestamp option for now.
  cowen 2006 Fixed crashes and compilation problems by getting rid of inlines.

 *
-----------------------------------*/

#include "mex.h"
#include <math.h>
#include <matrix.h>
//___________________________________________________________________________________
int binsearch_floor(int n, double* data, double key, int start)
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
	//double tmp;
	
    
  /* binary search */
  //start = 0;
  end = n-1;
  while (start < (end-1))
    {
      mid = floor((start + end)/2);
      if (key == data[mid])
          start = end = mid;
      if (key < data[mid])
          end = mid;
      if (key > data[mid])
          start = mid;
    }
    
	return start;
}

void mexFunction(
				 int nOUT, mxArray *pOUT[],
				 int nINP, const mxArray *pINP[])
{
	int n_intervals= 0, n_timestamps = 0;
	double *timestamps;
	double *interval_starts;
	double *interval_ends;
	double *result;
	int ts_idx=0,ts2_idx=0,intvl_idx=0, last_idx=0, temp_time=0;
	/*********************************************************/
	/* check number of arguments: expects 2 inputs, 1 output */
	/*********************************************************/
	if (nINP != 2 && nINP != 3)
		mexErrMsgTxt("Call with timestamp vector and an interval matrix as inputs.");
	if (nOUT != 1)
		mexErrMsgTxt("Requires one output.");
	
	/*******************/
	/*  unpack inputs  */
	/*******************/
    if ((mxGetM(pINP[1]) != mxGetM(pINP[2])) || (mxGetN(pINP[1]) != mxGetN(pINP[2])))
        mexErrMsgTxt("Start end end times must be of the same size!");
    
    n_timestamps	= mxGetM(pINP[0]) * mxGetN(pINP[0]);
    
    if (n_timestamps == 0){
        mexPrintf("No Timestamps!!\n");
        return;
    }

	n_intervals   	= mxGetM(pINP[1])*mxGetN(pINP[1]);

	timestamps      = (double *) mxGetPr(pINP[0]);
	interval_starts = (double *) mxGetPr(pINP[1]);
	interval_ends   = (double *) mxGetPr(pINP[2]);
    //mexPrintf("n_intervals %d n_timestamps %d \n ", n_intervals,n_timestamps);
		
	/****************/
	/* allocate output */
	/****************/
	pOUT[0] = mxCreateDoubleMatrix(n_intervals, 1, mxREAL);
	result  = mxGetPr(pOUT[0]);
	if (!pOUT[0]) 
		mexErrMsgTxt("Cannot create output array. Probably out of memory.");	
	
	/* If nothing is passed in, just return a vector of 0s.*/
	if (mxIsEmpty(pINP[0]) || mxIsEmpty(pINP[1])){
        mexPrintf("Empty values passed in.\n");
        // result = NULL;
        // timestamps = NULL;
		return;
    }
	
	/*********************************************************/
	/*  Do you iterate through the intervals and search for spikes for each 
	*  interval or do you iterate through the spikes and search for the proper 
	*  interval for each spike? The program tries to intelligently decide and
	*  do whatever is fastest. */
	/*********************************************************/
	
	/*********************************************************/
	/*  How about this: go through each interval, find the firs t 
  	*  spike within that interval, then keep going through
	*  the spikes until you hit one greater than the interval, 
	*  then move to the next interval */
	/*********************************************************/
	last_idx = 0;

    /*********************************************************/
    /*  Make sure inputs are sorted in ascending order. */
	/*********************************************************/   
    for (intvl_idx =0 ; intvl_idx < (n_intervals-1); intvl_idx++){
        if (interval_starts[intvl_idx+1] < interval_starts[intvl_idx])
            mexErrMsgTxt("The intervals must be sorted in ascending order!");
        if (interval_starts[intvl_idx] > interval_ends[intvl_idx])
            mexErrMsgTxt("Intervals must be positive(start, end).");
    }

    for (intvl_idx=0; intvl_idx < n_intervals; intvl_idx++)
    {
        /*********************************************************/
        /* find the timestamp indices closest to the interval start	and end */
        /*********************************************************/
        ts_idx  = binsearch_floor(n_timestamps, timestamps, interval_starts[intvl_idx], last_idx);
        last_idx = ts_idx; // THis is not the PROBLEM
        while ((timestamps[ts_idx] < interval_starts[intvl_idx]) && (ts_idx < (n_timestamps-1)))
            ts_idx++;
        if (timestamps[ts_idx] >= interval_starts[intvl_idx])
        {
            // It's possible that ts_idx could get to n_timestmaps (thus 1 over the limit)
            // perhaps by putting (ts_idx < n_timestamps) in front, this condition will 
            // never be reached. If it still crashes, then I will have to test for this
            // explicitly.
            while ((ts_idx < n_timestamps) && (timestamps[ts_idx] <= interval_ends[intvl_idx]))
            {
                result[intvl_idx]++;
                ts_idx++;
            }
        }else
        {
            return; // Reached the last timestamp in the range.
        }
        
    }
}
