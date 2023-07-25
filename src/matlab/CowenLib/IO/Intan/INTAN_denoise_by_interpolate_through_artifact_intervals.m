function DAT = INTAN_denoise_by_interpolate_through_artifact_intervals(DAT, st_ed_recid, pts_before_after )
% Cowen 2016
plot_it = false;

if ischar(DAT)
    dat_file = DAT;
    fp = fopen(dat_file,'rb');
    DAT = fread(fp,'int16');
    fclose(fp);
    write_file = true;
else
    write_file = false;
end

if plot_it 
    plot(DAT,'k')
end
len = length(DAT);
for ii  = 1:Rows(st_ed_recid)
    ix1 = st_ed_recid(ii,1)-pts_before_after(1):(st_ed_recid(ii,1)-1);
    ix2 = (st_ed_recid(ii,2)+1):(st_ed_recid(ii,2)+1) + pts_before_after(2);
    ix = [ix1 ix2];
    ix= ix(ix<len & ix > 0);
    DAT(st_ed_recid(ii,1):st_ed_recid(ii,2)) = interp1(ix,DAT(ix),st_ed_recid(ii,1):st_ed_recid(ii,2),'pchip'); % Tried spline - not very good.
end

if plot_it
    hold on
    plot(DAT,'g')
    legend('orig','subtracted')
end

if write_file
    [p,n,e] = fileparts(dat_file);
    newfile = fullfile(p,[n '_intrpart' e]);
    fp = fopen(newfile,'wb');
    fwrite(fp,int16(DAT),'int16');
    fclose(fp);
end
