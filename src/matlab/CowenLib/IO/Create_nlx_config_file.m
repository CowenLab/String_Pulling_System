function Create_nlx_config_file(Spike_channels, CSC_channels, header_file, destination_file)
% Creates a Neuralynx config file for a specified mixture of channels.
% INPUT: 
%
%  CSC_channels, Spike Channels : if a vector of numbers, then a csc
%   or nse object is made for each channel. If a string, then the strings are
%   converted into numbers (e.g. A12 = channel 12, B12 = channel 24). If a
%   cell array of strings is passed, then the strings are converted into
%   channel numbers.
%
% header_file - location of a file that just contains the default header
%    information ( e.g.  sampling rate, buffer sizes, etc...)
% destingation_file - name of the config destination file.
%
% Examples :
%   Create_nlx_config_file({'A1' 'C4' 'K2' 'L12' },{'A10' 'C10' 'D3' 'L11' },'C:\Program Files\Neuralynx\Cheetah\Nlx_config_header.txt','C:\Program Files\Neuralynx\Cheetah\auto_Warp_144.cfg');
%   Create_nlx_config_file(1:144,145:160,'C:\Program Files\Neuralynx\Cheetah\Nlx_config_header.txt','C:\Program Files\Neuralynx\Cheetah\auto_Warp_144.cfg');
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: if you would like to change the sampling rate or buffer sizes, it
% is best to change it by altering the header file -- or creating a new
% one. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cowen 2004
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SCFreqDivisor = 16; % Default is 16, but tweak if you would like to push the limits.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preprocessing the inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(Spike_channels) | isempty(CSC_channels)
    error('You must pass in at least one value for the spike or CSC channels')
end

CSC_vector = [];
Spike_vector = [];
if iscell(CSC_channels)
    for ii = 1:length(CSC_channels)
        CSC_vector(ii) = Alpha2Channel(CSC_channels{ii});
    end
else 
    CSC_vector = CSC_channels;
end
if iscell(Spike_channels)
    for ii = 1:length(Spike_channels)
        Spike_vector(ii) = Alpha2Channel(Spike_channels{ii});
    end
else 
    Spike_vector = Spike_channels;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create the header records (stored in a separate header file.)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
success = copyfile(header_file, destination_file);
if ~success
    msgbox('PROBLEM COPYING HEADER FILE')
end
fp = fopen(destination_file,'a');
fprintf(fp,'\n\n### START OF AUTOMATIC CSC/SPIKE GENERATED FILE\n\n# Set up spike channels\n\n\n');

for ii = 1:length(Spike_vector)
    %if (Spike_vector(ii) < 145)
        fprintf(fp,'-Create SEScControl SEScDisp%i \n',ii);
        %fprintf(fp,'\t-SetRect 0 0 130 89\n');
        fprintf(fp,'\t-ControlSize 130 89\n');
        fprintf(fp,'\t-OcxName NeuralynxControls.NlxSeControl4\n');
        fprintf(fp,'\t-WaveformSize 64 72\n'); % If you don't do this, the waveform only takes up 1/2 of the x axis.
        %fprintf(fp,'\t-XYPlotSize 2 2\n');
        %fprintf(fp,'\t-CellFlag 511\n');
    %end
end
fprintf(fp,'\n\n# Create each spike object \n\n\n');

for ii = 1:length(Spike_vector)
    %if (Spike_vector(ii) < 145)
        fprintf(fp,'-Create SEScAcqEnt %i_Sc%i_%s\n',ii,Spike_vector(ii), Channel2Alpha(Spike_vector(ii)));
        fprintf(fp,'\t-Display SEScDisp%i\n',ii);
        fprintf(fp,'\t-DataFile Sc%03i_%s.nse\n',Spike_vector(ii), Channel2Alpha(Spike_vector(ii)));
        fprintf(fp,'\t-AcqUnit DCDCB\n');
        fprintf(fp,'\t-BigDisplay BigSc\n');
        fprintf(fp,'\t-ADChannel	%i\n',Spike_vector(ii)-1);
        fprintf(fp,'\t-GainControl SpikeGainControls\n');
        fprintf(fp,'\t-ADGain	8\n');
        fprintf(fp,'\t-AmpGain	2000\n');
        fprintf(fp,'\t-AmpHiCut	6000\n');
        fprintf(fp,'\t-AmpLowCut	600\n');
        fprintf(fp,'\t-ThreshVal	250\n\n\n');
    %end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CSC channels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(fp,'\n\n# Set up CSC channels\n\n\n');
for ii = 1:ceil(length(CSC_vector)/12)
    if ii <= 4
        x1 = 23 + (ii-1)*50;
        x2 = 868 + (ii-1)*80;
        y1 = x1+20;
        y2 = x2+40;
    elseif ii > 4 & ii <= 8
        x1 = 23 + 400 + (ii-5)*50;
        x2 = 868 + 400  + (ii-5)*80;
        y1 = 23 + 20 + (ii-5)*50;;
        y2 = 868 + 40 + (ii-5)*80;
    elseif ii > 8 & ii <= 12
        x1 = 23 + 800 + (ii-9)*50;
        x2 = 868 + 800  + (ii-9)*80;
        y1 = 23 + 20 + (ii-9)*50;;
        y2 = 868 + 40 + (ii-9)*80;
    end
    
    fprintf(fp,'-Create EegControl ContinuouslySampledChannels%i\n',ii);
    fprintf(fp,'	-SetRect %i %i %i %i\n',x1,y1,x2,y2);
    fprintf(fp,'	-DispTime 1000\n');
%    fprintf(fp,'	-Flash\n'); % the flash option does not work.
%    fprintf(fp,'	-SpreadZeros\n');
%    fprintf(fp,'	-ShowNormal\n');
end

fprintf(fp,'\n\n# Create CSC objects\n\n\n');
for ii = 1:length(CSC_vector)
    control_number = ceil(ii/12);
    fprintf(fp,'-Create CscAcqEnt %s_ch%i_CSC\n', Channel2Alpha(CSC_vector(ii)),CSC_vector(ii));
    fprintf(fp,'\t-Display ContinuouslySampledChannels%i\n',control_number);
    fprintf(fp,'\t-DataFile Ch%03i_%s.Ncs\n',CSC_vector(ii), Channel2Alpha(CSC_vector(ii)));
    fprintf(fp,'\t-AcqUnit DCDCB\n');
    fprintf(fp,'\t-GainControl CscGainControls\n');
    fprintf(fp,'\t-ADChannel	%i\n',CSC_vector(ii)-1);
    fprintf(fp,'\t-ADGain	2\n');

    if exist('E:\Cheetah_Data','dir')
        switch CSC_vector(ii)
            case 160 % Sound . This should be the same on both systems.
                fprintf(fp,'\t-AmpGain	100\n');
                fprintf(fp,'\t-AmpHiCut	3000\n'); % Don't have it at 3000 -- according to bruce, this will cause aliasing at low frequencies.
                fprintf(fp,'\t-AmpLowCut	100\n');
                fprintf(fp,'\t-SCFreqDivisor  %i\n', 4); % Faster sampling rate for audio.
                fprintf(fp,'\t-AcqMode	Normal\n\n\n');
            otherwise
                % Record a non-spiking spike channel continuously so that it can be
                % used as a reference later on.
                fprintf(fp,'\t-AmpGain	2000\n');
                fprintf(fp,'\t-AmpHiCut	6000\n'); % Don't have it at 3000 -- according to bruce, this will cause aliasing at low frequencies.
                fprintf(fp,'\t-AmpLowCut	600\n');
                fprintf(fp,'\t-SCFreqDivisor  %i\n', 1);
                fprintf(fp,'\t-AcqMode	Normal\n\n\n');
        end
    else
        switch CSC_vector(ii)
            case 145 % CSC 1 is reserved for spikes
                fprintf(fp,'\t-AmpGain	2000\n');
                fprintf(fp,'\t-AmpHiCut	6000\n'); % Don't have it at 3000 -- according to bruce, this will cause aliasing at low frequencies.
                fprintf(fp,'\t-AmpLowCut	300\n');
                fprintf(fp,'\t-SCFreqDivisor  %i\n', SCFreqDivisor);
                fprintf(fp,'\t-AcqMode	Normal\n\n\n');
            case num2cell(147:152) % EMG channels
                fprintf(fp,'\t-AmpGain	1000\n');
                fprintf(fp,'\t-AmpHiCut	475\n'); % Don't have it at 3000 -- according to bruce, this will cause aliasing at low frequencies.
                fprintf(fp,'\t-AmpLowCut	100\n');
                fprintf(fp,'\t-SCFreqDivisor  %i\n', SCFreqDivisor);
                fprintf(fp,'\t-AcqMode	Normal\n\n\n');
            case 160 % Sound . This should be the same on both systems.
                fprintf(fp,'\t-AmpGain	100\n');
                fprintf(fp,'\t-AmpHiCut	3000\n'); % Don't have it at 3000 -- according to bruce, this will cause aliasing at low frequencies.
                fprintf(fp,'\t-AmpLowCut	100\n');
                fprintf(fp,'\t-SCFreqDivisor  %i\n', 4); % Faster sampling rate for audio.
                fprintf(fp,'\t-AcqMode	Normal\n\n\n');
            otherwise
                fprintf(fp,'\t-AmpGain	500\n');
                fprintf(fp,'\t-AmpHiCut	475\n'); % Don't have it at 3000 -- according to bruce, this will cause aliasing at low frequencies.
                fprintf(fp,'\t-AmpLowCut	1\n');
                fprintf(fp,'\t-SCFreqDivisor  %i\n', SCFreqDivisor);
                fprintf(fp,'\t-AcqMode	Normal\n\n\n');
        end
    end
end

%if strcmp(hostid,'153609')
if 0
    % THIS DOES NOT WORK FOR SOME REASON.
    fprintf(fp,'-Select VideoTracker1\n');
    fprintf(fp,'	-SetRect 0 200 870 720\n');
    fprintf(fp,'	-ShowNormal\n');
    fprintf(fp,'	-UpdateWindowPosition\n');
    fprintf(fp,'	-PlotMode Fill\n\n');

    fprintf(fp,'-Select Tracker1\n');
    fprintf(fp,'	-Lum		1	64 \n');
    fprintf(fp,'	-PureRed	1	79 \n');
    fprintf(fp,'	-PureGreen	1	50 \n');
    fprintf(fp,'	-PureBlue	1	50 \n');
    fprintf(fp,'	-RawRed	0	100 \n');
    fprintf(fp,'	-RawGreen	0	100 \n');
    fprintf(fp,'	-RawBlue	0	100 \n');
    fprintf(fp,'	-BTColor	255 \n');
    fprintf(fp,'	-BTTint	128 \n');
    fprintf(fp,'	-BTBright	4 \n');
    fprintf(fp,'	-BTContrast	255 \n');
    fprintf(fp,'    -TargetDist	5 \n');
end

fprintf(fp,'\n\n\n\n\n#\n');
fprintf(fp,'# EOF\n');
fprintf(fp,'#\n');

fclose(fp)