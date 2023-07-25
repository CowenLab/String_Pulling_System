function tline = Load_file(fname)
% Reads a text file into matlab
fid = fopen(fname)
count = 1;
while 1
    tmp = fgetl(fid);
    if ~ischar(tmp), break, end
    tline{count} = tmp;
    %disp(tline{count})
    count = count + 1;
end
fclose(fid);
