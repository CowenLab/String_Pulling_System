function O = Wonambi_stages_to_csv(start_end_s, stageID, start_time_string, out_file)

%% for testing
% start_end_s = [0 30; 30 60; 60 90; 90 120];
% stageID = {'NREM' 'REM' 'NREM' 'WAKE'};
% start_time_string = '07:00:0.0';
% out_file = 'C:\Temp\out.csv';
    
d = ['2018-06-25 ' start_time_string];
t = datetime(d,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
fp = fopen(out_file,'w');
fprintf(fp,'Wonambi v7.11\n');
fprintf(fp,'clock start time,start,end,stage\n');
for iR = 1:Rows(start_end_s)
    tstr = datestr(datenum(t)+seconds(30*(iR-1)),'HH:MM:SS')
    fprintf(fp,'%s,%d,%d,%s\n',tstr,start_end_s(iR,1),start_end_s(iR,2),stageID{iR});

end
fclose(fp);
