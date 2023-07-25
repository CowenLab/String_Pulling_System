function col_names = DLC_generate_col_names(csv_fname)
% Generates unique col names based on the 2nd and 3rd rows of the defauilt
% .csv file created by DLC.
% INPUT: full path to the .csv file created by DLC
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fp = fopen(csv_fname,'r');
fgetl(fp);
txt1 = fgetl(fp);
txt2 = fgetl(fp);
fclose(fp);
txt1 = split(txt1,',');
txt2 = split(txt2,',');
% Create variable names
col_names = [];
for iV = 1:length(txt1)
    col_names{iV} = [strrep(txt1{iV},' ','_') '_' strrep(txt2{iV},' ','_')];
end