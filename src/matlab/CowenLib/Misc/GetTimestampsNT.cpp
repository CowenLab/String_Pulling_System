/*---------------------------------
* Spike_count_nt   Count the number of records in the file.
* MEX file         and get start and end time.
*
* input:
*    fn = file name string
*
* output:
*    [nrecs, start_timestamp, end_timestamp]
*
* cowen 10/19/01: 
* PL Sept 2000 
*--------------------------------*/

#include "mex.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <matrix.h>

#ifdef __GNUC__
#define __int64 long long 
#endif


#define BY_TIMESTAMP 1
#define BY_RECORD 2
#define BY_TIMESTAMP_RANGE 3
#define BY_RECORD_RANGE 4

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
	    mexPrintf("NT-Header skipped (%d bytes)\n",NHEADERBYTES);
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
int GetNumberOfSpikes(char* fn){
	
	// open file 
	FILE* fp = fopen(fn, "rb");
	if (!fp)
		mexErrMsgTxt("Could not open file.");

	//skip header and determine file record size
	int new_NT_format = SkipHeader(fp);
    if (new_NT_format) SkipCheetahNTHeader(fp);     // Skip standard Neuralynx header if present (Cheetah versions >= 1.3)

	int recSize = 260;
	if (new_NT_format) recSize = 304; 
        
	// get filesize
	int postHeaderPos = ftell(fp);     // beginnig of file after header (if any)
	fseek(fp,0,2);                     // goto end of file
	int nbytes = ftell(fp) - postHeaderPos;

	int nSpikes = nbytes/recSize -1;    // skip last record since it may be incomplete 
	if (new_NT_format) nSpikes = nbytes/recSize; // no need to skip last record for NT_cheetah files
//	mexPrintf("Reading file %s:\nRecordSize = %d,  %d spikes, %d bytes.\n",
//		fn, recSize, nSpikes, nbytes);

	// cleanup
	fclose(fp);	

	return nSpikes;
}


//___________________________________________________________________________________
void ReadTT(char* fn, int nSpikes, double *t, double *wv){
	
#ifdef __GNUC__
	const long long  TIMESTAMP_MAX = 0x00FFFFFFFFFFFFFFLL;  //( = 2^52-1; the largest integer fitting
#else
	const __int64 TIMESTAMP_MAX = 0x00FFFFFFFFFFFFFF;  //( = 2^52-1; the largest integer fitting
#endif
	//   in a double IEEE mantissa (=7 bytes)
	int bigendianFlag = bigendianMachine();
	
	// NT TT record
	__int64 qwTimeStamp, qwTimeStamp0;
	long dwParams[10];
	short snData[128];
	
	// sun TT record
	long tmpT;
	short tmpWV[128];
	
	// open file 
	FILE *fp = fopen(fn, "rb");
	if (!fp)
		mexErrMsgTxt("ERROR: Could not open file.");
	
	// skip header 
	int new_NT_format = SkipHeader(fp);  // flag for new NT_format TT files (0=old SUN, 1=new NT) 
	if (new_NT_format) SkipCheetahNTHeader(fp);     // Skip standard Neuralynx header if present (Cheetah versions >= 1.3)
	long postHeaderPos = ftell(fp);
	
	if (new_NT_format){ 
		
		// read records and convert all to double
		fseek(fp, postHeaderPos, SEEK_SET);
		for (int i = 0; i < nSpikes; i++){
			
			fread(&qwTimeStamp0,  sizeof(char),   8, fp);
			fread(dwParams,      sizeof(char),  40, fp);
			fread(snData  ,      sizeof(char), 256, fp);
			
			if(bigendianFlag){
				// convert from NT(little endian) to Sun (big endian)
				qwTimeStamp = swapbytes(qwTimeStamp0);
				if(qwTimeStamp > TIMESTAMP_MAX){
					mexPrintf(" ERROR: timestamp %d in file %s is too large to fit in a double!\n",i,fn);
				   mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
				}
				t[i] = (double) qwTimeStamp/100.0;
				for (int j = 0; j<4; j++)
					for(int k = 0; k<32; k++)
						wv[i + nSpikes*j + nSpikes*4*k] = (double) swapbytes(snData[j + 4*k]);  
				
			} else {
				// don't convert, just copy
				qwTimeStamp = qwTimeStamp0;
				if(qwTimeStamp > TIMESTAMP_MAX){
					mexPrintf(" ERROR: timestamp %d in file %s is too large to fit in a double!\n",i,fn);
				   mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
				}
				t[i] = (double) qwTimeStamp/100.0;
				for (int j = 0; j<4; j++)
					for(int k = 0; k<32; k++)
						wv[i + nSpikes*j + nSpikes*4*k] = (double) snData[j + 4*k];  
			}
			
		}
		
	} else {    /*  OLD sun cheetah format */
		
		// read t, wv 
		fseek(fp, postHeaderPos, SEEK_SET);
		for (int i = 0; i < nSpikes; i++){
			
			fread(&tmpT,  sizeof(char),   4, fp);
			fread(tmpWV, sizeof(char), 256, fp);
			
			if (bigendianFlag){
				// don't convert, just copy into Fortran (column oriented) arrays t,wv
				t[i] = (double) tmpT;
				for (int j = 0; j<4; j++)
					for(int k = 0; k<32; k++)
				  	   wv[i + nSpikes*j + nSpikes*4*k] = (double) tmpWV[j + 4*k];
			} else { 
				// convert from Sun (big endian) to NT(little endian) 
				t[i] = (double) swapbytes(tmpT);
				for (int j = 0; j<4; j++)
					for(int k = 0; k<32; k++)
				  	   wv[i + nSpikes*j + nSpikes*4*k] = (double) swapbytes(tmpWV[j + 4*k]);
			}	
		}
	}
   fclose(fp);	
}	

///////////////////////////////////////////////////////////////////
// Open the file and fseek to just those record number passed in 
// in the array: records_to_get. The last record of records to get 
// indicates the end of records. It's code is END_OF_RECORDS.
///////////////////////////////////////////////////////////////////


void ReadTTByRecord(char* fn, double *records_to_get, int n_records_to_get, double *t){
	
#ifdef __GNUC__
	const long long  TIMESTAMP_MAX = 0x00FFFFFFFFFFFFFFLL;  //( = 2^52-1; the largest integer fitting
#else
	const __int64 TIMESTAMP_MAX = 0x00FFFFFFFFFFFFFF;  //( = 2^52-1; the largest integer fitting
#endif

	///////////////////////////////////////////////////////////////////
	int i = 0;

	///////////////////////////////////////////////////////////////////
	//   in a double IEEE mantissa (=7 bytes)
	///////////////////////////////////////////////////////////////////
	int bigendianFlag = bigendianMachine();
	
	///////////////////////////////////////////////////////////////////
	// NT TT record
	///////////////////////////////////////////////////////////////////
	__int64 qwTimeStamp, qwTimeStamp0;
	long dwParams[10];
	short snData[128];
	
	///////////////////////////////////////////////////////////////////
	// sun TT record
	///////////////////////////////////////////////////////////////////
	long tmpT;
	short tmpWV[128];
		
	///////////////////////////////////////////////////////////////////
	// open file 
	///////////////////////////////////////////////////////////////////

	FILE *fp = fopen(fn, "rb");
	if (!fp)
		mexErrMsgTxt("ERROR: Could not open file.");
	
	///////////////////////////////////////////////////////////////////
	// skip header 
	///////////////////////////////////////////////////////////////////
	int new_NT_format = SkipHeader(fp);  // flag for new NT_format TT files (0=old SUN, 1=new NT) 
	if (new_NT_format) SkipCheetahNTHeader(fp);     // Skip standard Neuralynx header if present (Cheetah versions >= 1.3)
	long postHeaderPos = ftell(fp);
	
	if (new_NT_format)
	{ 
		
		///////////////////////////////////////////////////////////////////
		// read records and convert all to double
		///////////////////////////////////////////////////////////////////
		while(i < n_records_to_get)
		{
			///////////////////////////////////////////////////////////////////
			// Go directly to the record in question. Do not pass go. NO $200.
			///////////////////////////////////////////////////////////////////
			fseek(fp, postHeaderPos+sizeof(char)*(8+40+256)*((long)records_to_get[i] - 1), SEEK_SET);
			
			///////////////////////////////////////////////////////////////////
			// Read the data.
			///////////////////////////////////////////////////////////////////
			fread(&qwTimeStamp0,  sizeof(char),   8, fp);
			fread(dwParams,       sizeof(char),  40, fp);
			fread(snData  ,       sizeof(char), 256, fp);
			
			if(bigendianFlag)
			{
				///////////////////////////////////////////////////////////////////
				// convert from NT(little endian) to Sun (big endian)
				///////////////////////////////////////////////////////////////////
				qwTimeStamp = swapbytes(qwTimeStamp0);
				if(qwTimeStamp > TIMESTAMP_MAX){
					mexPrintf(" ERROR: timestamp %d in file %s is too large to fit in a double!\n",i,fn);
				   mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
				}
				t[i] = (double) qwTimeStamp/100.0;
//				for (int j = 0; j<4; j++)
//					for(int k = 0; k<32; k++)
//						wv[i + n_records_to_get*j + n_records_to_get*4*k] = (double) swapbytes(snData[j + 4*k]);  
				
			} 
			else 
			{
				///////////////////////////////////////////////////////////////////
				// don't convert, just copy
				///////////////////////////////////////////////////////////////////
				qwTimeStamp = qwTimeStamp0;
				if(qwTimeStamp > TIMESTAMP_MAX){
					mexPrintf(" ERROR: timestamp %d in file %s is too large to fit in a double!\n",i,fn);
				   mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
				}
				t[i] = (double) qwTimeStamp/100.0;
//				for (int j = 0; j<4; j++)
//					for(int k = 0; k<32; k++)
//						wv[i + n_records_to_get*j + n_records_to_get*4*k] = (double) snData[j + 4*k];  
			}
			i++;
		}
		
	} else {    /*  OLD sun cheetah format */
		
		///////////////////////////////////////////////////////////////////
		// read records and convert all to double
		///////////////////////////////////////////////////////////////////
		while(i < n_records_to_get)
		{
			///////////////////////////////////////////////////////////////////
			// Go directly to the record in question. Do not pass go. NO $200.
			///////////////////////////////////////////////////////////////////
			fseek(fp, postHeaderPos+sizeof(char)*(4+256)*((long)records_to_get[i] - 1), SEEK_SET);
			
			fread(&tmpT,  sizeof(char),   4, fp);
			fread(tmpWV, sizeof(char), 256, fp);
			
			if (bigendianFlag){
				// don't convert, just copy into Fortran (column oriented) arrays t,wv
				t[i] = (double) tmpT;
//				for (int j = 0; j<4; j++)
//					for(int k = 0; k<32; k++)
//				  	   wv[i + n_records_to_get*j + n_records_to_get*4*k] = (double) tmpWV[j + 4*k];
			} else { 
				// convert from Sun (big endian) to NT(little endian) 
				t[i] = (double) swapbytes(tmpT);
//				for (int j = 0; j<4; j++)
//					for(int k = 0; k<32; k++)
//				  	   wv[i + n_records_to_get*j + n_records_to_get*4*k] = (double) swapbytes(tmpWV[j + 4*k]);
			}
			i++;
		}
	}
   fclose(fp);	
}	

//___________________________________________________________________________________
void mexFunction(int nOUT, mxArray *pOUT[],
				 int nINP, const mxArray *pINP[])
{
	
	int i;
	double *records_to_get,*t;
	int n_records_to_get = 0;
	int nSpikesInFile = 0;
	double a_rec[1];
	double *M;	
	double a_double;

	/* check number of arguments: expects 1 input */
	if (nINP != 1)
				mexErrMsgTxt("Call with fn.");
	if (nOUT > 3)
				mexErrMsgTxt("Requires 1-3 outputs (nrecs, starttimestamp, endtimestamp).");

	/* read inputs */
	int fnlen = (mxGetM(pINP[0]) * mxGetN(pINP[0])) + 1;
	char *fn = (char *) mxCalloc(fnlen, sizeof(char)); 
	if (!fn)
		mexErrMsgTxt("Not enough heap space to hold converted string.");
	int errorstatus = mxGetString(pINP[0], fn,fnlen);    
	if (errorstatus)
		mexErrMsgTxt("Could not convert string data.");


	nSpikesInFile = GetNumberOfSpikes(fn);
	pOUT[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
	M = mxGetPr(pOUT[0]); M[0] = (double)nSpikesInFile;
	if(nOUT >= 2)
	{	
		////////////////////////////////////////////////////////
		// Get the start timestamp
		////////////////////////////////////////////////////////
		t = &a_double;
		a_rec[0] = 1;
		ReadTTByRecord(fn,a_rec ,1,t);
		pOUT[1] = mxCreateDoubleMatrix(1, 1, mxREAL);
		M = mxGetPr(pOUT[1]); M[0] = t[0];
	}

	if (nOUT ==3)
	{
		////////////////////////////////////////////////////////
		// Get the last timestamp
		////////////////////////////////////////////////////////
		t = &a_double;
		a_rec[0] = nSpikesInFile;
		ReadTTByRecord(fn,a_rec ,1,t);
		pOUT[2] = mxCreateDoubleMatrix(1, 1, mxREAL);
		M = mxGetPr(pOUT[2]); M[0] = t[0];


	}
	

	// cleanup
	mxFree(fn);

}

