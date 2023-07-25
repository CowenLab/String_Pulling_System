function D = Read_DSI_Ponemah_eeg_ascii(fname,nChannels,assumed_sFreq)
% function D = Read_DSI_Ponemah_eeg_ascii(fname,nChannels,assumed_sFreq)
%
%% Read output from Ponemah DSI data acquisition system. It's ASCII.
%
% Tried to make this efficient givne the data format but it's going to be
% slow. Big files. text files. slow conversion of datetime timestamps. 
%
%
%
%% Cowen 2017

if nargin < 3
    assumed_sFreq = 1000;
    % The timestamps do not have the precision that would capture ms. Maybe
    % there is another way to output the data with more precision?
end
%% %%%%%%%%%%%%%%%%%%%%%%%

block_size_sec = 30;
txtscanstr = '';
for ii = 1:(nChannels + 1)
    txtscanstr = [txtscanstr '%s'];
end
%%

fp = fopen(fname,'r');
for ii = 1:150
    l = fgetl(fp)
end
if nargin < 2
    nChannels = length(strfind(l,'x'));
end

tic
cnt = 1; block_cnt = 1; file_save_cnt = 1;
TIME = nan(1000000,1);
EEG = zeros(1000000,nChannels,'single');
while fp>0
    b = textscan(fp,txtscanstr,assumed_sFreq*block_size_sec,'Delimiter',',','EmptyValue',nan);
    if ~isempty(b{1})
        if strcmpi(b{2}{1},'x') || isempty(b{2}{1})
            fprintf('o')
        else
            if mod(block_cnt,20) == 0
                fprintf('.%s %2.2fh\n',b{1}{1},cnt/(assumed_sFreq*60*60))
            else
                fprintf('.')
            end
            T = datenum(datetime(b{1},'format','M/d/yyyy h:m:s:SSSS aa')); % I think that this is what slows things down but not a good way around this.
            DATA = nan(length(T),nChannels);
            for ii =1:nChannels
                DATA(:,ii) = str2double(b{ii+1});
            end
            TIME(cnt:(cnt+length(T)-1),:) = T;
            EEG(cnt:(cnt+length(T)-1),:) = DATA;
            
            cnt = cnt + length(T);
            % If the file is HUGE, then let's break it up into 24h bits...
            if cnt/(assumed_sFreq*60*60) > 12
                               
                sFreq = 1/(mode(diff(TIME))*(24*60*60));
                
                INFO.Notes = 'Time is in datenums which are in days. Multiply by *24*60*60 to convert to seconds';
                INFO.sFreq = sFreq;
                
                [p,n] = fileparts(fname);
                save(fullfile(p,[n 'f' num2str(file_save_cnt) '.mat']),'TIME','EEG','INFO')
                EEG = []; TIME = [];
                cnt = 1;
                file_save_cnt = file_save_cnt + 1;
                disp('Saved subfile')
            end
            
        end
    else
        fprintf('x')
        % End if you found an empty record. This should be universal indcating eof.
        break
    end
    block_cnt = block_cnt + 1;
end
fclose(fp);
% EEG = EEG(1:(cnt-length(TIME)-1),:);

%%

sFreq = 1/(mode(diff(TIME))*(24*60*60));

INFO.Notes = 'Time is in datenums which are in days. Multiply by *24*60*60 to convert to seconds';
INFO.sFreq = sFreq;

toc/60
[p,n] = fileparts(fname);
if file_save_cnt > 1
    save(fullfile(p,[n 'f' num2str(file_save_cnt) '.mat']),'TIME','EEG','INFO')
else
    save(fullfile(p,[n '.mat']),'TIME','EEG','INFO')
end
figure
for iCh = 1:nChannels
    subplot(nChannels,1,iCh)
    plot(TIME(1:1000:end)-TIME(1),EEG(1:1000:end,iCh))
    xlabel('Days')
    ylabel('mV');
    axis tight
    box off
    if iCh ==1
        title(sprintf('%s to %s, skip 1000',datestr(T(1)),datestr(T(end))))
    else
        title(num2str(iCh))
    end
end
saveas(gcf,fullfile(p,[n '.png']))

if nargout > 0
    D.EEG = EEG;
    D.T = T;
    D.INFO = INFO;
end
%%
%%
%%
%%
%%
if 0
    % Other things we 'could' do prior to saving, but this alters the original data so I think that this should be done in a different program.
    tic
    zix = 1;
    % Many timestamps are missing - there is not that much precision in the
    % timing - blocks are missed. We will have to interp, assuming that the
    % sFreq is 1000.
    while  ~isempty(zix)
        interval = (1/assumed_sFreq)/(24*60*60);
        
        zix = find([1;diff(D(:,1))]==0);
        if ~isempty(zix)
            if zix(1) == 1
                D(1,1) = D(1,1) - 0.0001;
            end
            D(zix,1) = D(zix,1) - 0.0001 * rand(1,1);
        end
    end
    
    
    T = D(1,1):interval:D(end,1);
    
    D(BIX,2) = 0;
    BIX = conv(BIX,ones(1000,1),'same')>0;
    BAD_TIMES = D(BIX,1);
    
    for iCh = 1:nChannels
        EEG(:,iCh) = interp1(D(:,1),D(:,iCh+1),T);
        BIX(:,iCh) = abs(D(:,iCh+1)) > 1.5 | isnan(D(:,iCh+1));
        fprintf('Found %d bad recs',sum(BIX(:,iCh)))
    end
    
    ix = binsearch_vector(T,find(BAD_TIMES));
    ix = unique(ix);
    EEG(ix,:) = nan;
end
