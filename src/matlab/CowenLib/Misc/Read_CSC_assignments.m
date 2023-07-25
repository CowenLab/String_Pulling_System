function CSC = read_csc_assignments(fname)
% PC read CSC assignments
if nargin ==0
    fname = 'CSC_reviewed_assignments.txt';
end
[d csc_files]= textread(fname,'%s%s','commentstyle','matlab','delimiter','\t')
for iRow = 1:length(d)   
   textscan(csc_files{iRow},'%s','delimiter',',')
end