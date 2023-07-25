function O = Wonambi_stages_to_RemLogic(start_time_string, stageID, duration_s, out_file)

%% for testing
% start_end_s = [0 30; 30 60; 60 90; 90 120];
% stageID = {'NREM' 'REM' 'NREM' 'WAKE'};
% times_sec = [0 30 60 120];
% start_time_string = '07:00:0.0';
% out_file = 'C:\Temp\remlogic.txt';
% duration_s = 30;
O.prefix = '2019-08-29T'; %year-month-date


O.d = ['2019-08-29 ' start_time_string];
O.t = datetime(O.d,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');

fp = fopen(out_file,'w');
fprintf(fp,'RemLogic Event Export\n');
fprintf(fp,'Patient:	\n');
fprintf(fp,'Patient ID:	\n');
fprintf(fp,'Recording Date:   11/07/2019\n\n'); %date-month-year
fprintf(fp,'Events Included:\n SLEEP-S0\n SLEEP-S1\n SLEEP-S2\n SLEEP-UNSCORED\n\n');
fprintf(fp,'Time [hh:mm:ss]	 Event   Duration[s]\n');
for iR = 1:length(stageID)
    tstr = datestr(O.t+seconds(duration_s*(iR-1)),'HH:MM:SS');
    fprintf(fp,'%s%s\t%s\t%d\n',O.prefix,tstr,stageID{iR}, duration_s);
end
fclose(fp);

end
