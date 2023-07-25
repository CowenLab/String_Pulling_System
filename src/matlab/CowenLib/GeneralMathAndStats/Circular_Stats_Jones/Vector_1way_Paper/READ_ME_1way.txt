                       Description of operation of script Vector_1way

The description of this script and calculations that it makes are described in
the Computers & Geosciences paper:
MATLAB functions to analyze directional (azimuthal) data. III. q-sample inference.

Operation of Vector_1way is the same as for any other MATLAB script.  

Start MATLAB as usual, and set the Current Directory to that in which the 35 scripts 
and functions (copied from the IAMG website) of Vector_1way are located.  
The MATLAB-supplied functions and the MATLAB Toolbox also must be accessible for 
execution.  

Transformations or operations on the data may be required (e.g., convert from time 
to angles; convert azimuths from the range [-180, 180] to [0, 360]).  If so, read 
the data file and perform the required operations with standard MATLAB commands. 

Start the script by typing Vector_1way on the command line in the Command Window; 
then press Enter.  The following sequence of windows allows setting controls for 
operating the script.  The script checks for errors and omissions in filling out 
the window entries.  If an error is detected, a message will appear in the 
Command Window and the GUI window will remain on the screen.     

1.  A window appears that 
A) allows entering a brief title (description) of the job or data being analyzed.  
This is printed with calculations and on generated figures.
B) allows the user to specify if the data to be analyzed are to be read from an 
External File, or if they are already in MATLAB as a Data Array.

2.  If an External File was specified above (1.B), then a standard window opens 
that allows the user to specify the name and path of the text file.  See below for 
information on the data file.

3a.  If an External File was specified in 1.B, then a window opens that requests 
information about the file.  This contains entries as follows:
A) Number of header records in the file to skip (0, 1, 2, ...).
B) Number of columns in the data set; these contain the azimuths to be analyzed.
C) Specify if the azimuths are in terms of Degrees or Radians.
D) Specify if the data are set up as individual azimuths, or if one column is 
class-midpoint for the azimuths, and other columns are count-frequencies for each
of the classes.
E) Values used to indicate missing data, as when some sub-samples have fewer 
observations than others; values less than or equal to this are ignored; defaults 
to -99.
F) Specify if the calculations are to be written to an output text file.  All 
calculations also appear in the Command Window, but this file allows permanent 
storage of the results.

3b.  If a Data Array was specified in 1.B, then a window opens that requests 
information about the array.  This contains entries as follows:
A) Name of the MATLAB data array that contains the azimuth data.  The default name 
is AzData.  If Vector_1way read an External File when previously executed, that 
data will be left in array AzData.
B) none
C) Specify if the azimuths are in terms of Degrees or Radians.
D) Specify if the data are set up as individual azimuths, or if one column is 
class-midpoint for the azimuths, and other columns are count-frequencies for each
of the classes.
E) Values used to indicate missing data, as when some sub-samples have fewer 
observations than others; not used here.
F) Specify if the calculations are to be written to an output text file.  All 
calculations also appear in the Command Window, but this file allows permanent 
storage of the results.

4. If calculations are to be written to the optional output file (3a.F or 3b.F), a 
window opens that requests the name and path of the file to be written.  The file 
should be of type  .txt.

5a. If the data are specified as Individual Azimuths (3a.D or 3b.D), then this 
window requests information about which columns in the data set are to be used 
in the analysis.
A) none 
Following are 10 sets of two entries.  These consist of definitions of up to 10 
sub-samples that are to be compared.  
B) Alphabetic identifier of the sub-sample or group being analyzed (optional).
C) Number of the column that contains the sub-sample or group information, that is, 
the individual azimuths. 

5b. If the data are specified as Count Frequencies (3a.D or 3b.D), then this window 
requests information about which columns in the data set are to be used in the 
analysis.
A) Number of the column containing the azimuths of the class midpoints. 
Following are 10 sets of two entries.  These consist of definitions of up to 10 
sub-samples that are to be compared.  
B) Alphabetic identifier of the sub-sample or group being analyzed (optional).
C) Number of the column that contains the sub-sample or group information, that is, 
the frequencies (counts) of the data for this sub-sample. 

6. This window allows specification of which calculations are to be made.  If none 
of the following are specified, then only basic descriptive calculations for each 
sub-sample and the total sample are provided.
A) Specify if rose diagrams of the data, and a compass plot of the sub-sample 
vector-means, are to be made.
B) Specify if wish to test vector means for equality.
C) Specify if wish to calculate confidence intervals on differences of two vector 
means, for all pairs of sub-samples.
D) Specify if wish to test concentrations (kappas) for equality.
E) Specify if wish to perform all resampling calculations, even if the sample sizes 
and kappas are large and the standard tests are appropriate.
F) Enter the level of significance, alfa, to be used for the tests of hypothesis 
and confidence intervals.  Allowable range is 0.001 to 0.25.
G) Enter the number of resampling (bootstrap) trials that are to be used.  
Allowable range is 100 to 10,000.

7. If plots are requested (6.A), a window opens for instructions:
A) Number of classes used for the rose.  Default is 12 (30-degree classes).
B) Origin for the first class.  
C) Specify if wish to plot frequency (counts) or square-root of frequency.

The script then performs the calculations; it generates the plots and output text 
file, if requested.



                                Error return codes

The script returns error codes to the Command Window if problems develop while 
filling out the GUI or during execution.

0 = execution OK
1 = the requested data set could not be found or could not be opened
2 = an incorrect value was given for the number of columns (3a.B) in the data set; 
file could not be read; possibly caused by blank line at end of file   
3 = the external output file could not be opened
7 = no name specified for output file, although it had been requested
8 = job was cancelled by user while inputting data-set controls
15 = sample size N is too small for valid test of hypothesis or confidence interval 
to be made


                              Format of input data set    	

The data set read by Vector_1way consists of (1) header records and (2) an array of 
numbers arranged in rows and columns, at least two columns of which contain 
sub-samples for comparison.  

The file begins with header records; any number are allowed, including 0.  During 
operation of the GUI, the user specifies the number of records to be skipped.   

Following the headers are the data records, each representing one observation. 
These are the rows in the data array.  Each record contains two or more columns.  
These columns contain the several sub-samples (groups).  These rows and columns 
thus make up the data array processed by MATLAB.  

With the exception of the header records, no character or string variables may be 
in the file.  If such variables are in the data set, read the file separately 
into MATLAB and pick up the resulting array for analysis.

The script may also process a data array that already is in MATLAB’s memory.  
If so, the user simply specifies the name of that array, and indicates which 
columns are to be used for analysis.  If the Vector_Stats, Vector_Corr, or 
Vector_1way script is used to read a text file, the data array that is input will 
be left in MATLAB memory, under the name AzData, after execution.       
