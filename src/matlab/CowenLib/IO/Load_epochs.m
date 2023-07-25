function [EPOCH_TIMES_10thsms,L] = Load_epochs(epoch_file_name)
% Reads the epochs.ascii file.
% cowen 2013
fp = fopen(epoch_file_name,'r');
L = textscan(fp,'%s %s\n');
fclose(fp)

EPOCH_TIMES_10thsms = zeros(length(L{1}),2);
for ii = 1:length(L{1})
    for jj = 1:2
        HMS_string = L{jj}{ii};
        ix = strfind(HMS_string,':');
        hrs = str2double(HMS_string(1:(ix(1)-1)));
        mins = str2double(HMS_string((ix(1)+1):(ix(2)-1)));
        secs = str2double(HMS_string((ix(2)+1):end));
        EPOCH_TIMES_10thsms(ii,jj) = Hms_to_timestamp(hrs,mins,secs);
    end
end
