/*-----------------------------------
* Load a text matrix. The main purpose of this routine is to load in data from files as
* they are being written. This requires that partially written lines are ignored. To
* my knowledge, you can't do this in matlab -- other than by reading line by line 
* in a loop which is painfully slow. Thus this program
* MEX file.
* INPUT:

* input: 1: the file name
* input: 2 (optional): If positive, the number of lines from the head of the file to read in (number of rows in the matrix)
*          If negative, the number of lines from the end of the file. 
* input: 3 If 3 inputs are passed, the 2nd is considered to be the start row and the third is the end row.
* 
  OUTPUT:
   the matrix, formed from the text file for the region specified.


*  PROBLEMS: 1) any trailing spaces on the first row will screw things up.
             2) Does not dynamically allocate memory for file positions so it will bomb for large files.
			 x3) providing negative rows to load larger than the file size will return a matrix of 0s(FIXED I THINK)
			 x4) Returns one more column than is in the file. (FIXED I THINK)
* cowen 2002      
* negatives do not work!
*  fixed column problem 7/2003     
-----------------------------------*/

#include "mex.h"
#include <math.h>
#include <matrix.h>
#include <string.h>

#define	MAX_LINE   20000	/* max characters per line */
#define	MAX_COLS   5000	    /* max cols per line */

//___________________________________________________________________________________

int get_row_vector(char *the_string, double *the_vector, int max_cols)
{
	///////////////////////////////////////////////////////////////////////////
	// the string containing the vector. WARNING: IT WILL BE MODIFIED!!!! NULLS ADDED
	// the_vector - pointer to space that will be filled with the output vector
	// max_cols - max allowable cols in this vector.
	// return - number of columns found in vector
	///////////////////////////////////////////////////////////////////////////
	char* delims = { " ,\n\r\t" };
	char *ptr_to_str;
	int col_count;
	col_count = 0;
	
    
    ptr_to_str         		= strtok( the_string, delims );
    the_vector[col_count] 	= atof(ptr_to_str);
    col_count++;
    ptr_to_str         		= strtok( NULL, delims );

   	while( ptr_to_str != NULL ) 
   	{
      	  the_vector[col_count] = atof(ptr_to_str);
		  col_count++;
	      ptr_to_str = strtok( NULL, delims );
    }
	return (col_count);
}
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
void mexFunction(
				 int nOUT, mxArray *pOUT[],
				 int nINP, const mxArray *pINP[])
{
	double n_rows_to_read = 0;
	unsigned long int start_row;
	unsigned long int end_row;
	unsigned long int current_row, current_col,n_rows, n_output_rows;
	char *filename;
	char buf[MAX_LINE];	/* line buffer */
	double line_vec[MAX_COLS];
	double min_val = 0, max_val = 0;
	double  *pr_to_M;
	int i,n_cols,proper_n_cols,fnlen, sort_col=0, row_count = 0;
	int errorstatus;
	long int *file_pos;
	long int start_file_pos;
	double nan;
	FILE *fp;
	/*********************************************************/
	/* check number of arguments: expects 2 inputs, 1 output */
	/*********************************************************/
	if (nOUT != 1)
		mexErrMsgTxt("Requires one output.");
	
	/*******************/
	/*  unpack inputs  */
	/*******************/	
	fnlen = (mxGetM(pINP[0]) * mxGetN(pINP[0])) + 1;
	filename = (char *) mxCalloc(fnlen, sizeof(char)); 
	if (!filename)
		mexErrMsgTxt("Not enough heap space to hold converted string.");
	errorstatus = mxGetString(pINP[0], filename,fnlen);    
	if (errorstatus)
		mexErrMsgTxt("Could not convert string data.");
	////////////////////////////////////////////////////////////////


	/*******************/
	/*  open the file  */
	/*******************/
	fp = fopen(filename, "r");
	if (!fp)
		mexErrMsgTxt("ERROR: Could not open file.");
	/*******************
	*  Read the first line
	*  in order to get the 
	*  number of columns 
	*  Ignore comments.
	/*******************/
	do{
		/* get first word from line */
		start_file_pos = ftell(fp);
		if (fgets(buf, sizeof(buf), fp) == NULL)
			mexPrintf("Error reading line.\n");
	}while (buf[0] == '%' || buf[0] == '/' || buf[0] == '#' || buf[0] == '\'');

	///////////////////////////////////////////
	// Determine the number of columns in the file.
	//  If the file is being written as we read, the last row could have a different
	//  number. That is why I do this.
	///////////////////////////////////////////
	proper_n_cols = get_row_vector(buf, line_vec, MAX_COLS);
	
	/*******************/
	/*  Get the pointers to the beginning of EVERY LINE. */
	/*  Also get the values of the sort col */
	/*******************/
	///////////////////////////////////////////
	// Pass 1. Count the number of lines.
	///////////////////////////////////////////
	n_rows = 0;
	do	{	
		n_rows++;	
	}while (fgets(buf, sizeof(buf), fp) != NULL );
	///////////////////////////////////////////
	// Allocate memory for the pointer and the sort column if need be.
	///////////////////////////////////////////
	mexPrintf("Finished first pass.\n" );

	////////////////////////////////////////////////////////////////
	// Now that we know how many rows exist, we can parse the input.
	////////////////////////////////////////////////////////////////
	if (nINP == 1) // Just a filename
	{
		end_row = n_rows;
		start_row = 1;
		n_rows_to_read = n_rows;
	}
	else if (nINP == 2) // A filename and a number specifying the number of lines from the top (pos) or the bottom (neg)
	{
		n_rows_to_read = mxGetScalar(pINP[1]);
		/*******************/
		// Determine where to begin saving lines.
		/*******************/

		if (n_rows_to_read > 0){ // if greater than 0, start at the top.
			start_row = 1;
			end_row = n_rows_to_read;
		}else{
			end_row = n_rows;
			start_row = end_row - abs(n_rows_to_read) + 1; 
			if (start_row < 1){
				start_row = 1;
				mexPrintf("More rows specified than exist in the file. Truncating to first line.\n");
			}
		}
	}
	else if (nINP == 3) // A filename and 2 numbers -- the first for the top and the second for the bottom of the range to read.
	{
		start_row = mxGetScalar(pINP[1]);
		end_row = mxGetScalar(pINP[2]);
		if (end_row > n_rows)
		{
			end_row = n_rows;
			mexPrintf("More rows specified than exist in the file. Truncating to last line.\n");
		}

		n_rows_to_read = end_row - start_row + 1;
		if (start_row > end_row)
			mexErrMsgTxt("Must enter start and then end row as paramters 2 and 3.");
	}
	else if (nINP == 4) // User specifies filename, a column from which to filter on (starting with 1), a minimum limit and a maximum limit. Only rows which fall wi those criteria are returned.
	{
		sort_col = mxGetScalar(pINP[1]);
		min_val  = mxGetScalar(pINP[2]);
		max_val  = mxGetScalar(pINP[3]);
		end_row  = n_rows;
		start_row = 1;
		n_rows_to_read = n_rows;
	}
	else
		mexErrMsgTxt("Call with 1, 2 or 3 paramters.");

	///////////////////////////////////////////
	// make	sure more rows than exist are not specified.
	//  If so, truncate to the existing n_rows
	///////////////////////////////////////////

	file_pos = (long int *)mxCalloc(n_rows, sizeof(long int));

	if( file_pos == NULL )
		mexPrintf("Can't allocate memory\n" );

	// The number of rows to be sent back to matlab in pOUT.
	n_output_rows = end_row - start_row + 1; // Should be the same as n_rows_to_read.
	mexPrintf("n_rows %i start_row %i end_row %i ncols %i n_output_rows %i.\n",n_rows,start_row,end_row,proper_n_cols,n_output_rows );
	
	if(sort_col <=0){
		pOUT[0] = mxCreateDoubleMatrix(n_output_rows, proper_n_cols, mxREAL);
		if (!pOUT[0]) 
			mexErrMsgTxt("Cannot create output array. Probably out of memory.");	
		pr_to_M = (double *) mxGetPr(pOUT[0]);
	}
	
	/*******************/
	/*  Jump to the first line of the block to read */
	/*******************/

	fseek(fp,start_file_pos,SEEK_SET);
	//fseek(fp,file_pos[start_row-1],SEEK_SET);
	row_count = 1;
	current_row = 1;
	nan=mxGetNaN();
    ///////////////////////////////////////////////////
	
	while (fgets(buf, sizeof(buf), fp) != NULL && current_row <= end_row )
	{
		if (row_count >= start_row)
		{
			n_cols = get_row_vector(buf, line_vec, MAX_COLS);
			if (n_cols != proper_n_cols)
			{
				mexPrintf("Improper number of columns at row: %li / %li start row %li end row %li. Row has been nand.\n", current_row, n_rows ,start_row, end_row);
				// Assign all elements in this row to nan.
				for (current_col = 1; current_col <= proper_n_cols; current_col++)	{
					pr_to_M[ (current_col-1) * n_output_rows + (current_row - start_row )]  = nan;
				}
				current_row++;	
			}else{
				// Put the vector in the matlab matrix.
				if(sort_col <= 0){
					for (current_col = 1; current_col <= proper_n_cols; current_col++)
						pr_to_M[ (current_col-1) * n_output_rows + (current_row - start_row )]  = line_vec[current_col-1];
					current_row++;	
				}else{
					// NOTE: If you have Int 64s you may miss the first and last item in the range
					// due to the loss of precision.
					if (line_vec[sort_col-1] >= min_val && line_vec[sort_col-1] <= max_val){
						file_pos[current_row-1] = ftell(fp);
						current_row++;	
					}
				}
			}
		}
		row_count++;
	}
	current_row--; // decrease by one so it reflects the total number of rows to send to matlab.
	// 
	// 
	// 
	if(sort_col > 0){
		// sorted on a passed in restriction.
		pOUT[0] = mxCreateDoubleMatrix(current_row, proper_n_cols, mxREAL);
		if (!pOUT[0]) 
			mexErrMsgTxt("Cannot create output array. Probably out of memory.");	
		pr_to_M = (double *) mxGetPr(pOUT[0]);

		for (i=0;i<current_row;i++){
			fseek(fp,file_pos[i],SEEK_SET);
			fgets(buf, sizeof(buf), fp);
			n_cols = get_row_vector(buf, line_vec, MAX_COLS);
			for (current_col = 1; current_col <= proper_n_cols; current_col++)
				pr_to_M[ (current_col-1) * current_row + (i + 1 - start_row )]  = line_vec[current_col-1];
		}
	}
	mxFree(filename);
	mxFree(file_pos);
}
