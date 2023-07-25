function [T,sFreq] = Load_EEG_Block_Timestamps(eeg_file,interval)
%
%
%
FieldSelection = [1 0 1 0 0];
ExtractMode = 4; ExtractHeader = 0;
T = [];
try
    [T sFreq] =  Nlx2MatCSC( eeg_file, FieldSelection, ExtractHeader, ExtractMode, interval );
end

if isempty(T)
    disp('Using ReadCR_partial_load')
    [T,x,sFreq] = ReadCR_partial_Load(eeg_file,interval(1)/100,interval(2)/100);
    T = T*100;
end
sFreq = sFreq(1);
