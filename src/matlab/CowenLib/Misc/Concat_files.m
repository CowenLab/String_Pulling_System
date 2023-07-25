function Concat_files(source_wildcard, dest_file)
% Concatenates all the files found with the wildcard into the dest_file.
% INPUT source file wildcard like '*.txt' and a destination file
% OUTPUT destination file with all the recs from all of the source files concatenated
% cowen
dos_method = 1;
if dos_method
   % cwd = pwd;
   % [ps,n,e] = fileparts(source_wildcard);
   % cd(ps)
   % spath = pwd;
   % [pd,n,e] = fileparts(dest_file);
   % cd(pd)
   % dpath = pwd;
   % 
   % [ps pd]
   eval(['!del ' dest_file])
   eval(['!type ' source_wildcard ' > ' dest_file]);
else
    % Matlab method
    
    f = find_files(source_wildcard);
    out_fp = fopen(dest_file,'w+');
    if out_fp
        for ii =1:length(f)
            in_fp = fopen(f{ii},'r');
            got_line = 1;
            L = fgets(in_fp);
            while(L(1) ~= -1)
                fprintf(out_fp,'%s',L);
                % fprintf(out_fp,'\n'); % if using fgets Don't need terminator because fgets returns the terminator.
                L = fgets(in_fp);
            end
            fclose(in_fp);
        end
        fclose(out_fp);
    else
        error('Could not open file')
    end
end