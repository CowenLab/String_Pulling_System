function POS = position_from_plx(fname)
% loads position data from a plexon .DVT file
% cowen 2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fp = fopen(fname,'r');
TMP = textscan(fp,'%n%n%n%n%n%n','delimiter',',');
fclose(fp)

switch length(TMP)
    case 4
        POS = [TMP{2} TMP{3} TMP{4} ];
        
    case 6
        POS = [TMP{2} TMP{3} TMP{4} TMP{5} TMP{6}];
end
