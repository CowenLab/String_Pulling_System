
% External functions and DLLs
% 	GetP3RawFileInfo.m		Used to get information on the RAW file - sample rates and segments
% 	GetP3RawFileData.m      Used to read P3 RAW files and obtain a single channel's data over a specified time range
%   P3RawFile.DLL           Dll used to read the RAW file 
%   P3RawFile_C.H           Include file associated with the DLL

function DisplayP3Data()
    global  MICRO_100_MUL;
	InitializeGlobals();
    reply = 'Y';

    DATA_ROOT           = 'C:\\LSS_DATA\\Merck Impedance Matlab\\'
	MAX_SAMPLES = int32(100000);   % data are processed in MAX_SAMPLES chunks
    SBP_Chan            = 2;       % 1 based P3 channel number
    SBF_Chan            = 3;       % 1 based P3 channel number
	
    szRawFileName 		= sprintf('%s%s', DATA_ROOT, '3-1-2013 PVR4 for impedence.RAW'); 		

    % Get RAW file info
    %   iNumSegments                number of data segments in the RAW file segments are bounded by breaks in the data - this occurs with a scheduled acquisition 
    %   aiStartTimes, aiEndTimes    arrays of data start and end times
    %   SampleRate
    [iNumSegments, aiStartTimes, aiEndTimes, SampleRate] = GetP3RawFileInfo(szRawFileName, SBP_Chan);

    Fs      = SampleRate
    dT      = int32(1/double(SampleRate) * MICRO_100_MUL);		% Intersample spacing in tenths of milliSeconds
    dt      = 1/double(SampleRate);                             % Intersample spacing in seconds

    %  a continuous acquisition will contain only one segment - a scheduled acquisition will contain multiple segments
    for iSeg=1:iNumSegments				% Steps through each segment in the RAW file
        if(reply ~= 'Y')
            break;
        end
        iStartTime      = aiStartTimes(iSeg);											% In tenths of mSec
        iEndTime        = iStartTime + (MAX_SAMPLES - 1) * dT;							% In tenths of mSec - step through by MAX_SAMPLES
        if(iEndTime > aiEndTimes(iSeg));                iEndTime = aiEndTimes(iSeg);    end;
        if(iStartTime > iEndTime);                      continue;    end;
        iCurTime        = iStartTime;
        
        while(iCurTime<iEndTime)
            % Get data from the RAW file
            [SBP, iDummy] 		= GetP3RawFileData(szRawFileName, SBP_Chan, iCurTime, iEndTime-iCurTime); %#ok<NASGU>
            [SBF, iDummy] 		= GetP3RawFileData(szRawFileName, SBF_Chan, iCurTime, iEndTime-iCurTime); %#ok<NASGU>
            
            L = size(SBP,1);
            t = double(0:L-1)*dt;                % Time vector

            figure('Name', 'Impedance', 'Position', [0, 0, 1000, 700]);
            iSubplot    = 1;
            iNumPlots   = 2;
            ax(iSubplot) = subplot(iNumPlots,1,iSubplot);
            plot(t(1:L),SBP(1:L),'b'); axis([t(1) t(L) min(SBP) max(SBP)]);
            title('SBP');
            
            iSubplot = iSubplot+1;
            ax(iSubplot) = subplot(iNumPlots,1,iSubplot);
            plot(t(1:L),SBF(1:L),'b'); axis([t(1) t(L) min(SBF) max(SBF)]);
            title('SBF');

            linkaxes(ax, 'x');
            zoom xon;


            % Set up for next segment of data
            iCurTime    = iEndTime + dT;
            iEndTime    = iCurTime + (MAX_SAMPLES - 1) * dT;
            if(iEndTime > aiEndTimes(iSeg)) 
                iEndTime = aiEndTimes(iSeg);
            end
            
            reply = input('Continue? Y/N [Y]: ', 's');
            if isempty(reply)
                reply = 'Y';
            end
            if(reply ~= 'Y' && reply ~= 'y')
                break;
            end
        end
    end
end


       
function InitializeGlobals()
    global MICRO_100_MUL;

	MICRO_100_MUL   = int32(10000);      % P3 uses NANO_MUL and works with time in nano seconds
										 % In this module, time is represented in 10ths of milliseconds instead
										 % (math on int64s is not supported in Matlab)
    
end



% [EOF]
