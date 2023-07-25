function EVENT_SE = INTAN_Extract_Times_From_DIN(event_file)
% load the DIN data and get the up and down times.
PLOT_IT = false;
fp = fopen(event_file,'rb');
V = logical(fread(fp,'uint16')); % logical to save some space.
fclose(fp);
EVENT_SE = find_intervals(V,.001);

if PLOT_IT 
    figure
    plot(se(:,1), ones(size(se(:,1))),'g>')
    hold on
    plot(se(:,2), ones(size(se(:,2))),'r<')
%     plot(V)
    
    figure
    plot(se(:,2) - se(:,1))
    ylabel('diff between end and start time')
end