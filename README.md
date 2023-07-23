# Pulling and Neural Data Analysis (PANDA) String Pulling System
Developed in the Cowen Laboratory.
See... [biorxiv](https://www.biorxiv.org/content/10.1101/2023.07.02.547431v1)

## Folders
* Hardware Manuals: Contains Manufacturer manuals of components. Currently it just has an entry for the Mako camera.
* src: Contains source code for analysis of hte string pulling data.
** rotary_encoder: Arduino code for controlling the rotary encoder and experiment control for the single-arduino system
** rotary_encoder_two: Arduino code for controlling the rotary encoder and experiment control for the dual-arduino system (in Supplementary Information)
** experiment_control: Arduino code for the experiment control Arduino that controls the feeder in addition to tracking pull distance.. This code can handle 2 encorders (e.g., if you had 2 strings)
** experiment_control_single_encoder: As above but for a single encoder (string).
* 3d_print_and_laser_cut_files: files for printing the camera mount and pully wheels
* String_Pull_Training: Notes and logs from training specific animals on the task.
* Instructions: Additional technical instructions for building the system and for setting up the camera.
* Original_instructions_from_Jordan_thesis: Legacy data from Gianna Jordan's Masters thesis on the string pulling system.
* Videos: videos of rats performing the task.
 
 
