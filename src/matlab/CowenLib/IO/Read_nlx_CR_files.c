/*---------------------------------
* Read_nlx_CR_files (file_names_cell_array, sFreq, intervals_in_timestamps) 
* Read a set of CR files at once at the specified sampling frequency and send it off to matlab.
* MEX file
*
*
* input:
*    cell array of file names
*    intervals: EITHER a nInterval X 2 matrix of start and end timestamps for the intervals to load OR a 
*               vector of timestamps to load.
* 
* output:
*    [t,D]
*    t = timestamps for EACH record
*    D = Data: the data you wish to read where each column corresponds to each file you passed in.
TODO
 *   IF the CSC file is corrupt (wierd timestamps/hunt errors, etc..) then this program can hang. It should catch such problems and drop out or skip bad blocks.
*    interval_indices = would be nice if this returned the start and end index of each interval so that you 
*           could then could quickly pull the intervals out of the data.
* 
* NOTE: THIS DOES NOT WORK IF YOU DESIRE A SAMPLING RATE HIGHER THAN THE ORIGINAL RATE.
*
* [t, D] = Read_nlx_CR_files({'CSC11.ncs' 'CSC10.ncs'},[1215413846 1415413846;1515413846 1815413846 ]); 
*
* version 0.9 Stephen L Cowen  - stephen.cowen@yahoo.com
* cowen(2004) * cowen feb 06 got rid of the inlines which screwed things up for the default compiler 
   (requires a cpp compiler and the builtin matlab compiler is not cpp). cowen Sep 07 fixed overflow bug.
*
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
    // Given a vector of xa and ya, retrurs the polynomial fit (n-1 where n is vector length of xa) y at the point x. Error is dy.
    // from numerical recipes in C.
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
            d[i]= (short) (hp*den);
            c[i]= (short) (ho*den);
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
short swapbytes_short(short ii)
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
long swapbytes_long(unsigned long ii)
// swap byte order of a long: (0,1,2,3) -> (3,2,1,0)
{
    union {
        unsigned long l;
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
__int64 swapbytes__int64(__int64 ii)
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
    qwTimeStamp = swapbytes_long(qwTimeStamp);
    
    if(qwTimeStamp > TIMESTAMP_MAX){
        mexPrintf(" ERROR 1: timestamp %d is too large to fit in a double!\n",qwTimeStamp);
        mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
    }
    dwSampleFreq = swapbytes_long(dwSampleFreq);
    dwNumValidSamples = swapbytes_short(dwNumValidSamples);
    for (j = 0; j<512; j++)
        blk->Data[j] = swapbytes_short(blk->Data[j]);
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
        qwTimeStamp = swapbytes__int64(qwTimeStamp);
        if(qwTimeStamp > TIMESTAMP_MAX){
            mexPrintf(" ERROR: timestamp %d is too large to fit in a double!\n",qwTimeStamp);
            mexPrintf(" Converted timestamps MAY or MAY NOT be valid - proceed with care! \n");
        }
        dwChannelNum = swapbytes_long(dwChannelNum);
        dwSampleFreq = swapbytes_long(dwSampleFreq);
        dwNumValidSamples = swapbytes_long(dwNumValidSamples);
        for (j = 0; j<512; j++)
            blk->Data[j] = swapbytes_short(blk->Data[j]);
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
FILE  *get_file_info(char *fn, long *start_pos, long *end_pos, int *nRecords, double *start_ts, double *end_ts, double *block_interval_ts, double *usec_per_point, int *new_NT_format, int *bigendianFlag)
{
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Get a lot of general information about the CR file.
    //////////////////////////////////////////////////////////////////////////////////////////////////

    BLOCK_TYPE blk_1; /* The data from one block in the CR file */
    FILE *fp;
    int got_data;
    double second_ts;
    const int NEW_CR_RECSIZE = 8+sizeof(int)+2*sizeof(long)+512*sizeof(short);


    //////////////////////////////////////////////////////////////////////////////////////////////////
    // START FILE IO STUFF
    //////////////////////////////////////////////////////////////////////////////////////////////////
    fp = fopen(fn, "rb");
    if (!fp)
        mexErrMsgTxt("Could not open file.");
    
        /* skip header */
    *new_NT_format = SkipHeader(fp);
    if (*new_NT_format) SkipCheetahNTHeader(fp);     // Skip standard Neuralynx header if present (Cheetah versions >= 1.3)
        /* count number of Records and determine the start and end timestamps*/

    *start_pos = ftell(fp); // The post header start of the data.
    got_data = get_data(fp, *bigendianFlag, &blk_1, *new_NT_format);
    *start_ts = blk_1.TimeStamp;
    got_data = get_data(fp, *bigendianFlag, &blk_1, *new_NT_format);
    second_ts = blk_1.TimeStamp;
    *block_interval_ts = second_ts - *start_ts;
    *usec_per_point = *block_interval_ts/512;
    
    // Find the end timestamp and record.
    fseek(fp, 0, SEEK_END);
    *end_pos = ftell(fp);
    *nRecords = (int)floor((*end_pos - *start_pos) / NEW_CR_RECSIZE);
    
    // Move to the start of the last block
    fseek(fp, -NEW_CR_RECSIZE, SEEK_END);
    
    got_data = get_data(fp, *bigendianFlag, &blk_1, *new_NT_format);
    *end_ts = blk_1.TimeStamp;
    
    //mexPrintf("File contains %d CR records.\n", nRecords);
    return fp;
}

//___________________________________________________________________________________
void mexFunction(int nOUT, mxArray *pOUT[],
int nINP, const mxArray *pINP[])
{
    int bigendianFlag = bigendianMachine();
    long start_pos,end_pos;
    int new_NT_format =1;     /* flag for new NT_format TT files (0=old SUN, 1=new NT)  */
    char *fn;
    FILE *fp;
    int nRecords, n_files;
    const int NEW_CR_RECSIZE = 8+sizeof(int)+2*sizeof(long)+512*sizeof(short);
    
    unsigned long junk = 0;
    double *x, *y;
    double sampFreq0 = 0.0;

    const mxArray *file_list_ptr;
    const mxArray *fname_ptr;
    
    double start_ts = 0; // Start ts of the data to be loaded
    double end_ts = 9999999999;   // End ts of the data to be loaded
    double first_ts = 0; // First ts of the file.
    double second_ts = 0; // First ts of the file.
    double block_interval_ts;
    
    BLOCK_TYPE blk_1,blk_2; /* The data from one block in the CR file */
    int i,j,target_block, sample_count = 0,file_count=0;  /* counters */
    int got_data = 0;
    int n_r,n_c,n_samples_to_get;
    double window_size_msec = 3.0; //
    int interpolation_method = 1;  // 1 = AVERAGE, 2 = linear.
    double usec_per_point;
    short window_data[1024];
    double window_ts[1024];
    double li = 0;
    
    /* check number of arguments: expects 1 input */
    if (nINP != 2){
        mexErrMsgTxt("2 input values and 1 outputs: [D] = Read_nlx_CR_files (file_names_cell_array, times_to_get) ");
    }
    //////////////////////////
    // read inputs
    //////////////////////////

    file_list_ptr	 = pINP[0];
    if (!mxIsCell(pINP[0]))
        mexErrMsgTxt("Files must be passed in as a CELL ARRAY of filenames.");

    n_files			 = mxGetNumberOfElements(file_list_ptr);
    x  		         = mxGetPr(pINP[1]); // The timestamps. This must be a vector and it must be ascending.
    n_r		         = mxGetM(pINP[1]);
    n_c		         = mxGetN(pINP[1]); // If it is 1, then just return the data for these timestamps.
//    mexPrintf("r%d c%d n_files%d\n",n_r,n_c,n_files);
    if (n_r == 0)
        n_r = 1;
    if (n_c == 0)
        n_c = 1;

    n_samples_to_get = n_r * n_c;
    if (n_samples_to_get < 1)
        mexErrMsgTxt("Read_nlx_CR_file.c: NO timestmaps! Something is wrong.");

    //window_size_msec = mxGetScalar(pINP[2]);
    // Calloc some space for the data
    pOUT[0] = mxCreateDoubleMatrix(n_samples_to_get, n_files, mxREAL);
    y	    = mxGetPr(pOUT[0]); // The output.

    //////////////////////////////////////////////////////////////////////////////////////////////////
    /* Open each file in succession (perhaps faster if in parallel, I don't know) and fit the timestamps */
    //////////////////////////////////////////////////////////////////////////////////////////////////
    for (file_count = 0;file_count<n_files;file_count++)
    {
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

        
        fp = get_file_info(fn, &start_pos, &end_pos, &nRecords, &start_ts, &end_ts, &block_interval_ts, &usec_per_point, &new_NT_format, &bigendianFlag);
        
        if (x[n_samples_to_get-1] > (end_ts + block_interval_ts)){
            mexPrintf("Timestamps exceeded the size of the file, TRUNCATING\n");
            i = n_samples_to_get-1;
            while(x[i]>(end_ts + block_interval_ts) && i>0)
                i--;
            n_samples_to_get = i+1;
        }

        if (x[0] < start_ts){
            mexPrintf("Timestamps: start_ts %d and x[0] %d.\n",start_ts, x[0]);
            mexErrMsgTxt("Timestamps start before the start of the CSC file.\n");
        }       
       // if (window_size_msec*1e3<=usec_per_point){
        //    mexPrintf("WARNING: The chosen window size is less than the interval between samples.\n");
        //    window_size_msec = 3*usec_per_point*1e3;
        //}
        //float pts = window_size_msec*1e3/usec_per_point;
        // Intermittently I get this problem where the end timestamp of the range is incorrect.
//        mexPrintf("start %f x%f end %f x%f samples %d",start_ts,x[0],end_ts,x[n_samples_to_get-1],n_samples_to_get);
        //mexPrintf("block interval %f nRecords %d \n",block_interval_ts, nRecords);
        //////////////////////////////////////////////////////////////////////////////////////////////////
        // allocate some space for the window.
        //////////////////////////////////////////////////////////////////////////////////////////////////
        fseek(fp, start_pos, SEEK_SET);
        sample_count = 0;
        while ( sample_count < n_samples_to_get )
        {
            //////////////////////////////////////////////////////////////////////////////////////////////////
            // estimate the location in the file given the start and end times and the block size. jump there
            // make sure that you move back far enough to account for the averaging window.
            //////////////////////////////////////////////////////////////////////////////////////////////////
            target_block = (int) floor((x[sample_count] - start_ts - 30*usec_per_point)/block_interval_ts);
            fseek(fp, start_pos, SEEK_SET); // Start at the beginnnig (do i need to do this each time??? - yes as this is the only true reference point - you cannot use SEEK_SET as this is not the beginning of the data.)
            fseek(fp, target_block*NEW_CR_RECSIZE, SEEK_CUR);
            got_data = get_data(fp, bigendianFlag, &blk_1, new_NT_format);
//            mexPrintf("1\n");

            //////////////////////////////////////////////////////////////////////////////////////////////////
            // Check if this is the right place. If it's too far forward, keep jumping back until you find the
            // right spot.
            //////////////////////////////////////////////////////////////////////////////////////////////////
            // Move back
            //mexPrintf("%f %f tgt %d\n",x[sample_count],blk_1.TimeStamp, target_block);\
            // The 30 is to force the search to end up on a record that has a couple of datapoints at the
            // beginning in order to facilitate interpolation.
            while (blk_1.TimeStamp > (x[sample_count] - 30*usec_per_point) && ftell(fp) > start_pos){
                fseek(fp, -2*NEW_CR_RECSIZE, SEEK_CUR); // You need to move back 2 as get_data will move ahead.
                //mexPrintf("<");
                got_data = get_data(fp, bigendianFlag, &blk_1, new_NT_format);
            }
            
//            mexPrintf("2\n");
            if (ftell(fp) == start_pos){
                mexErrMsgTxt("TIMESTAMPS ARE NOT IN THE RANGE OF THE DATA! REACHED START OF FILE.\n");
                //x[sample_count] =  blk_1.TimeStamp; // fall out of the loop. Probably will crash.
            }
            
            // move forward if necessary.
//            mexPrintf("(%10.0f) tgt %d\n", blk_1.TimeStamp,target_block);
            while (blk_1.TimeStamp < (x[sample_count] - 30*usec_per_point) && ftell(fp) <= 0){
                //fseek(fp, NEW_CR_RECSIZE, SEEK_CUR); // don't need to do this as get_data moves ahead one automatically.
                mexPrintf(">");
                got_data = get_data(fp, bigendianFlag, &blk_1, new_NT_format);
            }
//            mexPrintf("3\n");

            fseek(fp, -1*NEW_CR_RECSIZE, SEEK_CUR);
            if (ftell(fp) >= (end_pos - NEW_CR_RECSIZE))
            {
                // backup to at least two blocks before the last record.
                fseek(fp, -1*NEW_CR_RECSIZE, SEEK_CUR);
                mexErrMsgTxt("WARNING: REACHED END OF FILE - the timestamps may not match the timestamps in the EEG data.\n");
                //x[sample_count] =  blk_1.TimeStamp; // fall out of the loop. Probably will crash.
            }

            //mexPrintf("Reached %10.0f \n",blk_1.TimeStamp);
            //mexPrintf("4\n");

            //////////////////////////////////////////////////////////////////////////////////////////////////
            // Get the data.
            //////////////////////////////////////////////////////////////////////////////////////////////////
            got_data = get_data(fp, bigendianFlag, &blk_1, new_NT_format);
            got_data = get_data(fp, bigendianFlag, &blk_2, new_NT_format);
            //////////////////////////////////////////////////////////////////////////////////////////////////
            // fill the window with the data and timestamps.
            //////////////////////////////////////////////////////////////////////////////////////////////////
            for (i=0;i<512;i++){
                window_data[i] = blk_1.Data[i];
                window_ts[i] =  blk_1.TimeStamp + floor((double)i*usec_per_point);
                window_data[i+512] = blk_2.Data[i];
                window_ts[i+512] =  blk_2.TimeStamp + floor((double)i*usec_per_point);
                //mexPrintf("%d %f data %d\n",i,window_ts[i],window_data[i]);
            }
            //mexPrintf("window start %f end %f \n",window_ts[0],window_ts[1023]);
 //           mexPrintf("4.1\n");
            
            j = 1; // to track the block count - in some bad records, the timestamp of the next block is missing or
            // corrupted so have a counter to make sure that we don't get stuck in the while loop that follows.
            //////////////////////////////////////////////////////////////////////////////////////////////////
            // Find the closest n points in the block to the data and then take a window around it.
            // NOTE!! An intermittent CRASH happens between this point and then end of the loop for 
            // reasons that I do not understand. I THINK I FIXED IT- The x[sample_count] in the while statement was
            // going over the limit. I added an if statement and break at the end of th ell
            //////////////////////////////////////////////////////////////////////////////////////////////////
            while ( x[sample_count] < window_ts[1023] & j <= 1023 ){
                // The following binsearch is where it dies.
                //mexPrintf("4.2 x[sample_count] %f sample_count %d n_samples_to_get %d \n", x[sample_count],sample_count,n_samples_to_get);
                i = binsearch(1024, window_ts, &x[sample_count]); // this could be made more efficient.
                //this is the floor so this is the record BEFORE the target record.
                
                // For now, just return this point. We'll deal with interpolation and means later.
                // POINT does work. It is just quite sensitive to the number of points in the interpolation.
                // It does not act as a smoothing factor if you add more points.
                //if (i > 7)
                //    polint(&window_ts[i-6], &window_data[i-6], 7, x[sample_count], &po_out, &po_error);
                //else
                //    mexPrintf("ERROR-- should not have reached this point %d \n",window_ts[i]);
                
                //mexPrintf("4.2222\n");
                if (i >= 0)
                    li = (double) window_data[i] + (x[sample_count] - window_ts[i])/(window_ts[i+1] - window_ts[i]) * (double)(window_data[i+1] - window_data[i]);
                else
                    mexPrintf("ERROR-- should not have reached this point %d %10.0f. Using the previous value.\n Make sure timestamps are in ASCENDING order.",i,window_ts[i]);
                    
                //*(y + sample_count + n_samples_to_get * file_count) = window_data[i];
                //*(y + sample_count + n_samples_to_get * file_count) = po_out;
                //mexPrintf("4.3\n");
                *(y + sample_count + n_samples_to_get * file_count) = li;
                // Perform standard linear interpolation given the point in front and the point behind.
                //mexPrintf("%d %d ts %10.0f   data %d po %f li %f\n",sample_count,i,x[sample_count], window_data[i],po_out,li);
                sample_count++;
                j++;
                // The following line is critical to prevent array overruns.
                if (sample_count == n_samples_to_get)
                    break;
            }
//            mexPrintf("5\n");

        }// Sample count
        /////////////////////////////////////////////////////////////////////////////////////////////////
        fclose(fp);
    }// FILE
    //mexPrintf("\n");

    mxFree(fn);
    // Option: If the user wants to re-reference the data, they may do it here.
}
