
function [Signal, SampleRate] = GetP3RawFileData(szFileName, iImportChan, iStart, iDuration)   %defaults to file name

%NANO_MUL        = int64(1000000000);
MICRO_100_MUL   = int32(10000);      % math on int64s is not supported, using time in 10ths of milliseconds instead

%% Load P3RawFile DLL
% addpath(['C:\code\P3 Raw File\P3RawFile_C\Release']);
[notfound,warnings]=loadlibrary('P3RawFile', 'P3RawFile_C.h');
libfunctions('P3RawFile');


%% User Inputs
% szFileName  = 'C:\LSS_DATA\Fulldemo.RAW';
% iImportChan   = 1;  %1 based channel index
% iStart      = int32(-1);      %time associated with the first point of interest, -1 = start of file
% %1Start    = int32(HrMnSec( , , )) * MICRO_100_MUL;
% 
% iDuration   = int32(HrMnSec(0,8,0)) * MICRO_100_MUL;     %duration to load in seconds

%% Setup Pointers
% TODO - figure out how to use voidPtr 
% pVoid             = voidPtr;     ppP3Raw     = libpointer('voidPtrPtr', pVoid);
 pbJmpExists        = libpointer('int32Ptr', int32(0));
 phResult           = libpointer('int32Ptr', int32(0));
 pP3RawAddr         = libpointer('int32Ptr', int32(0));
 piChanCount        = libpointer('int32Ptr', int32(0));
 piType             = libpointer('int32Ptr', int32(0));
 pMasterSampleRate  = libpointer('singlePtr', single(0));
 piDivisor          = libpointer('int32Ptr', int32(0));
 pStartTimes        = libpointer('int32Ptr', int32(0));   % dummy pointers until we know the size needed
 pEndTimes          = libpointer('int32Ptr', int32(0));   % dummy pointers until we know the size needed
 pNumTimes          = libpointer('int32Ptr', int32(0)); 
 

%% Get Data times in RAW file
 calllib('P3RawFile', 'P3RawFile_OpenFile', szFileName, pP3RawAddr, phResult); P3RawAddr  = pP3RawAddr.value;

 % call with NumTimes = 0, to get actual num times
 pNumTimes.value    = 0;
 calllib('P3RawFile', 'P3RawFile_CalculateDataTimes', P3RawAddr, pStartTimes, pEndTimes, pNumTimes, phResult);  
 if 0 == pNumTimes.value 
     msgbox('No time segments in RAW file', 'Warning', 'warn'); 
     return;
 end
 StartTimes     = zeros(pNumTimes.value, 1, 'int32');
 EndTimes       = zeros(pNumTimes.value, 1, 'int32');
 pStartTimes    = libpointer('int32Ptr', StartTimes);   
 pEndTimes      = libpointer('int32Ptr', EndTimes);   
 calllib('P3RawFile', 'P3RawFile_CalculateDataTimes', P3RawAddr, pStartTimes, pEndTimes, pNumTimes, phResult);

 calllib('P3RawFile', 'P3RawFile_CloseFile', P3RawAddr, phResult); % Close file and reopen, else crash on getting samples


%% Open the RAW dll again, after calling CalculateDataTimes, else a crash
%% will occur on calling GetNextSampleScaled()
 calllib('P3RawFile', 'P3RawFile_OpenFile', szFileName, pP3RawAddr, phResult);    P3RawAddr  = pP3RawAddr.value;

 calllib('P3RawFile', 'P3RawFile_GetChannelCount', P3RawAddr, piChanCount);
 iChanCount     = piChanCount.value;
 SampleFrame     = zeros(iChanCount,1, 'single');   pSampleFrame = libpointer('singlePtr', SampleFrame); 

 calllib('P3RawFile', 'P3RawFile_DoesJumpExist', P3RawAddr, pbJmpExists);
 if false == pbJmpExists.value 
     msgbox('The selected RAW file does not contain a JMP file. Use P3 to update the RAW file prior to loading in MATLAB', 'Warning', 'warn'); 
     return;
 end

% reserve space for type for each channel
 aiValidChans     = zeros(iChanCount, 1, 'int8'); 
% get type for each channel

 for iChan=1:iChanCount
    calllib('P3RawFile', 'P3RawFile_GetChanType', P3RawAddr, iChan-1, piType);
    aiValidChans(iChan) = int8(piType.value > 0);
 end

 calllib('P3RawFile', 'P3RawFile_GetSampleRate', P3RawAddr, pMasterSampleRate);
 calllib('P3RawFile', 'P3RawFile_GetChanDivisor', P3RawAddr, iImportChan-1, piDivisor);
 SampleRate     = pMasterSampleRate.value/single(piDivisor.value);
 
%% Verify 
 % Is the import channel is legit
 if(iImportChan > iChanCount || iImportChan < 1)
     chans = '';
     for iChan=1:iChanCount
         if(aiValidChans(iChan) > 0)
             if(chans ~= '')
                 chans = sprintf('%s, %d', chans, iChan);
             else
                 chans = sprintf('%d',iChan);
             end
         end
     end
     Msg = sprintf('The requested channel does not exist, the valid channels are %s', chans);
     msgbox(Msg, 'Warning', 'warn'); 
     return;
 end

% Is the requested range is within a single segment
 if(-1 == iStart);     iStart = pStartTimes.value(1);    end
 iEnd       = iStart + iDuration;
 bSegGood   = false;
 for iSeg=1:pNumTimes.value
     if(iStart >= pStartTimes.value(iSeg) && iEnd <= pEndTimes.value(iSeg))
         bSegGood   = true;
         break;
     end
 end
 if(false == bSegGood);  msgbox('time out of range', 'Warning', 'warn'); return; end
 
 %Jump to the start Time
  calllib('P3RawFile', 'P3RawFile_JumpToTime', P3RawAddr, iStart, phResult);
 
 %determine the number of points
 iNumPoints     = int32(double(iDuration)/double(MICRO_100_MUL) * SampleRate);
 
 Signal = zeros(iNumPoints, 1, 'double');
 for i=1:iNumPoints
     calllib('P3RawFile', 'P3RawFile_GetNextSampleScaled', P3RawAddr, pSampleFrame, iChanCount, phResult);
     SampleFrame = pSampleFrame.value;
     Signal(i) = SampleFrame(iImportChan);
 end
 
 
 calllib('P3RawFile', 'P3RawFile_CloseFile', P3RawAddr, phResult);

unloadlibrary('P3RawFile');

%plot(Signal);




    
    