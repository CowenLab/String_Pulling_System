OLDBAD_NEWGOOD_TTS = [1 17; 2 16; 3 15; 4 14; 5 4; 6 3; 7 2; 8 1; 9 8; 10 7; 11 6; 12 5; 13 13; 14 12; 15 11; 16 10];


load('AllSpikes.mat')
for ii = 1:length(SP)
    IX = OLDBAD_NEWGOOD_TTS(:,1) == SP(ii).Tetrode;
    SP(ii).Tetrode = OLDBAD_NEWGOOD_TTS(IX,2);
end

save('AllSpikes.mat','SP')