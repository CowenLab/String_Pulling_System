function [TBL, INFO]= DLC_read_DLC_csv_file(dlc_csv_file_path)
% Reads the .csv created by DLC as a Matlab table.
% INPUT: full path to the .csv file created by DLC
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
INFO.col_names = DLC_generate_col_names(dlc_csv_file_path);
TBL = readtable(dlc_csv_file_path,'HeaderLines',3);
TBL.Properties.VariableNames = INFO.col_names;
% from the above, identify the column pairs that have x and y.
INFO = DLC_extract_body_parts_and_coordinates_from_tbl(TBL.Properties.VariableNames);
