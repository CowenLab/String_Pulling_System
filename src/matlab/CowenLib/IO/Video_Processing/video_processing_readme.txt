WHAT'S IN THIS DIRECTORY


PROCESS_VIDEO_LABVERSION.M

This is a function which streamlines the processing of a video
file from a VT.zip file to a finished position file (.PVD).  It uses
a circle-fitting algorithm, which matches the lights on the headstage. 
Note that this file will output a .pvd file, which is an ascii file with 
columns as follows: [Timestamp Xpos Ypos Velocity Direction]

IF YOU ARE A FIRST-TIME USER, YOU WILL PROBABLY WANT TO START WITH THIS FUNCTION.
NO OTHER CALLS ARE NECESSARY TO COMPLETELY PROCESS YOUR VIDEO DATA.


PROCESS_VIDEOWM.M

Same as process_video_labversion, but this tracks rat's position based on 
a simple weighted mean of all "on" pixels.  As in the labversion, there is still 
an exclusion radius, which starts at the rats last known location.  Pixels outside this
radius aren't considered in the fit.  Translates .zip files into .pvd.  


CUTVIDEO.EXE

cutvideo.exe is a c program with two purposes.  1) it restricts a video data file to only the 
requested timestamps 2) it converts the data to an ascii file.  Here's how to run the function:

cutvideo requires the following arguments:
   -inp <filename>
   -outp <filename>
   -start <timestamp(usec)>
   -end <timestamp>


UNZIP.EXE

unzip.exe is a command-line utility for extracting zip files.  



EXTRACTVIDPOS.M

this is the actual video extraction function, which operates on an 
existing ascii function.  Process_video calls this function, but you can 
also create your own ascii files and run this as a stand-alone function. 



FIND_LWC

Find local weighted center of the pixels.  A 2D gaussian is convolved over
the entire image and then the maximum is choosen.  I use this to localize the rat 
when nothing is known about its previous location (i.e., when starting tracking or
after he gets lost by the tracker)



FIT CIRCLE

This function takes as set of points and fits a circle to them.


DRAW_CIRCLE


this function is a simple utility that does just what it says