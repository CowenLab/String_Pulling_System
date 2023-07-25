/*---------------------------------
* Read_nlx_CR_files (file_names_cell_array, sFreq, intervals_in_timestamps) 
* Read a set of CR files at once at the specified sampling frequency and send it off to matlab.
* MEX file
*
*
* input:
*    cell array of file names
*    sFreq = the sampling frequency of the outputted data. Leaving empty will assume the file's standard samplnig rate.
*    intervals - a n X 2 matrix of start and end timestamps or records (not implemented yet).
*   
* 
* output:
*    [t,D]
*    t = timestamps for EACH record
*    D = Data: the data you wish to read where each column corresponds to each file you passed in.
TODO
*    interval_indices = would be nice if this returned the start and end index of each interval so that you 
*           could then could quickly pull the intervals out of the data.
* 
**** This needs to be a .cpp file as it has inlines.
* NOTE: THIS DOES NOT WORK IF YOU DESIRE A SAMPLING RATE HIGHER THAN THE ORIGINAL RATE.
*
* [a, b] = Read_nlx_CR_files({'CSC11.ncs' 'CSC10.ncs'},100,[1215413846 1415413846;1515413846 1815413846 ]); 
*
* version 0.6
* cowen(2004)
--------------------------------*/

#include "mex.h"
//#include "nrutil.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <matrix.h>


#ifdef __GNUC__
#define __int64 long long 
#endif

/***********************************************************/
/* DEFINTIONS: */
/***********************************************************/


typedef struct block_type_tag {
	FILE *fp;
	double	TimeStamp;	
	long	ChannelNum;	
	long	SampleFreq;	
	long	NumValidSamples;	
	short	Data[512];		
} BLOCK_TYPE;
//___________________________________________________________________________________
// From Numerical Recipes. MODIFIED (E.G. Double support)
//___________________________________________________________________________________
#define NR_END 1
#define FREE_ARG char*

void nrerror(char error_text[])
/* Numerical Recipes standard error handler */
{
	mexPrintf("Numerical Recipes run-time error...\n");
	mexPrintf("%s\n",error_text);
	mexPrintf("...now exiting to system...\n");
	exit(1);
}

short *vector(long nl, long nh)
/* allocate a float vector with subscript range v[nl..nh] */
{
	short *v;
	v = (short *)mxMalloc((size_t) ((nh-nl+1+NR_END)*sizeof(short)));
	if (!v) nrerror("allocation failure in vector()");
	return v-nl+NR_END;
}

void free_vector(short *v, long nl, long nh)
/* free a float vector allocated with vector() */
{
	mxFree((FREE_ARG) (v+nl-NR_END));
}

void polint(double xa[], short ya[], int n, double x, double *y, double *dy)
{
	int i,m,ns=1;
	double den,dif,dift,ho,hp;
	short w;
	short *c,*d;

	dif=fabs(x-xa[1]);
	c=vector(1,n);
	d=vector(1,n);
	for (i=1;i<=n;i++) {
		if ( (dift=fabs(x-xa[i])) < dif) {
			ns=i;
			dif=dift;
		}
		c[i]=ya[i];
		d[i]=ya[i];
	}
	*y= (double) ya[ns--];
	for (m=1;m<n;m++) {
		for (i=1;i<=n-m;i++) {
			ho=xa[i]-x;
			hp=xa[i+m]-x;
			w=c[i+1]-d[i];
			if ( (den=ho-hp) == 0.0) nrerror("Error in routine polint");
			den=w/den;
			d[i]= (short) hp*den;
			c[i]= (short) ho*den;
		}
		*y += (double) (*dy=(2*ns < (n-m) ? c[ns+1] : d[ns--]));
	}
	free_vector(d,1,n);
	free_vector(c,1,n);
}


//___________________________________________________________________________________
// General utilities
//___________________________________________________________________________________
int binsearch(int n, double* data, double* key)
{
	// n = number of records in data.
	// data is an array of records to search
	// key is the value to find.
	// 
	// binsearch returns the index of the closest item in data
	//
	// from ADR adapted by cowen. 
	// fixed to return always the lower integreal timestamp (floor(*data)) if key is not integral (PL)

	int start = 0;
	int end = 0; 
	int mid = 0;
	double tmp;

	// binary search 
	start = 0;
	end = n-1;
	while (start < (end-1))
	 {
	  mid = (int) floor((double)(start + end)/2);
	  tmp = floor(data[mid]);
	  if ((*key) == tmp)
	     start = end = mid;
	  if ((*key) < tmp)
	     end = mid;
      if ((*key) > tmp)
	     start = mid;
	}

  return start;
}

//___________________________________________________________________________________
// NLX specific IO.
//___________________________________________________________________________________
int SkipCheetahNTHeader(FILE *fp)
{
	// Cheetah NT versions 1.3 or greater have a standard Neuralynx header of ascii strings of total
	// length of 16384 bytes in the beginning of the binary file. 
	// Check if Cheetah header present (in versions > 1.3) and skip header
	//
	// returns 1 if new Neuralynx header is present and was skipped
	//         0 if NO  header is present

    char headerflag[8];   // if first 8 bytes of AnyCheetahfile.dat contain "########" there is a header 
                          // of length 16,384 bytes to skip (from the very beginning including the eight '#') 
    const int NHEADERBYTES = 16384;	
	
	fread(headerflag, sizeof(char), 8, fp);  
	//mexPrintf("Headerflag =  %8s \n", headerflag);
    fseek(fp,0,0);       // reset filepointer to the beginning of file
	if (strncmp(headerflag,"########",8) == 0){
		fseek(fp,NHEADERBYTES,0);  // set filepointer after byte NHEADERBYTES
	    //mexPrintf("NT-Header skipped (%d bytes)\n",NHEADERBYTES);
		return 1;
	} 
	return 0;
}

//___________________________________________________________________________________
int SkipHeader(FILE *fp)
{
	/* returns 0 if header present and skipped  (success) 
	**         1 if NO header present in file (indicates a new NT_cheetah TT file) */
	long curpos = ftell(fp);
	char headerline[81];

	fgets(headerline, 80, fp);
	if (strncmp(headerline, "%%BEGINHEADER", 13) == 0){
		while (strncmp(headerline, "%%ENDHEADER",11) != 0)
			fgets(headerline, 80, fp);
		return 0;
	} else {
		fseek(fp, curpos, SEEK_SET);
		return 1;
	}
}

//___________________________________________________________________________________
int bigendianMachine(void)
{
	/* returns 0 if is a littleendian machine, else returns nonzero */
	/* key is that it looks to see if short's second byte is the low order bits */
	short fullLoByte = 0xFF;
	char *byteOrder = (char *) &fullLoByte;
	return (byteOrder[1]);	
}


//___________________________________________________________________________________
inline short swapbytes(short ii)
// swap byte order of a short: (0,1) -> (1,0)
{
	union {
		short s;
		char c[2];
	} tmp0,tmp;
	
	tmp.s = ii;
	tmp0.c[0] = tmp.c[1];					
	tmp0.c[1] = tmp.c[0];

	return tmp0.s;
}

//___________________________________________________________________________________
inline unsigned short swapbytes(unsigned short ii)
// swap byte order of a short: (0,1) -> (1,0)
{
	union {
		unsigned short us;
		char c[2];
	} tmp0,tmp;
	
	tmp.us = ii;
	tmp0.c[0] = tmp.c[1];					
	tmp0.c[1] = tmp.c[0];

	return tmp0.us;
}


//___________________________________________________________________________________
inline unsigned long swapbytes(unsigned long ii)
// swap byte order of an unsigned long: (0,1,2,3) -> (3,2,1,0)
{
	union {
		unsigned long ul;
		char c[4];
	} tmp0,tmp;
	
	tmp.ul = ii;
	tmp0.c[0] = tmp.c[3];					
	tmp0.c[1] = tmp.c[2];
	tmp0.c[2] = tmp.c[1];					
	tmp0.c[3] = tmp.c[0];

	return tmp0.ul;
}

//___________________________________________________________________________________
inline long swapbytes(long ii)
// swap byte order of a long: (0,1,2,3) -> (3,2,1,0)
{
	union {
		long l;
		char c[4];
	} tmp0,tmp;
	
	tmp.l = ii;
	tmp0.c[0] = tmp.c[3];					
	tmp0.c[1] = tmp.c[2];
	tmp0.c[2] = tmp.c[1];					
	tmp0.c[3] = tmp.c[0];

	return tmp0.l;
}

inline long doubleswapbytes(long ii)
// swap byte order of a long: (0,1,2,3) -> (2,3,1,0)
{
	union {
		long l;
		char c[4];
	} tmp0,tmp;
	
	tmp.l = ii;
	tmp0.c[0] = tmp.c[2];					
	tmp0.c[1] = tmp.c[3];
	tmp0.c[2] = tmp.c[1];					
	tmp0.c[3] = tmp.c[0];

	return tmp0.l;
}



//___________________________________________________________________________________
inline __int64 swapbytes(__int64 ii)
// swap byte order of a long long: (0,1,2,3,4,5,6,7) -> (7,6,5,4,3,2,1,0)
{
	union {
		__int64 ll;
		char c[8];
	} tmp0,tmp;
	
	tmp.ll = ii;
	tmp0.c[0] = tmp.c[7];					
	tmp0.c[1] = tmp.c[6];
	tmp0.c[2] = tmp.c[5];					
	tmp0.c[3] = tmp.c[4];
	tmp0.c[4] = tmp.c[3];					
	tmp0.c[5] = tmp.c[2];
	tmp0.c[6] = tmp.c[1];					
	tmp0.c[7] = tmp.c[0];

	return tmp0.ll;
}



int get_data_v1(FILE *fp, BLOCK_TYPE *blk)
{	

/* For old UNIX cheetah data */

#ifdef __GNUC__
	const long long  TIMESTAMP_MAX = 0x00FFFFFFFFFFFFFFLL;  //( = 2^52-1; the largest integer fitting
#else
	const __int64 TIMESTAMP_MAX = 0x00FFFFFFFFFFFFFF;  //( = 2^52-1; the largest integer fitting
#endif
	unsigned long qwTimeStamp;
	unsigned long dwChannelNum = 999;
	unsigned long dwSampleFreq = 0;
	unsigned short dwNumValidSamples;
	int j;

	fread(&qwTimeStamp,  sizeof( long),   1, fp);
	fread(&dwNumValidSamples, sizeof( short), 1, fp);
	fread(&dwSampleFreq, sizeof( long),   1, fp);
	fread(blk->Data, sizeof( short), 512, fp);
	qwTimeStamp = swapbytes(qwTimeStamp);
	
	if(qwTimeStamp > TIMESTAMP_MAX){
		mexPrintf(" ERROR 1: timestamp %d is too large to fit in a double!\n",qwTimeStamp);
		mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
	}
	dwSampleFreq = swapbytes(dwSampleFreq);
	dwNumValidSamples = swapbytes(dwNumValidSamples);
	for (j = 0; j<512; j++)
		blk->Data[j] = swapbytes(blk->Data[j]);
	/* Convert into the standard block format */

	blk->TimeStamp       = (double) qwTimeStamp; /* Timestamps already in 1/10000sec */
	blk->ChannelNum      = (unsigned long) dwChannelNum ;
	blk->SampleFreq      = (unsigned long) dwSampleFreq;
	blk->NumValidSamples = (unsigned long) dwNumValidSamples;

	return (1);
}


int get_data_v2(FILE *fp, int bigendianFlag, BLOCK_TYPE *blk)
{	
	/* For newer NT cheetah data */
#ifdef __GNUC__
	const long long  TIMESTAMP_MAX = 0x00FFFFFFFFFFFFFFLL;  //( = 2^52-1; the largest integer fitting
#else
	const __int64 TIMESTAMP_MAX = 0x00FFFFFFFFFFFFFF;  //( = 2^52-1; the largest integer fitting
#endif
	__int64 qwTimeStamp;
	unsigned long dwChannelNum;
	unsigned long dwSampleFreq;
	unsigned long dwNumValidSamples;
	//signed short snSamples[512];
	int j;
	fread(&qwTimeStamp,  sizeof(__int64),   1, fp);
	fread(&dwChannelNum, sizeof(long),   1, fp);
	fread(&dwSampleFreq, sizeof(long),   1, fp);
	fread(&dwNumValidSamples, sizeof(long), 1, fp);
	fread(blk->Data, sizeof(short), 512, fp);
	/* fread(&junk,sizeof(long),1,fp); */
			
	if(bigendianFlag){
	// convert from NT(little endian) to Sun (big endian)
		qwTimeStamp = swapbytes(qwTimeStamp);
		if(qwTimeStamp > TIMESTAMP_MAX){
			mexPrintf(" ERROR: timestamp %d is too large to fit in a double!\n",qwTimeStamp);
			mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
		}
		dwChannelNum = swapbytes(dwChannelNum);
		dwSampleFreq = swapbytes(dwSampleFreq);
		dwNumValidSamples = swapbytes(dwNumValidSamples);
		for (j = 0; j<512; j++)
			blk->Data[j] = swapbytes(blk->Data[j]);
	}
	/* Convert into the standard block format */

	blk->TimeStamp = (double) qwTimeStamp; 
	blk->ChannelNum = dwChannelNum ;
	blk->SampleFreq = dwSampleFreq;
	blk->NumValidSamples = dwNumValidSamples;
	return (1);
}
////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////
int get_data(FILE *fp, int bigendianFlag, BLOCK_TYPE *blk, int new_NT_format)
{	
	int out;
	if (new_NT_format){
		out = get_data_v2(fp, bigendianFlag, blk);
	}else{
		out = get_data_v1(fp, blk);
	}
	return (out);
}


//___________________________________________________________________________________
void mexFunction(int nOUT, mxArray *pOUT[],
					  int nINP, const mxArray *pINP[])
{
	int errorstatus;
	int bigendianFlag = bigendianMachine();
	long postHeaderPos,endPos,start_pos,end_pos;
	int fnlen;
	int new_NT_format;     /* flag for new NT_format TT files (0=old SUN, 1=new NT)  */
	char *fn;
	char fname[200];
	FILE *fp;
	int nSamples = 0;      /* to be implemented later */
	int nRecords, prev_nRecords, n_files, n_intervals;
	const int NEW_CR_RECSIZE = 8+sizeof(int)+2*sizeof(long)+512*sizeof(short);
	double timestamp_buffer[NEW_CR_RECSIZE*3];
	
	unsigned long junk = 0; 
	double *t, *t_out, *D_out,tmp_dbl;
	double *cr,n_timestamps;
	double sampFreq, sampFreq0 = 0.0; 
	double *crptr, *intervals;
	const mxArray *file_list_ptr;
	const mxArray *fname_ptr;
	
	double tmp_ts = 0; 

	double start_ts = 0; // Start ts of the data to be loaded
	double end_ts = 9999999999;   // End ts of the data to be loaded
	double first_ts = 0; // First ts of the file.
	double actual_start_ts = 0; // The actual ts of the block closest to the start ts.
	double actual_end_ts = 0;
	double ts_interval_for_desired,ts_interval_for_actual;
	double sFreq_for_desired;
	double sFreq_for_actual;
	double block_interval_ts;
	double *dy; // Error from the interpolation.
	double *original_times;
	short *original_data;
	int out_rows;
	int interval_width_in_idxs = 100; // Must be even. The size of the window around the target.

	BLOCK_TYPE blk_1,blk_2; /* The data from one block in the CR file */
	int crDims[] = {nSamples, 512};
	int subs[] = {0, 0};
	int index; 
	int i,j,k,rec_count = 0,file_count=0,interval_count,t_out_count = 0;  /* counters */
	int partial_load = 0, found_start = 0, found_end = 0;     /* Flags */
	int got_data = 0;		
	double *interval_end_ts;
			
	
	/* check number of arguments: expects 1 input */
	if (!((nINP == 3) || (nINP == 1)) )
		mexErrMsgTxt("1 or 3 input values and 1 or 2 outputs: [t,D] = Read_nlx_CR_files (file_names_cell_array, sFreq, intervals_in_timestamps) ");
	if (nOUT != 2)
		mexErrMsgTxt("Requires two outputs (t, Data)");
	if (nINP == 3){	
		partial_load = 1;
	}
	//////////////////////////
	/* read inputs */
	//////////////////////////
	file_list_ptr	 = pINP[0];
	n_files			 = mxGetNumberOfElements(file_list_ptr);
	sFreq_for_desired= mxGetScalar(pINP[1]);
	intervals		 = mxGetPr(pINP[2]);
	n_intervals		 = mxGetM(pINP[2]);
	interval_end_ts  = (double *) mxCalloc((size_t) n_intervals, sizeof(double)); // Stores the last timestamp of each interval.
	//////////////////////////////////////////////////////////////////////////////////////////////////
	/* Step 1: Determine the precise timestamps to return given the start and end time and the sampling frequency. */
	//////////////////////////////////////////////////////////////////////////////////////////////////
	ts_interval_for_desired = 1e6/sFreq_for_desired;
	mexPrintf("NOTE: You may get strange results if and only if you passed in overlapping intervals.\n Read_nlx_CR_files works fine with non-overlapping intervals.\nn_files %i sFreq_for_desired  %5.2f n_intervals  %i ts_interval_for_desired %g \n", n_files, sFreq_for_desired, n_intervals,ts_interval_for_desired);
	out_rows = 0;
	for (i=0;i<n_intervals;i++)	{
		out_rows = (int) out_rows + ceil((*(intervals + i + n_intervals) - *(intervals + i ))/ts_interval_for_desired);
	}
	// Create some space for the timestamps
	pOUT[0] = mxCreateDoubleMatrix(out_rows, 1, mxREAL);
    t_out	= mxGetPr(pOUT[0]);
	// Calloc some space for the data
	pOUT[1] = mxCreateDoubleMatrix(out_rows, n_files, mxREAL);
	D_out	= mxGetPr(pOUT[1]);
	//////////////////////////////////////////////////////////////////////////////////////////////////
	/* Fill up the timestamp data with the appropriate timestmaps */
	//////////////////////////////////////////////////////////////////////////////////////////////////
	k = 0;
	for (i=0;i<n_intervals;i++)	{
	    if ((*(intervals + i + n_intervals) - *(intervals + i)) < 0)
	    {
	        mexPrintf("ERROR: Intervals are not in ascending order\n");
	        exit(0);
	    }
		for(tmp_dbl = 0;tmp_dbl < ceil((*(intervals + i + n_intervals) - *(intervals + i))/ts_interval_for_desired) ;tmp_dbl++){
			*(t_out + k) = *(intervals + i) + tmp_dbl*ts_interval_for_desired;
			k++; 

			if(k>out_rows)
			{
				mexPrintf("OVERFLOW IN ASSIGNIGN TIMESTAMPS: %i, last timestamp %g\n",k, *(t_out + k-1));
				break;
			}
		}
		interval_end_ts[i] = *(t_out + k - 1); // Store the last timestamp of each interval.
		//mexPrintf("INTERVAL %g %g tout1 = %g    n_intervals %i \n",*(intervals + i + 0),*(intervals + i + n_intervals),*(t_out + 0),n_intervals);
	}
	//////////////////////////////////////////////////////////////////////////////////////////////////
	/* Step 3: Open each file in succession (perhaps faster if in parallel, I don't know) and fit the timestamps (interpolate) */
	//////////////////////////////////////////////////////////////////////////////////////////////////
	for (file_count = 0;file_count<n_files;file_count++)
	{
		t_out_count = 0; // Reset for each FILE.
		//////////////////////////////////////////////////////////////////////////////////////////////////
		// START FILE IO STUFF
		//////////////////////////////////////////////////////////////////////////////////////////////////
		fname_ptr = mxGetCell(file_list_ptr,file_count);

		/* Allocate enough memory to hold the converted string. */ 
		i = mxGetNumberOfElements(fname_ptr)+1;
		fn = (char *) mxCalloc(i, sizeof(char)); 
		if (!fn)
			mexErrMsgTxt("Not enough heap space to hold converted string.");		 
		/* Copy the string data from string_array_ptr and place it into buf. */ 
		j = mxGetString(fname_ptr,  fn, i);

		/* open file */
		fp = fopen(fn, "rb");
		if (!fp)
			mexErrMsgTxt("Could not open file.");
		
		/* skip header */
		new_NT_format = SkipHeader(fp);
		if (new_NT_format) SkipCheetahNTHeader(fp);     // Skip standard Neuralynx header if present (Cheetah versions >= 1.3)
		/* count number of Records */
		start_pos = ftell(fp); // The post header start of the data.
		fseek(fp, 0, SEEK_END);	
		end_pos = ftell(fp);
		nRecords = (int)floor((end_pos - postHeaderPos) / NEW_CR_RECSIZE);
		if (file_count == 0)
			prev_nRecords = nRecords;
		if (nRecords != prev_nRecords)
			mexPrintf("ERROR 2: File %s is not the same size as the previous file.",fn);
		prev_nRecords = nRecords;
		//////////////////////////////////////////////////////////////////////////////////////////////////
		// END FILE IO STUFF
		//////////////////////////////////////////////////////////////////////////////////////////////////

		//////////////////////////////////////////////////////////////////////////////////////////////////
		// Read the first two records to get and estimate of the sampling frequency.
		//////////////////////////////////////////////////////////////////////////////////////////////////
		fseek(fp, start_pos, SEEK_SET);

		got_data = get_data(fp, bigendianFlag, &blk_1, new_NT_format);
		got_data = get_data(fp, bigendianFlag, &blk_2, new_NT_format);

		sFreq_for_actual = 1000000*(512/(blk_2.TimeStamp - blk_1.TimeStamp));
		//////////////////////////////////////////////////////////////////////////////////////////////////
		// If the user does not specify a sampling frequency, use the sfreq
		// acquired from the first file.
		//////////////////////////////////////////////////////////////////////////////////////////////////
		if(mxIsEmpty(pINP[1]) && file_count == 0)
		{
		     sFreq_for_desired = sFreq_for_actual;
		     mexPrintf("No sampling rate specified, sampling at = %g Hz\n",sFreq_for_desired);
		}
	
		block_interval_ts = (blk_2.TimeStamp - blk_1.TimeStamp);
		start_ts = blk_1.TimeStamp;
		/////////////////////////////////////////////////////////////////////////////////////////////////
		// Find the region of interest.  Load the entire interval at once. Assign times to it
		/////////////////////////////////////////////////////////////////////////////////////////////////

		for (interval_count=0; interval_count < n_intervals; interval_count++)	{
			/////////////////////////////////////////////////////////////////////////////////////////////////
			// Jump to the start of the interval -- find it.
			/////////////////////////////////////////////////////////////////////////////////////////////////
			// If the first value of teh range is less than the vals in the data, then change the range.
			if (*(intervals + interval_count) < start_ts){
				mexPrintf(" Data starts after the specified interval. Data starts at %g, interval starts at %g n_intervals %i\n", start_ts,*(intervals + interval_count),n_intervals);
				*(intervals + interval_count) = start_ts;
			}

			int est_jump_size_blocks = ceil((*(intervals + interval_count) - start_ts) /block_interval_ts);
			int est_interval_size_blocks = ceil((*(intervals + interval_count + n_intervals) - *(intervals + interval_count))/block_interval_ts) + 1; 
			//mexPrintf("est_jump_size_blocks %i block_interval_ts %g start_ts %g\n",est_jump_size_blocks,block_interval_ts,start_ts);

			if (est_jump_size_blocks < 0) // If it is 0, that means you are already there. No need to move.
			{
				mexErrMsgTxt(" Jump size is less than 0. Something is wrong.");
				break;
			}
			/////////////////////////////////////////////////////////////////////////////////////////////////
			fseek(fp, start_pos, SEEK_SET); // Start at the beginnnig
			fseek(fp, est_jump_size_blocks*NEW_CR_RECSIZE,SEEK_CUR);

			got_data = get_data(fp, bigendianFlag, &blk_1, new_NT_format);

			//mexPrintf(" File : %s, Target = %g Actual = %g est_jump_size_blocks %i est_interval_size_blocks %i\n", fn, *(intervals + interval_count),blk_1.TimeStamp,est_jump_size_blocks,est_interval_size_blocks );
			/////////////////////////////////////////////////////////////////////////////////////////////////
			// Jump forward if necessary
			/////////////////////////////////////////////////////////////////////////////////////////////////
			if (blk_1.TimeStamp < *(intervals + interval_count + 0))
			{
				while (blk_1.TimeStamp < *(intervals + interval_count + 0))
				{
					//blk = blk_1;
					//fseek(fp,NEW_CR_RECSIZE,SEEK_CUR);
					got_data = get_data(fp, bigendianFlag, &blk_1, new_NT_format);
					//mexPrintf(">");
				}
				// Now step back so that you are in the record before the target.
				fseek(fp,-2*NEW_CR_RECSIZE,SEEK_CUR);
				//blk_1 = blk;
				// Get the data.
				got_data = get_data(fp, bigendianFlag, &blk_1, new_NT_format);
				//mexPrintf("<");
			}
			// Jump backwards if necessary
			while (blk_1.TimeStamp >= *(intervals + interval_count + 0) && ftell(fp) > start_pos)
			{
				fseek(fp,-2*NEW_CR_RECSIZE,SEEK_CUR);
				got_data = get_data(fp, bigendianFlag, &blk_1, new_NT_format);
				//mexPrintf("<");
			}
			//mexPrintf("AFTER CORRECTION: File: %s, Target = %g Actual = %g \n", fn, *(intervals + interval_count + 0),blk_1.TimeStamp );

			/////////////////////////////////////////////////////////////////////////////////////////////////
			// Allocate the space for the actual data (not interpolated).
			//  Include some extra to correct for edge effects.
			/////////////////////////////////////////////////////////////////////////////////////////////////
			if (interval_count == 0)
			{
				original_times = (double*) mxCalloc((size_t) (est_interval_size_blocks+4) * 512, sizeof(double));
				original_data  = (short*)  mxCalloc((size_t) (est_interval_size_blocks+4) * 512, sizeof(short));
			}else
			{
				original_times = (double*) mxRealloc(original_times, (est_interval_size_blocks+4) * 512 * sizeof(double));
				original_data  = (short*)  mxRealloc(original_data,  (est_interval_size_blocks+4) * 512 * sizeof(short));
				if (original_times == NULL || original_data == NULL)
					mexErrMsgTxt("Failure reallocating memory.");
			}

			/////////////////////////////////////////////////////////////////////////////////////////////////
			// Load in the actual data and create timestamps for each record.
			/////////////////////////////////////////////////////////////////////////////////////////////////
			//mexPrintf("original_times size = %i \n",(est_interval_size_blocks+4) * 512 * sizeof(double));
			
			got_data = get_data(fp, bigendianFlag, &blk_2, new_NT_format);
			//mexPrintf("t= %g  \n",blk_2.TimeStamp);
			int data_len = 0;
			// Pad the beginning of the record with something so that interpolation can occur 
			// even if the desired sample occurrs before the actual data.
			//for (data_len=0;data_len<interval_width_in_idxs;data_len++)
			//{
			//	original_times[data_len] = data_len;
			//	original_data[data_len]  = 0;
			//}

			while (blk_1.TimeStamp <= *(intervals + interval_count + n_intervals))
			{
				//mexPrintf("%g  %g\n", blk_1.TimeStamp,blk_2.TimeStamp);

				ts_interval_for_actual = (blk_2.TimeStamp - blk_1.TimeStamp)/512;
				for (i=0;i<512;i++)
				{
					tmp_ts = blk_1.TimeStamp + (double) i * ts_interval_for_actual;
					//if ((tmp_ts >= *(intervals + interval_count)) && (tmp_ts <= *(intervals + interval_count + n_intervals)))
					//{
						if (data_len>(est_interval_size_blocks+2)*512){
							 mexErrMsgTxt("Overflow!!!");
							 break;
						}else
						{
							original_times[data_len] = tmp_ts;
							original_data[data_len]  = blk_1.Data[i];
							//if(data_len%1000==0)
                            //    mexPrintf("%i(%g, %i) ",data_len,original_times[data_len],original_data[data_len]);
							data_len++;
						}
					//}
				}
				blk_1 = blk_2;
				got_data = get_data(fp, bigendianFlag, &blk_2, new_NT_format);
			} // TIMES WITHIN INTERVAL
			//data_len--; // To be correct you need to subract one.
			/////////////////////////////////////////////////////////////////////////////////////////////////
			// Interpolate.
			/////////////////////////////////////////////////////////////////////////////////////////////////
			//mexPrintf("\nPOLINT %i %i %g\n",sizeof(t_out),sizeof(D_out),ts_interval_for_desired/ts_interval_for_actual);
			/////////////////////////////////////////////////////////////////////////////////////////////////
			// Find the record in the data closest to the current t_out timestamp.
			// In reality, I should not need to do this, I should be able to estimate the jump size
			// by teh ration of actual to desired intervals.
			/////////////////////////////////////////////////////////////////////////////////////////////////
			int jump_interval_idx = ceil(ts_interval_for_desired/ts_interval_for_actual);
			// Find the start position.
			//int idx = binsearch(data_len, original_times, (t_out + t_out_count));
			//idx = idx - interval_width_in_idxs; // Move to the beginning of the window of interpolation.
			//if (idx < 0) // Check to see if we are out of range of the data.
	     	//		idx = 1;
			int idx = 0;
			int tmp_idx = 0;
			double step_time_ts = ceil(ts_interval_for_desired/2.0);
			//mexPrintf("1) %11.0G %11.0g  st %g   tout = %11.0g  idx %i i = %i data_len = %i   est_interval_size_blocks %i invl %g endintvl %g  \n",original_times[idx ],original_times[idx + interval_width_in_idxs], step_time_ts, t_out[t_out_count],idx,i,data_len,est_interval_size_blocks,*(intervals + interval_count + n_intervals),interval_end_ts[interval_count]);
			original_times[data_len-1] = 1e20;
			do{
				// assumes ascending order (should always be)
				// There is room for optimization here. The size of the search region could be limited considerably.
				//
				// Binsearch does not get the closest, it finds the floor -- the lower timestamp.
				tmp_idx = binsearch(data_len - idx + 1, &original_times[idx], (t_out + t_out_count));
				//idx = data_len - idx - 1; // This converts it to the absolute (from the relative).
				//idx = idx + tmp_idx - interval_width_in_idxs/2; // This converts it to the absolute (from the relative) and moves it to the beginning of the window.
				idx = idx + tmp_idx; // This converts it to the absolute (from the relative) and moves it to the beginning of the window.
				// I should not need the following as I have extra buffer space on the end.
				if (idx > (data_len-1)){
					idx = data_len-1;
					mexPrintf("O1!");
				}

				//if(t_out_count%100 == 0)
				//		mexPrintf("2) %11g  tout[%i] = %g idx %i i = %i data_len = %i  DATA = %i est_interval_size_blocks %i invl %g endintvl %g  \n",original_times[idx], t_out_count,t_out[t_out_count], idx,i,data_len,original_data[idx + interval_width_in_idxs - 1],est_interval_size_blocks,*(intervals + interval_count + n_intervals),interval_end_ts[interval_count]);
				
				//	if (t_out_count+1 > out_rows){
				//		//mexPrintf("t_out_count %i t_out %g end: %g\n",t_out_count,*(t_out + t_out_count-1) ,*(intervals + interval_count + n_intervals));
				//		mexPrintf("O2!!");
				//		break;
				//	}
				/////////////////////////////////////////////////////////////////////////////////////////////////
				// Screw interpolation, just take the closest thing (actually, a hanning). (I could take a local average, but why bother - the results look just fine.
				//  This is REALLY FAST. THE BETTER OPTION, ESP IF A VERY LOW sFREQ is desired is to take the average of all the points
				// between the output indices.
				/////////////////////////////////////////////////////////////////////////////////////////////////
				// To do the averaging, I just need to have a while loop here that adds up vals in the original data
				// until it reaches the end of a bin in the original data. After this it should 
				// divide by the number of samples it took to reach this. It should also add half the 
				// bin duration to the current timestamp as timestamps "should" be centered on the bin.
				/////////////////////////////////////////////////////////////////////////////////////////////////
				  int tmp_idx2 = idx;
				  while( original_times[tmp_idx2] < ts_interval_for_desired  + *(t_out + t_out_count) )
				  {
				      *(D_out + t_out_count + out_rows*file_count ) = *(D_out + t_out_count + out_rows*file_count ) + original_data[tmp_idx2];
				      tmp_idx2++;
			  	  }
			  	  // Get the average.
			  	  if (tmp_idx2 == idx)
			  	  {
			  	      // For whatever reason, the current desired output timestamp was the same as or less than the closest
			  	      // original timestamp. Perhaps the user passed a range out of bounds of the data? I don't know,
			  	      // but sometimes it happens.
 			  	      mexPrintf("?");
			  	  }else
			  	  {
			  	      *(D_out + t_out_count + out_rows*file_count ) =  *(D_out + t_out_count + out_rows*file_count ) / (tmp_idx2 - idx);
			  	  }
				  // Center the interval
				  *(t_out + t_out_count) = *(t_out + t_out_count) + step_time_ts;
                  //				     *(D_out + t_out_count + out_rows*file_count ) = original_data[idx-1]*.25 + original_data[idx]*.50 + original_data[idx+1]*.25;
				/////////////////////////////////////////////////////////////////////////////////////////////////
				// Linear interpolation. Need to subtract 1 since the numerical recipes convention is start arrays with 1.
				//  I did not have the patience to get this to work.
				/////////////////////////////////////////////////////////////////////////////////////////////////
				//polint(original_times + idx - 1, original_data + idx + interval_width_in_idxs - 1, interval_width_in_idxs, *(t_out + t_out_count), D_out + t_out_count + out_rows*file_count, dy);
				t_out_count++; 

			}while (*(t_out + t_out_count) <= *(intervals + interval_count + n_intervals) && (t_out_count < out_rows));
	
		}// INTERVAL
		/////////////////////////////////////////////////////////////////////////////////////////////////

		//timestamp_buffer
		fclose(fp);
	}// FILE
	mxFree(original_times);
	mxFree(original_data);
	mxFree(fn);
	// Option: If the user wants to re-reference the data, they may do it here.
}
