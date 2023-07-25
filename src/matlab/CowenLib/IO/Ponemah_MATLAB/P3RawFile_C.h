
#pragma once
// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the P3RAWFILE_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// P3RAWFILE_API functions as being imported from a DLL, wheras this DLL sees symbols
// defined with this macro as being exported.
#ifdef P3RAWFILE_EXPORTS
#define P3RAWFILE_API __declspec(dllexport)
#else
#define P3RAWFILE_API __declspec(dllimport)
#endif

//typedef PVOID VP3RAW;			//Had some issues with void pointers in Matlab
typedef int VP3RAW;

#ifdef __cplusplus
extern "C"
{
#endif

P3RAWFILE_API void P3RawFile_OpenFile(char *szFileName, VP3RAW *pvP3Raw, HRESULT *phResult);
P3RAWFILE_API void P3RawFile_CloseFile(VP3RAW vP3Raw, HRESULT *phResult);
P3RAWFILE_API void P3RawFile_DoesJumpExist(VP3RAW vP3Raw, BOOL *bExists);
P3RAWFILE_API void P3RawFile_JumpToTime(VP3RAW vP3Raw, int iTime, HRESULT *phResult);
P3RAWFILE_API void P3RawFile_GetNextSampleScaled(VP3RAW vP3Raw, float *pSignals, int iCount, HRESULT *phResult);
P3RAWFILE_API void P3RawFile_GetChannelCount(VP3RAW vP3Raw, int *piChannelCount);
P3RAWFILE_API void P3RawFile_GetChanType(VP3RAW vP3Raw, int iChan, int *piType);
P3RAWFILE_API void P3RawFile_GetChanDivisor(VP3RAW vP3Raw, int iChan, int *piDivisor);
P3RAWFILE_API void P3RawFile_CalculateDataTimes(VP3RAW vP3Raw, INT32 *pStartTimes, INT32 *pEndTimes, int *pCount, HRESULT *phResult);
P3RAWFILE_API void P3RawFile_GetSampleRate(VP3RAW vP3Raw, float *pfSampleRate);


#ifdef __cplusplus
}
#endif

// ////////////////////////////////////////////////////////////////////////////////
// // NOTE: On Decimal, Power, & Scale
// //
// // Decimal is depricated, kept around for the use in older RAW files.
// // Power is essentially equivilent to 1 / 10^Decimal (also depricated)
// // Scale is Cal_Span / AD_Span (Usually [HighCal-LowCal] / [SHRT_MAX-SHRT_MIN])

// // This class is exported from the P3RawFile.dll
// class P3RAWFILE_API P3FileOpener
// {
// public:
   // virtual HRESULT OpenFile(HANDLE* phFile, LPCTSTR szFileName, DWORD dwDesiredAccess, DWORD dwShareMode, 
                        // DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes) = NULL;

   // virtual HRESULT DeleteFile(LPCTSTR szFileName) = NULL;
// };


// class JumpCache;

// //////////////////////////////////////////////////////////////////////////////
// // Error Codes
// const int      RAWFILE_ERROR_START     =  0x2000;	// Start index for error codes
// enum RAW_FILE_ERROR_CODES{
   // RAWERR_NO_JUMP = (RAWFILE_ERROR_START + 1),		///< Jump File not found
   // RAWERR_FILE_ALREADY_OPEN,                       ///< Raw File is already open
   // RAWERR_CANNOT_CREATE_FILE,                      ///< Unable to create the Raw File
   // RAWERR_FILE_NOT_OPEN,                           ///< Raw File is not open, cannot perform request
   // RAWERR_RAWHEADER_NOT_VALID,                     ///< The Raw File does not contain a valid Raw Header
   // RAWERR_RAWHEADER_ALREADY_WRITTEN,               ///< The Raw Header has alreawdy been written, cannot modify
   // RAWERR_CANNOT_OPEN_JUMP,                        ///< Cannot open the jump file
   // RAWERR_NO_MORE_BLOCKS,                          ///< No more blocks, end of file reached
   // RAWERR_CANCELED,                                ///< Action canceled
   // RAWERR_JUMPFILE_ERROR,                          ///< Error encountered in the jump file
   // RAWERR_NEED_CALC_DATA_TIMES,                    ///< CalcDataTimes has not been called, expected to have been called
   // RAWERR_END_OF_BLOCK,                            ///< End of data in block
   // RAWERR_APPEND_NOT_SUPPORTED,                    ///< Currently, Appended raw file not supported
   // RAWERR_UNEXPECTED_END_OF_FILE,                  ///< Reached EOF when not expected, middle of an operation
   // RAWERR_UNDETERMINED,                            ///< Unknown Error
// };


// //////////////////////////////////////////////////////////////////////////////
// // Raw File Modes
// enum RAW_FILE_MODE {
   // RAWFILE_NONE,
   // RAWFILE_WRITING,
   // RAWFILE_READING,
// };


// typedef  struct
// {
   // short AD_Low;     ///< A/D Low bit value
   // short AD_High;    ///< A/D High bit value
   // float Scale;      ///< Scale value
   // char  ChanID[9];  ///< Channel ID
// } CHANNEL_GROUP;

// const int      USERNAME_LENGTH         =  40;
// const int      RAWFILE_MAX_CHANNELS    =  128;
// const DWORD    RAWFILE_APPEND          =  0x55aaaa52;
// const DWORD    RAWFILE_ID_16           =  0x55aaaa50;  // raw data file for 16 channels
// const DWORD    RAWFILE_ID_8            =  0x55aaaa51;  // for 8 channel system
// const DWORD    RAWFILE_NEW_ID16        =  0x55aaaa54;  // used for float sample rate
// const DWORD    RAWFILE_NEW_ID8         =  0x55aaaa55;
// const DWORD    RAWFILE_EXTENDED        =  0xaa5555aa;
// const DWORD    RAWFILE_EXTENDED2       =  0xaa5555a5;  // extended file with extended jump

// /////////////////////////////////////////////////
// /// Struct for Raw Header Data
// typedef struct
// {
   // BOOL        bValid;           ///< Is the header struct valid
   // BOOL        bOldRawFile;      ///< Is this an old style Raw File
   // BOOL        bExtendedFile;    ///< Is this a newer, extended Raw File
   // BOOL        bExtendedJump;    ///< Does the jump file have exetended attributes
   // long        lFileID;          ///< Actual fileID of the Raw File (first 4 bytes of file)
   // USHORT      sNumChannels;     ///< Number of channels in Raw File
   // USHORT      sAD_Serial;       ///< Serial number of the AD system
   // USHORT      sCP_Serial;       ///< Serial number of the Rainbow key on system
   // long        lDate;            ///< Date the data was acquired (start date)
   // long        lTime;            ///< Time the data was acquired (start time)
   // ULONGLONG   n64JumpTable;     ///< Position of Jump Table - if combined with raw file
   // INT64       i64TimeSlice;     ///< Time slice of Raw File, according to Master Sample Rate, in Nanoseconds
   // char        cGroups;          ///< Number of groups in Raw FIle (always 1, I think)
   // int         iNumActive;       ///< Num Active?
   // float       fRate;            ///< Master Sample Rate
   // char        szUserName[USERNAME_LENGTH];           ///< Name of user that Acquired the file
   // char        acType[RAWFILE_MAX_CHANNELS];          ///< Array, Channel Type of signal
   // int         iSampleIndex[RAWFILE_MAX_CHANNELS];    ///< Array, number of active channels prior to this channel
   // char        acDecimal[RAWFILE_MAX_CHANNELS];       ///< Array, Decimal multiplier of channel
   // USHORT      sDivisor[RAWFILE_MAX_CHANNELS];        ///< Array, Divisor modifier to sample rate
   // float       afHighCal[RAWFILE_MAX_CHANNELS];       ///< Array, High Cal value
   // float       afLowCal[RAWFILE_MAX_CHANNELS];        ///< Array, Low Cal value
   // ULONGLONG   n64RawHeaderLength;                    ///< Length of Raw File Header
   // CHANNEL_GROUP Group[RAWFILE_MAX_CHANNELS][RAWFILE_MAX_CHANNELS];  ///< Array of CHANNEL_GROUP
// } RAW_HEADER_DATA;

// /////////////////////////////////////////////////
// /// Struct for Block Header Data
// typedef struct
// {
   // BOOL        bValid;              ///< Is block header valid
   // DWORD       dwNanoSeconds;       ///< Time of block header start, the Nanosecond offset
   // DWORD       dwElapsedTime;       ///< Time of block header start, in seconds
   // DWORD       dwDataSize;          ///< Size of data in block header
   // char        cGroup;              ///< First group in Block (Always 1?)
   // char        cFirstChan;          ///< First channel in Block
   // short       sDivisorCount[RAWFILE_MAX_CHANNELS];   ///< Array, current Divisor Count for this block
   // ULONGLONG   i64EndBlockTime;     ///< End time of Block
   // DWORD       dwDataPos;           ///< Current position within Block as it is read
   // char        *pData;              ///< Pointer to Data
// } BLOCK_HEADER_DATA;


// /////////////////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////
// // P3RawFile
// class P3RAWFILE_API P3RawFile
// {
// public:
   // friend JumpCache;

   // P3RawFile();
   // ~P3RawFile();

   // /////////////////////////////////////////////////////////////////////////////
   // // Reading Methods
   // HRESULT  OpenFile(LPCTSTR szFileName);
   // HRESULT  CloseFile();
   // BOOL     IsOpen();
   // HRESULT  GetNextSampleScaled(float* pSignals, int iCount);
   // HRESULT  GetNextSampleUnscaled(short* pSamples, int iCount);
   
   // /////////////////////////////////////////////////////////////////////////////
   // // Jump Methods
   // BOOL     DoesJumpExist();
   // HRESULT  CreateJumpFile(BOOL bSynchronous);
   // HRESULT  JumpToTime(INT64 i64Time);

   // /////////////////////////////////////////////////////////////////////////////
   // // Acquiring Methods
   // HRESULT  CreateFile(LPCTSTR szFileName);
   // HRESULT  PutNextSampleUnscaled(BOOL bSave, short* pSamples, int iCount, float* pSignals = NULL);
   // HRESULT  PutNextSampleScaled(BOOL bSave, float* pSignals, int iCount, short* pSamples = NULL);
   // HRESULT  BreakToTime(INT64 i64Time);

   // /////////////////////////////////////////////////////////////////////////////
   // // Time Methods
   // HRESULT  GetFileTime(USHORT* pHours, USHORT* pMinutes, USHORT* pSeconds);
   // HRESULT  SetFileTime(USHORT iHours, USHORT iMinutes, USHORT iSeconds);
   // HRESULT  GetFileDate(ULONG* pYear, ULONG* pMonth, ULONG* pDay);
   // HRESULT  SetFileDate(ULONG iYear, ULONG iMonth, ULONG iDay);
   // HRESULT  GetCurrentElapsedTime(USHORT* pHours, USHORT* pMinutes, USHORT* pSeconds, USHORT* pMilliSeconds);
   // INT64    GetCurrentNanoSeconds();
   // HRESULT  GetCurrentRealTime(USHORT* pHours, USHORT* pMinutes, USHORT* pSeconds, USHORT* pMilliSeconds);
   // HRESULT  GetCurrentRealDate(ULONG* pYear, ULONG* pMonth, ULONG* pDay);
   // HRESULT  CalculateDataTimes(INT64 *pStartTimes, INT64 *pEndTimes, int *pCount);

   // /////////////////////////////////////////////////////////////////////////////
   // // Other Functions
   // HRESULT  CopyHeaderInfo(P3RawFile *pRawFile);
   // HRESULT  SetFileOpener(P3FileOpener *pOpener);

   // /////////////////////////////////////////////////////////////////////////////
   // // Properties
   // void     SetUserName(LPCTSTR newVal);
   // void     GetUserName(char* pVal, int iCount);
   // float    GetSampleRate();
   // void     SetSampleRate(float newVal);
   // INT64    GetTimeSlice();
   // void     SetTimeSlice(INT64 newVal);
   // USHORT   GetCPSerial();
   // void     SetCPSerial(USHORT newVal);
   // USHORT   GetADSerial();
   // void     SetADSerial(USHORT newVal);
   // USHORT   GetChannelCount();
   // void     SetChannelCount(USHORT newVal);

   // char     GetChanType(int iChan);
   // void     SetChanType(int iChan, char newVal);
   // char     GetChanDecimal(int iChan);
   // void     SetChanDecimal(int iChan, char newVal);
   // USHORT   GetChanDivisor(int iChan);
   // void     SetChanDivisor(int iChan, USHORT newVal);
   // float    GetChanHighCal(int iChan);
   // void     SetChanHighCal(int iChan, float newVal);
   // float    GetChanLowCal(int iChan);
   // void     SetChanLowCal(int iChan, float newVal);
   // short    GetChanADHigh(int iChan);
   // void     SetChanADHigh(int iChan, short newVal);
   // short    GetChanADLow(int iChan);
   // void     SetChanADLow(int iChan, short newVal);
   // float    GetChanScale(int iChan);
   // void     SetChanScale(int iChan, float newVal);
   // void     GetChanID(int iChan, char* pVal, int iCount);
   // void     SetChanID(int iChan, LPCTSTR newVal);

   // int      GetCurrentDivisorCount(int iChan);
   // void     SetCurrentDivisorCount(int iChan, int iDivisor);
	
   // long     GetRawHeaderID();
	// void     GetFileName(LPTSTR o_strFileName, int iMaxChars) const;

// protected:
   // void     ResetMembers();
   // UINT64   HugeSeek(INT64 i64DistanceToMove, DWORD dwMoveMethod);
   // HRESULT  ReadRawHeader();
   // HRESULT  ReadBlockHeader(LONG bReadData);
   // HRESULT  ReadBlockHeaderMem(char* pBuffer);
   // void     CalcScalingVars();
   // void     UpdateFileStats();
   // float    ScaleData(int iChan, short sData);
   // short    UnscaleData(int iChan, float fSignal);
   // HRESULT  AppendJump();
   // HRESULT  WriteRawHeader();
   // HRESULT  FillNextBlockHeader();
   // HRESULT  WriteBlock();

   // LONG     ReadLong();
   // void     ReadString(char *szVal, int iLength);
   // UINT64   ReadInt64();
   // float    ReadFloat();
   // USHORT   ReadShort();
   // char     ReadChar();
   // LONG     BufferReadLong(char** pBuffer);
   // UINT64   BufferReadInt64(char** pBuffer);
   // char     BufferReadChar(char** pBuffer);
   // USHORT   BufferReadShort(char** pBuffer);
   // float    BufferReadFloat(char** pBuffer);

   // static UINT    CreateJumpFileProc(LPVOID pInfo);
   // static LONG    SwapLong(long value);

// protected:
   // HANDLE                  m_hFile;
   // HANDLE                  m_hJumpFile;
   // char                    *m_szFileName;
   // char                    *m_szJumpName;
   // P3FileOpener            *m_pDefaultFileOpener;
   // P3FileOpener            *m_pFileOpener;
   // UINT64                  m_n64EndOfFile;
   // UINT64                  m_n64BlockHeaderSize;
   // int                     m_iRawFileMode;
   // JumpCache               *m_pJumpCache;
   // RAW_HEADER_DATA         m_RawHeader;
   // BLOCK_HEADER_DATA       m_BlockHeader;
   // char                    *m_pBlockData;          ///< Variable to hold block data when read directly from file
   // INT64                   m_i64CurElapsedTime;
   // BOOL                    m_bCancelCreateJump;
   // HANDLE                  m_hJumpLock;
   // double                  m_fJumpFilePerc;
   // int                     m_iDesiredBlockSize;
   // FILETIME                m_ftLastCalcData;
   
   // INT64                   *m_pDataStartTimeArray;
   // INT64                   *m_pDataEndTimeArray;
   // int                     m_iDataTimeCount;
   // int                     m_iDataTimeAlloc;

   // float       m_fScaleVal[RAWFILE_MAX_CHANNELS];           ///< Array, Calculated Scale value for each channel
   // float       m_fScaleLowCal[RAWFILE_MAX_CHANNELS];        ///< Array, Calculated Cal value for each channel
   // SHORT       m_sDivisorCount[RAWFILE_MAX_CHANNELS];       ///< Array, current divisor count of channels
   // LONG        m_bInterestedChan[RAWFILE_MAX_CHANNELS];     ///< Array of Interested Channels
// };


