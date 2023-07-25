OLDBAD_NEWGOOD_TTS = [1 8; 2 7; 3 6; 4 5; 5 4; 6 3; 7 2; 8 1; 9 16; 10 15; 11 14; 12 13; 13 12; 14 11; 15 10; 16 9];


load('AllSpikes.mat')
for ii = 1:length(SP)
    IX = OLDBAD_NEWGOOD_TTS(:,1) == SP(ii).Tetrode;
    SP(ii).Tetrode = OLDBAD_NEWGOOD_TTS(IX,2);
end

save('AllSpikes.mat','SP')