function [T,WV,EID]= Read_unt_file(unt_file,thresh)
%function [T,WV,EID]= Read_unt_file(unt_file,thresh)
% Reads the binary unt file.
% INPUT: unt_file - name of AD .unt file
%        thresh - threshold to apply to the data - e.g. to reduce the size
%        of a file that's too big. YOU CAN ALSO put a Nan for the
%        threshold. If you do this, a plot of the max points on the
%        waveforms will be drawn and you can then choose a new threshold.
%        IF YOU LEAVE THIS EMPTY, ALL POINTS ARE RETURNED.
%
% OUTPUT: Waveforms (128 pts) and timestamps and the electrode ID for each
%         spike on the tetrode. (in native precision)
%
% cowen 2008
% 264 bytes in each record: 128*2 = 256 for data leaving 8 bytes for the channel and timestamp
% [filename, permission, machineformat, encoding] = fopen(fid);
%%
if nargin == 1
    thresh = [];
end
fp = fopen(unt_file,'r');
out = [];
% Get past the header.
while isempty(findstr(out,'%%ENDHEADER'))
    out = fgetl(fp);
end
endheader_pos = ftell(fp); %
% move forward until you get to some good data.
% int electrode_num; long timestamp; int data[128]
%%
extra = 1;
if 1
    data = [0 0 ];
    el_num = inf;
    ts = -1;
    count = 1;
    offset = 1658;
    startpos = endheader_pos + offset; % 3395 works for most non-corrupt files.
    fseek(fp,startpos,-1); % Some junk at the end of the header.
    while (abs(el_num) > 1) || ((max(abs(data))) > 5000) || (ts < 100000) || (extra ~= 29555)
        curpos = ftell(fp);
        el_num = fread(fp,1,'int16');
        ts = fread(fp,1,'int32');
        data = fread(fp,128,'int16');
        extra = fread(fp,1,'int16'); % 29555 usually
        if feof(fp) % || count > 10000
            fclose(fp);
            error([ unt_file ' NO RECORDS OR CORRUPT!' ])
        end
        fseek(fp,startpos + count,-1);
        count = count + 1;
    end
    fseek(fp,-1,0); % move back one.
    %%%%%%
    %% Estimate the size of the data array and initialize the variables.
    %%%%%%
else
    curpos = 3395; % HARD WIRED HEADER SIZE (MAY NOT BE APPROPRIATE FOR ALL FILES)
end
%%
fseek(fp,0,1);
endpos = ftell(fp);
n_recs = ceil((endpos-curpos)/264);
fprintf('Header ends at %u. Found Start at %u, check = %u.\n Estimated %u records.\n',endheader_pos,curpos,extra,n_recs);
T  = zeros(n_recs,1,'int32')*nan; % Keep it in the native size - much smaller as a matlab double is 8 bytes (64).
WV = zeros(n_recs,128,'int16');
EID = zeros(n_recs,1,'int8')*nan;
EX = zeros(n_recs,1,'int16')*nan;

%%%%%%
%% Get records - This is where it could screw up.
%%%%%%
fseek(fp,curpos,-1);
count = 1;
dix = [1:4:128 2:4:128 3:4:128 4:4:128];
go = 1;
while go
    el_num = fread(fp,1,'int16') ;
    ts = fread(fp,1,'int32');
    data = fread(fp,128,'int16');
    %extra = fread(fp,1,'int16') ;
    fread(fp,1,'int16') ;

    if feof(fp)
        break
    end

    if count < (n_recs-1) && (el_num > 1 || ts < 1000 || extra ~= 29555)
        disp([unt_file ' Corrupt record: ' num2str(count)])
        % Skip ahead past the corruption. Hope that the timestmaps are not
        % fucked up.
        data = data + 10000; extra = 1;
        el_num = inf;   ts = -1; 
        while (abs(el_num) > 1) || ((max(abs(data))) > 4000) || (ts < 100000) || extra ~= 29555
            curpos = ftell(fp);
            el_num = fread(fp,1,'int16');
            ts = fread(fp,1,'int32');
            data = fread(fp,128,'int16');
            extra = fread(fp,1,'int16'); % 29555 usually
            if feof(fp) % || count > 10000
                ts = 0;
                data = zeros(128,1)*nan;
                el_num = 1000;
                extra = -1;
                go = 0;
                break;
            end
            fseek(fp,1,0); % move ahead.
        end
        if ~feof(fp)
            fseek(fp,-1,0); % move back one.
        end
    end
    WV(count,:) = data(dix);
    T(count) = ts;
    EID(count) = el_num;
    EX(count) = extra;
    count = count + 1;
    if mod(count,10000) == 0
        fprintf('.')
    end
end
badix = find(T ==0 | EID > 1 | EX ~= 29555);
WV(badix,:) = [];
EID(badix) = [];
T(badix) = [];

if ~isempty(thresh)
    mx = double(max(WV(:,8:32:128),[],2));   
    if isnan(thresh)
        figure
        hist(mx(1:100:end),100);
        title(['CHOOSE THE 2 point THRESHOLD WINDOW !!!!!!!!!!! ' num2str(length(mx))])
        xlabel(['Originally ' num2str(length(T)) ' points.'])
        [thresh,y] = ginput(2);
    end
    IX = mx >= min(thresh) & mx <= max(thresh);
    WV= WV(IX,:);
    EID = EID(IX);
    T = T(IX);
    close
end

fprintf('\nActual %u records.\n',length(T));
%%
fclose(fp);

if 0
    clf
    for jj = 1:4
        subplot(2,2,jj)
        plot(data(jj:4:end))

    end
    title(num2str(el_num))
end

