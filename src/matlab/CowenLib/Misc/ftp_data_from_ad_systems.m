function ftp_data_from_ad_systems(ratID,sessionID)
% Gets all of the data from the machine.
%cd C:\Cowen\Data\VPA
rat = sprintf('%02.0f',ratID);
id = sprintf('%02.0f',sessionID);
trackers = [1 3 5 6 7 8 10 14];
for iT = trackers
    disp(['Transferring from tracker' num2str(iT)])
    f = ftp(['tracker' num2str(iT)],'root','');
    binary(f) % CRITICAL!!! Otherwise you get byte swapping and weirdness.
    d = dir(f,['r' rat '*_' id '*']);
    cd(f,'/dos/ad')
    mget(f,['r' rat '*_' id '*'])
    close(f)
end
%% Transfer crap to brahms.
disp(['Transferring to Brahms'])
f = ftp('brahms','nitz','pelter1');
binary(f) % CRITICAL!!! Otherwise you get byte swapping and weirdness.
cd(f,'cowen_data')
cd(f,['rat' rat])
mkdir(f,id)
cd(f,id)
mput(f,['r' rat '*_' id '*.eeg'])
mput(f,['r' rat '*_' id '*.pos'])
close(f)
    
    
% Convert the unt files to nlx files.
%% Not really a part of ftp, but good to get done anyway.
unt_files = find_files('*.unt');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the steretrode data and save it as
%  Neuralyx Tetrode data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iF = 1:length(unt_files)
    % First, extract each stereotrode (do this first as loading the entire
    % .unt file into memory will probably kill the system)
    [p,n,e] = fileparts(unt_files{iF});
    [T,WV,EID]= Read_unt_file(unt_files{iF});
    if length(T) > 700000
        % Rethreshold the data if it's too big.
        [T,WV,EID]= Read_unt_file(unt_files{iF},nan);
    end
    WV = reshape(WV',32,4,length(T));
    % Write to the appropriate tt file.
    if ~isempty(WV)
        for ii = [0 1];
            IX = EID==ii;
            n_recs = length(T(IX));
            scn = zeros(1,n_recs);
            pars = zeros(8,n_recs);
            cn = zeros(1,n_recs);
            if n_recs > 8000
                % NOTE: Use this version of mat2nlxtt because the newer versions are even more cryptic and do not work
                n = strrep(n,'.','_');
                mat2nlxtt_v1([n '_' num2str(ii) '.Ntt'], double(T(IX)')*100, scn, cn, pars,double(WV(:,:,IX)), sum(IX));
            end
        end
    end
end
copyfile('../Batch1.txt',pwd)