
% External functions and DLLs
% 	GetP3RawFileData.m      Used to read P3 RAW files and obtain a single channel's data over a specified time range
%   P3RawFile.DLL           Dll used to read the RAW file 
%   P3RawFile_C.H           Include file associated with the DLL

function DisplayP3Data_minimal()
 	MICRO_100_MUL   = int32(10000);      % P3 uses NANO_MUL and works with time in nano seconds
 										 % In this module, time is represented in 10ths of milliseconds instead
 										 % (math on int64s is not supported in Matlab)

    DATA_ROOT           = 'C:\\LSS_DATA\\Merck Impedance Matlab\\'
	MAX_SAMPLES = int32(100000);   % data are processed in MAX_SAMPLES chunks
    Chan                = 2;       % 1 based P3 channel number
	
    szRawFileName 		= sprintf('%s%s', DATA_ROOT, '3-1-2013 PVR4 for impedence.RAW'); 		

    iStart          = int32(-1);            % time associated with the first point in the file
    iDuration       = int32(5*60);          % Duration to load in seconds
    [Data, SampleRate] 		= GetP3RawFileData(szRawFileName, Chan, iStart, iDuration*MICRO_100_MUL); %#ok<NASGU>

    plot(Data);         % plots data in samples
end
    


% [EOF]
