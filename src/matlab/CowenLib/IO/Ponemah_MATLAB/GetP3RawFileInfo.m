

function [NumTimes, StartTimes, EndTimes, SampleRate] = GetP3RawFileInfo(szFileName, iImportChan)   %defaults to file name
	NumTimes	= 0;
	StartTimes	= 0;
	EndTimes 	= 0;
	SampleRate	= 0;

	MICRO_100_MUL   = int32(10000);      % math on int64s is not supported, using time in 10ths of milliseconds instead

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
 

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%% Load P3RawFile DLL
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	[notfound,warnings]=loadlibrary('P3RawFile', 'P3RawFile_C.h');
	libfunctions('P3RawFile');
	calllib('P3RawFile', 'P3RawFile_OpenFile', szFileName, pP3RawAddr, phResult); P3RawAddr  = pP3RawAddr.value;

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%% Check for JMP file
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	calllib('P3RawFile', 'P3RawFile_DoesJumpExist', P3RawAddr, pbJmpExists);
	if false == pbJmpExists.value 
		msgbox('The selected RAW file does not contain a JMP file. Use P3 to update the RAW file prior to loading in MATLAB', 'Warning', 'warn'); 
		return;
	end
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%% Get data times
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% call with NumTimes = 0, to get actual num times
	pNumTimes.value    = 0;
	calllib('P3RawFile', 'P3RawFile_CalculateDataTimes', P3RawAddr, pStartTimes, pEndTimes, pNumTimes, phResult);  
	if 0 == pNumTimes.value 
		msgbox('No time segments in RAW file', 'Warning', 'warn'); 
		return;
	end
	NumTimes	= pNumTimes.value;
 
	StartTimes     = zeros(pNumTimes.value, 1, 'int32');
	EndTimes       = zeros(pNumTimes.value, 1, 'int32');
	pStartTimes    = libpointer('int32Ptr', StartTimes);   
	pEndTimes      = libpointer('int32Ptr', EndTimes);   
	calllib('P3RawFile', 'P3RawFile_CalculateDataTimes', P3RawAddr, pStartTimes, pEndTimes, pNumTimes, phResult);
	StartTimes     = pStartTimes.value;
	EndTimes       = pEndTimes.value;

	calllib('P3RawFile', 'P3RawFile_CloseFile', P3RawAddr, phResult); % Close file and reopen, else crash on getting samples
	%% CloseFile must be called to prevent a crash when calling GetNextSampleScaled
	calllib('P3RawFile', 'P3RawFile_OpenFile', szFileName, pP3RawAddr, phResult);    P3RawAddr  = pP3RawAddr.value;

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%% Verify requested channel
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	calllib('P3RawFile', 'P3RawFile_GetChannelCount', P3RawAddr, piChanCount);
	iChanCount     = piChanCount.value;
	SampleFrame     = zeros(iChanCount,1, 'single');   pSampleFrame = libpointer('singlePtr', SampleFrame); 
	% reserve space for type for each channel
	aiValidChans     = zeros(iChanCount, 1, 'int8'); 
	for iChan=1:iChanCount
		calllib('P3RawFile', 'P3RawFile_GetChanType', P3RawAddr, iChan-1, piType);
		aiValidChans(iChan) = int8(piType.value > 0);
	end
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

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%% Get SampleRate
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	calllib('P3RawFile', 'P3RawFile_GetSampleRate', P3RawAddr, pMasterSampleRate);
	calllib('P3RawFile', 'P3RawFile_GetChanDivisor', P3RawAddr, iImportChan-1, piDivisor);
	SampleRate     = pMasterSampleRate.value/single(piDivisor.value);
 
	%% Cleanup
	calllib('P3RawFile', 'P3RawFile_CloseFile', P3RawAddr, phResult);
	unloadlibrary('P3RawFile');   
    