/*---------------------------------
 * Waveform_Parameters
 * MEX file - goes through a neuralynx spike file and resamples the data after curve fitting at the new, higher,sampling rate and generates new parameters.
 
 The new parameters include:

 Peak width, peak to trough width, peak, valley. 


 *
 * input:
 *    fn = file name string
 *
 * output:
 *    [t, p]
 *    t = n x 1: timestamps of each spike in file
 *    p = n x 4*nchannels parameters: peak, trough, peak half width, peak to trough
 *
 * Reads Neuralynx tetrode (ST) files, based on the Windows-family processors.
 * by checking if a header exists (for sun STfiles) or not (for NT-STfiles)
 * Checks for standard Neuralynx header if present (in Cheeath versions >= 1.3)
 * and automatically skips header.
 *
 *Cowen 2009
%
% Status: PROMOTED (Release version)
% See documentation for copyright (owned by original authors) and warranties (none!).
% This code released as part of MClust 3.0.
% Version control M3.0.
 *--------------------------------*/

#include "mex.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <matrix.h>
// #include "sys/malloc.h" // For MAC
#include <malloc.h>  // For PC

#ifdef __GNUC__
#define __int64 long long
#endif

#ifdef __GNUC__
const long long  TIMESTAMP_MAX = 0x00FFFFFFFFFFFFFFLL;  //( = 2^52-1; the largest integer fitting
#else
const __int64 TIMESTAMP_MAX = 0x00FFFFFFFFFFFFFF;  //( = 2^52-1; the largest integer fitting
#endif

// needed for structure to align correctly.
#pragma pack(1)

#define N_TRODES 2 
#define UPSAMPLE_POINTS 200
#define N_PARAMETERS 4
//___________________________________________________________________________________
// Numerical Recipes

void free_vector ( float	*v, int	n1, int nh)
{
  free((char*) (v+n1));
}

void nrerror(char error_text[])
{
//  void exit();

  fprintf(stderr,"Numerical Recipes run-time error...\n");
  fprintf(stderr,"%s\n",error_text);
  fprintf(stderr,"...now exiting to system...\n");
}


float *vector(int	n1,int nh)
{
  float	*v;
  v = (float*)malloc((unsigned) (nh-n1+1)*sizeof(float));
  if(!v) nrerror("allocation failure in vector()");
  return v-n1;
}

void spline(float x[], float y[], int n, float yp1, float ypn, float y2[])
/* Given arrays x[1..n] and y[1..n] containing a tabulated function, i.e., yi = f(xi),with
x1 < x2 <...< xN, and given values yp1 and ypn for the ï¬?rst derivative of the interpolating
function at points 1 and n, respectively, this routine returns an array y2[1..n] that contains
the second derivatives of the interpolating function at the tabulated points xi.If yp1 and/or
ypn are equal to 1 Ã— 1030 or larger, the routine is signaled to set the corresponding boundary
condition for a natural spline, with zero second derivative on that boundary.
*/
{
int i,k;
float p,qn,sig,un,*u;
u=vector(1,n-1);
if (yp1 > 0.99e30) // The lower boundary condition is set either to be â€œnat-uralâ€? 
	y2[1]=u[1]=0.0;
else { // or else to have a speciï¬?ed ï¬?rst derivative.
	y2[1] = -0.5;
	u[1]=(3.0/(x[2]-x[1]))*((y[2]-y[1])/(x[2]-x[1])-yp1);
}
for (i=2;i<=n-1;i++) { // This is the decomposition loop of the tridiagonal algorithm. y2 and u are used for temporary storage of the decomposed factors.
	sig=(x[i]-x[i-1])/(x[i+1]-x[i-1]);
	p=sig*y2[i-1]+2.0;
	y2[i]=(sig-1.0)/p;
	u[i]=(y[i+1]-y[i])/(x[i+1]-x[i]) - (y[i]-y[i-1])/(x[i]-x[i-1]);
	u[i]=(6.0*u[i]/(x[i+1]-x[i-1])-sig*u[i-1])/p;
}
if (ypn > 0.99e30) // The upper boundary condition is set either to be â€œnaturalâ€? 
	qn=un=0.0;
else { // or else to have a speciï¬?ed ï¬?rst derivative.
	qn=0.5;
	un=(3.0/(x[n]-x[n-1]))*(ypn-(y[n]-y[n-1])/(x[n]-x[n-1]));
}
y2[n]=(un-qn*u[n-1])/(qn*y2[n-1]+1.0);
for (k=n-1;k>=1;k--) //This is the backsubstitution loop of the tridiagonal algorithm. 
	y2[k]=y2[k]*y2[k+1]+u[k];
	free_vector(u,1,n-1);
}

void splint(float xa[], float ya[], float y2a[], int n, float x, float *y)
//Given the arrays xa[1..n] and ya[1..n], which tabulate a function (with the xaiâ€™s in order),
//and given the array y2a[1..n], which is the output from spline above, and given a value of
//x, this routine returns a cubic-spline interpolated value y.
{
void nrerror(char error_text[]);
int klo,khi,k;
float h,b,a;
klo=1; 
/*We will ï¬?nd the right place in the table by means of
bisection. This is optimal if sequential calls to this
routine are at random values of x. If sequential calls
are in order, and closely spaced, one would do better
to store previous values of klo and khi and test if
they remain appropriate on the next call.
*/
khi=n;
while (khi-klo > 1) {
	k=(khi+klo) >> 1;
if (xa[k] > x) khi=k;
else klo=k;
}// klo and khi now bracket the input value of x.
h=xa[khi]-xa[klo];
if (h == 0.0) 
	nrerror("Bad xa input to routine splint"); // The xaâ€™s must be distinct. 
a=(xa[khi]-x)/h;
b=(x-xa[klo])/h; // Cubic spline polynomial is now evaluated.
*y=a*ya[klo]+b*ya[khi]+((a*a*a-a)*y2a[klo]+(b*b*b-b)*y2a[khi])*(h*h)/6.0;
}

// END Numerical Recipes

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
    // changed end = n-1 to end = n to allow retrieval of last record in file (ncst)
    
    int start = 0;
    int end = 0;
    int mid = 0;
    double tmp;
    
    // binary search
    start = 0;
    end = n;
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
//===================================================================================
//-----------------------------------------------------------------------------------
// Loading Functions

const int recSize = 176;
const int recSizeAfterTimestamp = recSize - sizeof(__int64);

//___________________________________________________________________________________
void GetOneRecord(FILE *fp, double &T, double wv[128])
// reads one record and goes to the next record
{
    int bigendianFlag = bigendianMachine();
    
    // NT TT record
    __int64 qwTimeStamp, qwTimeStamp0;
    long dwParams[10];
    short snData[128];
    
    fread(&qwTimeStamp0,  sizeof(char),   8, fp);
    fread(dwParams,      sizeof(char),  40, fp);
    fread(snData  ,      sizeof(char), 128, fp);
    
    if(bigendianFlag){				// convert from NT(little endian) to Sun (big endian)
        qwTimeStamp = swapbytes(qwTimeStamp0);
        if(qwTimeStamp > TIMESTAMP_MAX){
            mexPrintf(" ERROR: timestamp is too large to fit in a double!\n");
            mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
        }
        T = (double) qwTimeStamp/100.0;
        for (int j = 0; j<2; j++)
            for(int k = 0; k<32; k++)
                wv[j + 4*k] = (double) swapbytes(snData[j + 2*k]);
 /*     
		for (int j = 2; j<4; j++)
            for(int k = 0; k<32; k++)
                wv[j + 4*k] = 0; 
*/

        
    } else {
        // don't convert, just copy
        qwTimeStamp = qwTimeStamp0;
        if(qwTimeStamp > TIMESTAMP_MAX){
            mexPrintf(" ERROR: timestamp is too large to fit in a double!\n");
            mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
        }
        T = (double) qwTimeStamp/100.0;
        for (int j = 0; j<2; j++)
            for(int k = 0; k<32; k++)
                wv[j + 4*k] = (double) snData[j + 2*k];
 /*     
        for (int j = 2; j<4; j++)
            for(int k = 0; k<32; k++)
                wv[j + 4*k] = 0;
*/
    }
    
}
void GetOneRecordST(FILE *fp, double &T, double wv[64])
// reads one record and goes to the next record
{
    int bigendianFlag = bigendianMachine();
    
    // NT TT record
    __int64 qwTimeStamp, qwTimeStamp0;
    long dwParams[10];
    short snData[64];
    
    fread(&qwTimeStamp0,  sizeof(char),   8, fp);
    fread(dwParams,      sizeof(char),  40, fp);
    fread(snData  ,      sizeof(char), 64, fp);
    
    if(bigendianFlag){				// convert from NT(little endian) to Sun (big endian)
        qwTimeStamp = swapbytes(qwTimeStamp0);
        if(qwTimeStamp > TIMESTAMP_MAX){
            mexPrintf(" ERROR: timestamp is too large to fit in a double!\n");
            mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
        }
        T = (double) qwTimeStamp/100.0;
        for (int j = 0; j<2; j++)
            for(int k = 0; k<32; k++)
                wv[j + N_TRODES*k] = (double) swapbytes(snData[j + 2*k]);
        
    } else {
        // don't convert, just copy
        qwTimeStamp = qwTimeStamp0;
        if(qwTimeStamp > TIMESTAMP_MAX){
            mexPrintf(" ERROR: timestamp is too large to fit in a double!\n");
            mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
        }
        T = (double) qwTimeStamp/100.0;
        for (int j = 0; j<2; j++)
            for(int k = 0; k<32; k++)
                wv[j + N_TRODES*k] = (double) snData[j + 2*k];
    }    
}

//___________________________________________________________________________________
int GetNumberOfSpikes(char* fn){
    
    // open file
    FILE* fp = fopen(fn, "rb");
    if (!fp)
        mexErrMsgTxt("Could not open file.");
    
    //skip header and determine file record size
    int new_NT_format = SkipHeader(fp);
    if (!new_NT_format)
        mexErrMsgTxt("Old SunOS formats are not supported by this loading engine.");
    SkipCheetahNTHeader(fp);     // Skip standard Neuralynx header if present (Cheetah versions >= 1.3)
    
    // get filesize
    int postHeaderPos = ftell(fp);     // beginnig of file after header (if any)
    fseek(fp,0,2);                     // goto end of file
    int nbytes = ftell(fp) - postHeaderPos;
    
    int nSpikes = nbytes/recSize; // no need to skip last record for NT_cheetah files
    mexPrintf("Reading file %s:\nRecordSize = %d,  %d spikes, %d bytes.\n",fn, recSize, nSpikes, nbytes);
    
    // cleanup
    fclose(fp);
    
    return nSpikes;
}


//___________________________________________________________________________________
void get_wv_params(float *y, float *p){
	float x[32];
    float y2[32];
    float x_sp[200];
    float y_sp[200];
	float yy,xx,res,start_t;
	float peak_t, trough_t, halfwidth_t1, halfwidth_t2;
	float peak, trough, prev_dx, curr_dx;


	for (int i = 0; i < 32; i++)
		x[i] = (float) i;
	for (int i = 0; i < UPSAMPLE_POINTS; i++)
		x_sp[i] = (float) i;
	// Interpolate.

	spline(x-1, y-1, 32, 2.0, 2.0, y2-1);
	/* Given arrays x[1..n] and y[1..n] containing a tabulated function, i.e., yi = f(xi),with
	x1 < x2 <...< xN, and given values yp1 and ypn for the ï¬?rst derivative of the interpolating
	function at points 1 and n, respectively, this routine returns an array y2[1..n] that contains
	the second derivatives of the interpolating function at the tabulated points xi.If yp1 and/or
	ypn are equal to 1 Ã— 1030 or larger, the routine is signaled to set the corresponding boundary
	condition for a natural spline, with zero second derivative on that boundary. */
	// Now get the parameters

	// Peak and peak location and valley_before_peak and valley_after_peak (x and y)

	// Peak 
	start_t = 6.0;

	splint(x-1, y-1, y2-1, 32, start_t, &y_sp[0]); // get the first point
	//prev_dx = 1; // assume that it's rising.
	peak = 0;
	peak_t = 11.0; // default peak time (0-31 points)
	for(int m = 1; m<100; m++)
	{
		xx = ((float) m)/100 * 5 + start_t; // assme the peak is between 6 and point 11
		splint(x-1, y-1, y2-1, 32, xx, &y_sp[m]);
		if ((y_sp[m] - y_sp[m-1]) <= 0)
		{
			peak = y_sp[m-1];
			peak_t = xx;//-0.01*5; // add 1 because C starts at 0
			break;
		}
		//prev_dx = curr_dx;
		//mexPrintf("%5.2f, ", y_sp[m]);
	}


	// Trough 
	start_t = peak_t + 1.4;
	splint(x-1, y-1, y2-1, 32, start_t, &y_sp[0]); // get the first point
	//prev_dx = -1; // assume that it's falling.
	trough = 0;
	trough_t = 31; // default if no trough is found.
	for(int m = 1; m<200; m++)
	{
		xx = ((float) m) * 15.0*0.005 + start_t; // assme the trough is at least 2 points in front of the peak.
		splint(x-1, y-1, y2-1, 32, xx, &y_sp[m]);
		if ((y_sp[m] - y_sp[m-1]) > 0 )
		{
			trough = y_sp[m-1];
			trough_t = xx;//-0.01*12; // add 1 because C starts at 0
			break;
		}
		//prev_dx = curr_dx;
		//mexPrintf("%5.2f, ", y_sp[m]);
	}

	// Half width
	// Move on down until you get a value less than 1/2 the peak value.
	// This looks fine.
	float v = 1.0;
	float cur_time ;
	yy = peak;
	cur_time = peak_t;
	while(yy > (peak/2.0) && yy > 0 && cur_time > 2)
	{
		cur_time = peak_t-v*0.02;
		splint(x-1, y-1, y2-1, 32, cur_time, &yy);
		v = v + 1.0;
	}

	halfwidth_t1 = cur_time;
	v = 1.0;
	yy = peak;
	cur_time = peak_t;
	while(yy > (peak/2.0) && yy > 0 && cur_time < 20)
	{
		cur_time = peak_t+v*0.02;
		splint(x-1, y-1, y2-1, 32, cur_time, &yy);
		v = v + 1.0;
	}
	halfwidth_t2 = cur_time;
	// Assign the values.
	p[0] = (double) peak;
	p[1] = (double) trough;
	p[2] = (double) trough_t - peak_t;
	p[3] = (double) halfwidth_t2 - halfwidth_t1; //halfwidth_t2 - halfwidth_t1;
}
/////////////////////////////////////////////////////////////////////////////////////
void Waveform_Parameters_ST(char* fn, int nSpikes, double *t, double *params){
    double t0;
    double wv0[128];
    float y[32], p[4];
    
    // open file
    FILE *fp = fopen(fn, "rb");
    if (!fp)
        mexErrMsgTxt("ERROR: Could not open file.");
    
    // skip header
    int new_NT_format = SkipHeader(fp);  // flag for new NT_format TT files (0=old SUN, 1=new NT)
    if (!new_NT_format)
        mexErrMsgTxt("Old sun format not supported by this loading engine.");
    SkipCheetahNTHeader(fp);     // Skip standard Neuralynx header if present (Cheetah versions >= 1.3)
    long postHeaderPos = ftell(fp);
	//
	// read records and convert all to double
	fseek(fp, postHeaderPos, SEEK_SET);
	// for (int i = 0; i < nSpikes; i++){
	// Limit to 100
//	nSpikes = 10;
	for (int i = 0; i < nSpikes; i++)
	{
		GetOneRecord(fp,t0,wv0);
		t[i] = t0;
   
		for (int j = 0; j<2; j++)
		{
			// Interpolate and generate parameters.
			for(int k = 0; k<32; k++)
			{
				y[k] = (float) wv0[j + 4*k]; // Make things remotely readable.
				//mexPrintf("%f, ", y[k]);
				//mexPrintf("%g, ", wv0[j + 4*k]);

			}

			get_wv_params(y,p);
			// fill up the params data.
			for (int m=0;m<4;m++)
				params[i + (j*N_PARAMETERS+m)*nSpikes] = (double) p[m];
		}
		// mexPrintf(";\n");
	}
    fclose(fp);
	//mexErrMsgTxt("made it this far,=");
}

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

void ReadST(char* fn, int nSpikes, double *t, double *wv){
    
    double t0;
    double wv0[64];
    
    // open file
    FILE * fp = fopen(fn, "rb");
    if (!fp)
        mexErrMsgTxt("ERROR: Could not open file.");
    
    // skip header
    int new_NT_format = SkipHeader(fp);  // flag for new NT_format TT files (0=old SUN, 1=new NT)
    if (!new_NT_format)
        mexErrMsgTxt("Old sun format not supported by this loading engine.");
    SkipCheetahNTHeader(fp);     // Skip standard Neuralynx header if present (Cheetah versions >= 1.3)
    long postHeaderPos = ftell(fp);
    
    // read records and convert all to double
    fseek(fp, postHeaderPos, SEEK_SET);
    for (int i = 0; i < nSpikes; i++){
        GetOneRecord(fp,t0,wv0);
        t[i] = t0;
        for (int j = 0; j<N_TRODES; j++)
            for(int k = 0; k<32; k++)
                wv[i + nSpikes*j + nSpikes*N_TRODES*k] = (double) wv0[j + N_TRODES*k];
    }
    
    fclose(fp);
}

void ReadTT(char* fn, int nSpikes, double *t, double *wv){
    
    double t0;
    double wv0[128];
    
    // open file
    FILE *fp = fopen(fn, "rb");
    if (!fp)
        mexErrMsgTxt("ERROR: Could not open file.");
    
    // skip header
    int new_NT_format = SkipHeader(fp);  // flag for new NT_format TT files (0=old SUN, 1=new NT)
    if (!new_NT_format)
        mexErrMsgTxt("Old sun format not supported by this loading engine.");
    SkipCheetahNTHeader(fp);     // Skip standard Neuralynx header if present (Cheetah versions >= 1.3)
    long postHeaderPos = ftell(fp);
    
    // read records and convert all to double
    fseek(fp, postHeaderPos, SEEK_SET);
    for (int i = 0; i < nSpikes; i++){
        GetOneRecord(fp,t0,wv0);
        t[i] = t0;
        for (int j = 0; j<N_TRODES; j++)
            for(int k = 0; k<32; k++)
                wv[i + nSpikes*j + nSpikes*N_TRODES*k] = (double) wv0[j + N_TRODES*k];
    }
    
    fclose(fp);
}

//_________________________________________________________________________________________________
void ReadTTByRecord(char* fn, double *records_to_get, int n_records_to_get, double *t, double *wv)
// Open the file and fseek to just those record number passed in
// in the array: records_to_get. The last record of records to get
// indicates the end of records. It's code is END_OF_RECORDS.
{
    int i = 0;
    double t0;
    double wv0[128];
    
    // open file
    FILE *fp = fopen(fn, "rb");
    if (!fp)
        mexErrMsgTxt("ERROR: Could not open file.");
    
    // skip header
    int new_NT_format = SkipHeader(fp);  // flag for new NT_format TT files (0=old SUN, 1=new NT)
    if (!new_NT_format)
        mexErrMsgTxt("Old sun format not supported by this loading engine.");
    SkipCheetahNTHeader(fp);     // Skip standard Neuralynx header if present (Cheetah versions >= 1.3)
    long postHeaderPos = ftell(fp);
    
    // read records and convert all to double
    while(i < n_records_to_get)
    {
        // Go directly to the record in question. Do not pass go. NO $200.
        fseek(fp, postHeaderPos+sizeof(char)*(recSize)*((long)records_to_get[i] - 1), SEEK_SET);
        GetOneRecord(fp,t0,wv0);
        t[i] = t0;
        for (int j = 0; j<N_TRODES; j++)
            for(int k = 0; k<32; k++)
                wv[i + n_records_to_get*j + n_records_to_get*N_TRODES*k] = (double) wv0[j + N_TRODES*k];
        i++;
    }
    fclose(fp);
}

//___________________________________________________________________________________
void ReadTT_timestamps(char* fn, int nSpikes, double *t)
{
    double t0;
    double wv0[128];
    
    // open file
    FILE *fp = fopen(fn, "rb");
    if (!fp)
        mexErrMsgTxt("ERROR: Could not open file.");
    
    // skip header
    int new_NT_format = SkipHeader(fp);  // flag for new NT_format TT files (0=old SUN, 1=new NT)
    if (!new_NT_format)
        mexErrMsgTxt("Old sun format not supported by this loading engine.");
    SkipCheetahNTHeader(fp);     // Skip standard Neuralynx header if present (Cheetah versions >= 1.3)
    long postHeaderPos = ftell(fp);
    
    // read records and convert all to double
    fseek(fp, postHeaderPos, SEEK_SET);
    for (int i = 0; i < nSpikes; i++)
    {
        GetOneRecord(fp,t0,wv0);
        t[i] = t0;
    }
    fclose(fp);
}

//___________________________________________________________________________________
void mexFunction(int nOUT, mxArray *pOUT[],int nINP, const mxArray *pINP[])
{   
    int i;
	mxArray *all_wv;
 	mxArray *all_p;
    double *records_to_get, *range_to_get,*t,*params,*wv, *all_timestamps;
    int n_records_to_get = 0;
    int record_units = 0;
    int nSpikes = 0;
    int length_records_to_get = 0;
    int start_idx=0;
    int end_idx = 0;
    int idx = 0;
	float wwv[32];
	float p[4],y[32];
    /* check number of arguments: expects 1 input */
    if (nINP != 2 && nINP != 1)
        mexErrMsgTxt("Call with fn or with waveforms(n x 32).");
    if (nOUT > 2)
        mexErrMsgTxt("Requires two outputs if a file is specified, or one output if waveforms are passed in.");
	/////////////////////////////////////////////////
	/* read inputs */
	/////////////////////////////////////////////////
	// 
	if (mxIsNumeric(pINP[0])==0)
	{
		int fnlen = (mxGetM(pINP[0]) * mxGetN(pINP[0])) + 1;
		char *fn = (char *) mxCalloc(fnlen, sizeof(char));
		if (!fn)
			mexErrMsgTxt("Not enough heap space to hold converted string.");
		int errorstatus = mxGetString(pINP[0], fn,fnlen);
		if (errorstatus)
			mexErrMsgTxt("Could not convert string data.");
	    
		nSpikes = GetNumberOfSpikes(fn);
	   // nSpikesInFile = 30;

		////////////////////////////////////////////////////////
		// create outputs
		////////////////////////////////////////////////////////
		mexPrintf("Getting %i records.\n",nSpikes);

		pOUT[0] = mxCreateDoubleMatrix(nSpikes , 1, mxREAL);
		t = mxGetPr(pOUT[0]);

		pOUT[1] = mxCreateDoubleMatrix(nSpikes, N_PARAMETERS*N_TRODES, mxREAL); // The parameters.,
		params = mxGetPr(pOUT[1]);
		//

		////////////////////////////////////////////////////////
		// load st or st file fn into t and wv arrays
		////////////////////////////////////////////////////////
	    
		Waveform_Parameters_ST(fn, nSpikes ,t,params);
	    
		////////////////////////////////////////////////////////
		// cleanup
		////////////////////////////////////////////////////////
		t = mxGetPr(pOUT[0]);
		mxFree(fn);
	}
	else
	{
		// The user passed in a matrix of waveforms (nx32).
		nSpikes = mxGetM(pINP[0]);
		pOUT[0] = mxCreateDoubleMatrix(nSpikes, N_PARAMETERS, mxREAL); // The parameters.,
		wv = mxGetPr(pINP[0]);
		params = mxGetPr(pOUT[0]);
		//mexPrintf("%i/n ", nSpikes);
		for (i=0;i<nSpikes;i++)
		{
			for(int k = 0; k<32; k++)
			{
				//y[k] = wv[i]
				y[k] = (float) wv[i+nSpikes*k]; // M
			//	mexPrintf("%f, ", y[k]);
			}
		//	mexPrintf("\n");
			get_wv_params(y,p);
			// fill up the params data.
			for (int m=0;m<4;m++)
				params[i + m*nSpikes] = (double) p[m];
			//params[i] = (double) i;
		}
	}
    return;  
}
