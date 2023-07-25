              Description of operation of script Vector_Stats

Operation of Vector_Stats is the same as for any other MATLAB script.  

Start MATLAB as usual, and set the Current Directory to that in which the 33
scripts and functions (copied from the IAMG website) of Vector_Stats are
located.  The MATLAB-supplied functions and the MATLAB Toolbox also must
be accessible for execution.  

Transformations or operations on the data may be required (e.g., convert from
time to angles; convert azimuths from the range [-180, 180] to [0, 360]).  If so,
read the data file and perform the required operations with standard MATLAB
commands. 

Start the script by typing Vector_Stats on the command line in the Command
Window; then press Enter.  The following sequence of windows allows setting
controls for operating the script.  The script checks for errors and omissions in
filling out the window entries.  If an error is detected, a message will appear in
the Command Window and the GUI window will remain on the screen.     

1.  A window appears that 
A) allows entering a brief description of the job or data being analyzed.  This is
printed with calculations and generated figures.
B) allows the user to specify if the data to be analyzed are to be read from an
External File, or if they are already in MATLAB as a Data Array.

2.  If an External File was specified above (1.B), then a standard window opens
that allows the user to specify the name of the text file.  See below for
information on the data file.

3a.  If an External File was specified in 1.B, then a window opens that requests
information about the file.  This contains entries as follows:
A) Number of header records in the file to skip (0, 1, 2, ...).
B) Number of columns in the data set; one of these will contain the azimuths to
be analyzed.
C) Number of the column that contains the individual azimuths (if the data are
not grouped) or the azimuth class midpoints (if the data are grouped). 
D) Number of the column that contains the class frequencies if the data are
grouped. Leave this field as 0 if data are not grouped.  
E) Specify if input azimuths are in degrees or radians.
F) Specify if the calculations are to be written to an output text file.  All
calculations also appear in the Command Window, but this file allows permanent
storage of the results.

3b.  If a Data Array was specified in 1.B, then a window opens that requests
information about the array.  This contains entries as follows:
A) Name of the MATLAB data array that contains the azimuth data.  The default
name is AzData.  If Vector_Stats read an External File when previously
executed, that data will be left in array AzData.
B) Number of the column that contains the individual azimuths (if the data are
not grouped) or the azimuth class midpoints (if the data are grouped). 
C) Number of the column that contains the class frequencies if the data are
grouped. Leave this field as 0 if data are not grouped.  
D) Specify if input azimuths are in degrees or radians.
E) Specify if the calculations are to be written to an output text file.  All
calculations also appear in the Command Window, but this file allows permanent
storage of the results.

4.  If calculations are to be written to the optional output file (3a.F or 3b.E), a
window opens that requests the name of the file to be written.  The file should be
of type .txt.

5.  A window opens to specify the calculations that are desired.  The calculations
are described in the accompanying paper.  Basic statistics on the data are
calculated automatically.  Other choices are requested by "clicking" on the radio
buttons described in A - F and J.
A) Are plots (rose diagram, compass plot, and Q-Q plots) to be generated?
B) Are tests for the uniform distribution to be conducted?
C) Are tests for the von Mises distribution to be conducted?
D) Is inference (tests of hypothesis, confidence intervals) concerning the vector
mean to be conducted, assuming the concentration parameter is known?
E) Is inference (tests of hypothesis, confidence intervals) concerning the vector
mean to be conducted, assuming the concentration parameter is unknown?
F) Are confidence intervals to be generated on the concentration parameter?
G) Enter the level of significance, alfa, to be used for the tests of hypothesis. 
Certain tests are tabled only for alfa equal to 0.10, 0.05, 0.025, and 0.01 for small
sample sizes.  For larger sample sizes, other tests, and confidence intervals, any
value of alfa may be used.  If a value for alfa is entered that is not one of the four
values above, alfa will be modified to the closest of the four.
H) The assumed-known value of the vector mean, or the hypothesized value of
the vector mean, depending on the calculations that are being made (degrees).       
I) The assumed-known value of the concentration parameter (used for certain
tests on the vector mean). 
J) Are the components of a mixture of two von Mises distributions to be
separated?

6. If rose diagrams are to be generated (5.A), a window opens that requests
information on the plot.
A) Number of classes (spread over 360 degrees) in rose; must be in range 4-36.
B) Origin (azimuth angle of an edge of any class) for the rose.
C) Specify if diagram is to plot frequencies or square-root of frequencies.

7.  If the components of a mixture of two von Mises distributions are to be
separated (5.J), a window opens that requests information for iterating a solution
to the equations.
A) Initial estimate of the vector mean (degrees) for component 1.
B) Concentration parameter for component 1.
C) Initial estimate of the vector mean (degrees) for component 2.
D) Concentration parameter for component 2.  
E) Proportion (fraction) of azimuths in the sample from component 1.  
F) Maximum number of iterations.  Unless the initial estimates are very poor or
the distribution is far from a simple mixture of separate components,
convergence typically occurs in fewer than 50 iterations.
G) Tolerance on the estimated values to stop iterating.

The script then performs the calculations and generates the plots and output text
file if requested.

Resampling (bootstrap) methods are used for small sample sizes.  The number of 
bootstrap iterations (NB) is specified in a line in the first part of the driver 
script Vector_Stats.m.  It is set to NB = 200; its value may be increased, but for 
accuracy should not be decreased

                           Error return codes

The script returns error codes to the Command Window if problems develop
while filling out the GUI or during execution.

0 = execution OK
1 = the requested data set could not be found or could not be opened
2 = an incorrect value was given for the number of columns (2.B) in the data set,
or a partial row exists in the data set; file could not be read   
3 = the external output file could not be opened
7 = no name specified for output file, although it had been requested
8 = job was cancelled by user while inputting data-set controls
9 = job was cancelled by user while inputting calculations to be made
10 = job was cancelled by user while inputting initial estimates and controls for
separating two components of mixture
15 = sample size N is too small for valid test of hypothesis or confidence interval
to be made
21 = no convergence was reached in separation of two components of mixture


                         Format of input data set         

The data set read by Vector_Stats consists of (1) header records and (2) an array
of numbers arranged in rows and columns, one column of which contains the
azimuths of interest.  

The file begins with header records; any number are allowed, including 0. 
During operation of the GUI, the user specifies the number of records to be
skipped.   

Following the headers are the data records, each representing an observed
azimuth or class interval of grouped azimuths.  These are the rows in the data
array.  Each record contains one or more columns.  These columns contain the
several variables that are associated with each observation.  These rows and
columns thus make up the data array processed by MATLAB.  

With the exception of the header records, NO CHARACTER OR STRING VARIABLES MAY BE
IN THE FILE.  If such variables are in the data set, read the file separately into
MATLAB and pick up the resulting array for analysis.

The script typically reads individual data values.  However, it may also read
grouped data.  In such cases, the azimuth values represent the midpoints of
azimuth classes in one column, and a second column in the data set contains the
class frequencies that are associated with the azimuth class midpoints.  

The script may also process a data array that already is in MATLAB's memory. 
If so, the user simply specifies the name of that array, and indicates which
column is to be used for analysis.  If the Vector_Stats script is used to read a
text file, the data array that is input will be left unchanged in MATLAB memory,
under the name AzData, after execution.       
