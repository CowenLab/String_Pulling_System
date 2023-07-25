% Attempt to fix nlx files by opening them with the standard reader and
% re-saving them - may do nothing but some corrupt files screw up our other
% readers. This function allows you to choose the valid range in the EEG
% data for saving so that there are no discontinuities.
CSC_files = find_files('*.Ncs');
FieldSelection(1) = 1;
FieldSelection(2) = 1;
FieldSelection(3) = 1;
FieldSelection(4) = 1;
FieldSelection(5) = 1;

ExtractHeader = 1;

ExtractMode = 1;

ModeArray(1) = 1;
%ModeArray(2) = 4;
%ModeArray(3) = 9;

%[Timestamps, ChannelNumbers, SampleFrequencies, NumberValidSamples, Samples, NlxHeader] = Nlx2MatCSC_v4( CSC_files{iF}, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
% 
[Timestamps, ChannelNumbers, SampleFrequencies, NumberValidSamples, Samples, NlxHeader] = Nlx2MatCSC_v4( CSC_files{1}, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
% Choose a good region;
figure(1)
clf
plot(Timestamps,[nan diff(Timestamps)]);
title('Enter range to restrict data to.')

[x,y] = ginput(2);
for iF = 1:length(CSC_files)
   % [Timestamps, ChannelNumbers, SampleFrequencies, NumberValidSamples, Samples, NlxHeader] = Nlx2MatCSC_v4(CSC_files{iF},1,1,1,1,1,1);
   if iF > 1
       [Timestamps, ChannelNumbers, SampleFrequencies, NumberValidSamples, Samples, NlxHeader] = Nlx2MatCSC_v4( CSC_files{iF}, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
   end
   ix = find(Timestamps > x(1) & Timestamps < x(2));
   
   xFieldSelection(1) = 1;
   xFieldSelection(2) = 0;
   xFieldSelection(3) = 0;
   xFieldSelection(4) = 0;
   xFieldSelection(5) = 1;
   xFieldSelection(6) = 1;
   fname = strrep(CSC_files{iF},'.Ncs','.Ncs.original');
   movefile(CSC_files{iF},fname)
   
   Mat2NlxCSC(CSC_files{iF} , 0,ExtractMode, ModeArray, length(ix), xFieldSelection, Timestamps(ix), Samples(:,ix),NlxHeader);
   CSC_files{iF}
end
