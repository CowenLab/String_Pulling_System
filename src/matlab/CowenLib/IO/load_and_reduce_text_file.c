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
#define	MAX_ROWS   200000    /* max rows */

//int get_row_vector(char *the_string, double *the_vector, int max_cols, int *found_cols);
//___________________________________________________________________________________

int get_row_vector(char *the_string, double *the_vector, int max_cols)
{
	///////////////////////////////////////////////////////////////////////////
	// the string containing the vector. WARNING: IT WILL BE MODIFIED!!!! NULLS ADDED
	// the_vector - pointer to space that will be filled with the output vector
	// max_cols - max allowable cols in this vector.
	// return - number of columns found in vector
	///////////////////////////////////////////////////////////////////////////
	char* delims = { " ,\n\r" };
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
	double n_lines;
	unsigned long int start_row;
	unsigned long int end_row;
	unsigned long int current_row, current_col, row_count,n_rows, n_output_rows;
	char *filename, *getlineout, *prev_ptr_to_str, *ptr_to_str;
	char buf[MAX_LINE];	/* line buffer */
	double line_vec[MAX_COLS];
	char a_char;
	double *result, *pr_to_M;
	int i, j,n_cols,proper_n_cols,fnlen;
	int errorstatus;
	char* delims = { " ," };
	long int file_pos[MAX_ROWS];
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
	


	if (nINP == 1)
	{
		end_row = MAX_ROWS;
		start_row = 1;
	}
	else if (nINP == 2)
	{
		n_lines = mxGetScalar(pINP[1]);
		/*******************/
		// Determine where to begin saving lines.
		/*******************/
		if (n_lines > 0) // if greater than 0, start at the top.
		{
			start_row = 1;
			end_row = n_lines;
		}else
		{
			end_row = MAX_ROWS;
			start_row = end_row + n_lines + 1; // remember, n_lines is negative so this is a subtraction.
		}
		
	
	}
	else if (nINP == 3)
	{
		start_row = mxGetScalar(pINP[1]);
		end_row = mxGetScalar(pINP[2]);
	}
	else
		mexErrMsgTxt("Call with 1, 2 or 3 paramters.");

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
	/*******************/
	buf[0] = '%';
	while (buf[0] == '%') {
		/* get first word from line */

		file_pos[0] = ftell(fp);

		if (fgets(buf, sizeof(buf), fp) == NULL)
			mexPrintf("Error reading line.\n");
	}
	
	/*******************/
	/*  Get the pointers to the beginning of EVERY line. */
	/*******************/
	//file_pos[i] = (long int) mxMalloc(sizeof(long int));
	//file_pos[0] = ftell(fp);
	i = 1;
	do	{	
		// too hard, pre-allocating memory. 
		// file_pos = (long int *) mxRealloc(line_fps, sizeof(long int) * i+1);
		//if (new_line_fps == NULL)
		//	{
		//	fprintf(stderr,"COULD NOT ALLOCATE MEMORY FOR FILE POINTERS\n");
		//	return(-1);
		//	}
		file_pos[i] = ftell(fp);
		i++;	

	}while (fgets(buf, sizeof(buf), fp) != NULL );
	
	n_rows = i - 1 ; // ?????? I don't understand this.

	if (n_lines < 0) // if greater than 0, start at the top.
	{
	    end_row = n_rows; 
	    start_row = end_row + n_lines + 1; // remember, n_lines is negative so this is a subtraction.
        }	

	if (end_row >= MAX_ROWS)
		end_row = n_rows;
	// make sure more lines than exist are not specified.
	if (end_row-start_row > abs(n_lines))	{
		start_row = 1;
		end_row = n_rows-1;
	}

	/*******************/
	/*  Jump to the first line */
	/*******************/
	fseek(fp,file_pos[0],SEEK_SET);
	/*******************/
	/*  Get a line to determine the number of cols. */
	/*******************/
	if (fgets(buf, sizeof(buf), fp) != NULL )
	{
		proper_n_cols = get_row_vector(buf, line_vec, MAX_COLS);
	}
	else
	{
		mexErrMsgTxt("Could not go to the previous pointer.");
	}
		
	/*******************/
	/* Now that we know the n cols, we 
	   know how much memory to allocate. */
	/*******************/
	
	n_output_rows = end_row - start_row + 1;
	if (n_output_rows > MAX_ROWS)
	{
		mexErrMsgTxt("Too many requested lines. ");
		return -1;
	}
	
	pOUT[0] = mxCreateDoubleMatrix(n_output_rows, proper_n_cols, mxREAL);
	if (!pOUT[0]) 
		mexErrMsgTxt("Cannot create output array. Probably out of memory.");	
	pr_to_M = (double *) mxGetPr(pOUT[0]);
	double *running_count = (double *)malloc(proper_n_cols,  * sizeof(double));
	/*******************/
	/*  Jump to the first line of the block to read */
	/*******************/

	fseek(fp,file_pos[start_row-1],SEEK_SET);
	current_row = start_row;
	nan=mxGetNaN();
	//mexPrintf("Columns at row: %li / %li start row %li end row %li. Row has been nand.\n", current_row, n_rows ,start_row, end_row);

    ///////////////////////////////////////////////////
	while (fgets(buf, sizeof(buf), fp) != NULL && current_row <= end_row )
	{
		n_cols = get_row_vector(buf, line_vec, MAX_COLS);

		if (n_cols != proper_n_cols)
		{
			mexPrintf("Improper number of columns at row: %li / %li start row %li end row %li. Row has been nand.\n", current_row, n_rows ,start_row, end_row);
			// Assign all elements in this row to nan.
			for (current_col = 1; current_col <= proper_n_cols; current_col++)
			{
				pr_to_M[ (current_col-1) * n_output_rows + (current_row - start_row )]  = nan;
			}
			
		}else
		{
			// Put the vector in the matlab matrix.
			for (current_col = 1; current_col <= proper_n_cols; current_col++)
		}
		
		for (current_col = 1; current_col <= proper_n_cols; current_col++)
			pr_to_M[ (current_col-1) * n_output_rows + (current_row - start_row )]  = line_vec[current_col-1];
		current_row++;	
	}

	
}
