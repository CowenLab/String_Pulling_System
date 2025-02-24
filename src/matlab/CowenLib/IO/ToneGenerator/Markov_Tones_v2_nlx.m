% Markov_Tones_v2 present sequences randomly, keep track of order of sequences
%
%   differs from original Markov_Tones in that entire sequence of five
%   tones is prepared first, so tone to tone timing is fixed. Also, keeps a
%   record of the sequences played, to make decoding the microphone signal
%   easier.
%
% JRI 12/09
%
% Cowen - added a mod that interfaced with the cheetah system to send event
% codes. How am I going to do this with my system? Probably hardware is
% best.
%%
pDrop3 = 0.20;
nTrials = 800;

%pause(15*60)

serverName = 'localhost';
disp(sprintf('Connecting to %s...', serverName));
succeeded = NlxConnectToServer(serverName);
if succeeded ~= 1
    disp(sprintf('FAILED connect to %s. Exiting script.', serverName));
    return;
else
    disp(sprintf('Connected to %s.', serverName));
end

%Identify this program to the server we're connected to.
succeeded = NlxSetApplicationName('My Matlab Script');
if succeeded ~= 1
    disp 'FAILED set the application name'
else
    disp 'PASSED set the application name'
end

% from Markov_Tones_makesounds.m % Makes tones in this directory.
if ~exist('Markov_Tones_sounds.mat','file'),
    Markov_Tones_makesounds
end
load Markov_Tones_sounds.mat

%to save a list of the stimuli we play
if 0
    orderfile = ['stimulusOrder_' datestr(now, 'mm.dd.yy_HH.MM.SS') '.txt'];
    if exist(orderfile,'file')
        error('stimulusOrder file already exists? Shouldn''t happen.')
    end
    fid = fopen(orderfile, 'w+');
    %write an informative header
    fprintf(fid,'stimulusOrder for sounds generated by Markov_Tones_v2\n');
    fprintf(fid,'seq = [1 2 3 4 5; 5 4 3 2 1; 4 2 3 1 5]\n');
    fprintf(fid,['freqs = ' num2str(FQ) '\n' ]);
    fprintf(fid,'probabilty of dropping tone 3: %f\n\n',pDrop3);
    %
    fprintf(fid,'time\tseq_num\tdrop3\n');
    
    fprintf(2,'\nsounds now playing...control-c to stop\n');
    fprintf('A record of which sequences are presented will be saved in %s\n',orderfile);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Send some event information so that there is a record of the sequence
% parameters in the .Nev file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str =  '[1 2 3 4 5; 5 4 3 2 1; 4 2 3 1 5]';
[succeeded, cheetahReply] = NlxSendCommand(['-PostEvent "SOUND SEQUENCES: ' str '" 100 100 ']);
str = ['freqs: ' num2str(FQ)];
[succeeded, cheetahReply] = NlxSendCommand(['-PostEvent "SOUND ' str '" 100 100 ']);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start the trials
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic
for ii = 1:nTrials    
    seq_num = ceil(rand*3);
    drop3 = (rand<pDrop3);
    if drop3,
        snd = stim_missing3{seq_num};
    else
        snd = stim{seq_num};
    end
    tOn = now;
    
    sound(snd*0.9,sf);
    
    %record info about the sound that played
    % fprintf(fid,'%f\t%d\t%d\n',tOn, seq_num, drop3);
    str = sprintf('%d\t%d\t%f\n',seq_num, drop3,tOn);
    [succeeded, cheetahReply] = NlxSendCommand(['-PostEvent "SOUND ' str '" ' num2str(seq_num + 10 + 10*drop3) ' ' num2str(seq_num + 10 + 10*drop3) ]);
    if succeeded == 0
        disp 'FAILED to send command'
    else
        disp 'PASSED send command'
    end
    
    pause(2.5 + 1.2 + rand(1,1)*1.0) % Sounds are about 2.5 seconds long
end
toc/60
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Disconnects from the server and shuts down NetCom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
succeeded = NlxDisconnectFromServer();
if succeeded ~= 1
    disp 'FAILED disconnect from server'
else
    disp 'PASSED disconnect from server'
end
