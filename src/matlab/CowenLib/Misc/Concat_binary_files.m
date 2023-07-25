function Concat_binary_files(first_file, second_file, dest_file)
% Concatenates the second file to the first.
% INPUT filenames for the first and second file and the name of the destination file. 
% OUTPUT destination file with all the recs from all of the source files concatenated
% cowen
eval(['!del ' dest_file])
copyfile(first_file, dest_file);
dest_fp = fopen(dest_file,'wb+');
if dest_fp
    % go to the end of the file
    fseek(dest_fp,0,'eof')
    second_fp = fopen(second_file,'rb');
    while ~feof(second_fp)
        a = fread(second_fp,1,'uint8=>uint8');
        fwrite(dest_fp, a,'uint8');
    end
    fclose(second_fp);
    fclose(dest_fp);
else
    error('Could not open file')
end
