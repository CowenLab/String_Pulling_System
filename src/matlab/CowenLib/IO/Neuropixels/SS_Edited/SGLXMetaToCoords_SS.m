function [chanMapFile,chanMapPath]=SGLXMetaToCoords_SS(varargin)
% 
% Write out coordinates for a Neuropixels 3A, 1.0 or 2.0 metadata file.
% Output selection: 0 for text coordinate file; 
%                   1 for Kilosort or Kilosort2 channel map file;
%                   2 for strings to paste into JRClust .prm file
% 
%SS edits for Kilosort and text output type ONLY
% 
% Input: binFileName and Path else it will ask for input meta file selection
% Output: Channel Map File Name and its path (Which is the samefolder as .meta/.bin file unless
% specified otherwise
%
%eg:[chanMapFile,chanMapPath]=SGLXMetaToCoords_SS(PRM_imec_binfile.name,AP_FILE_DIR)

outType = 1;
metaName='';
metaFilePath='';

% Ask user for metadata file
if length(varargin)<2
    [metaName,metaFilePath] = uigetfile('*.meta', 'Select Metadata File');

end

Extract_varargin;
% Parse in file to get the metadata structure 
meta=ReadMeta(metaName,metaFilePath);

% Shank separation for multishank
shankSep = 250;


%KILOSORT SS EDITS FOR FILE NAME AND PATH
% Build output name and write out file

[chanMapPath,fname,~] = fileparts(fullfile(metaFilePath,metaName));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(meta, 'imDatPrb_type')
    pType = str2num(meta.imDatPrb_type);
else
    pType = 0; %3A probe
end

if pType <= 1
    
    %Neuropixels 1.0 or 3A probe
    [elecInd, connected] = NP10_ElecInd(meta);
    
    % Get saved channels
    chans = OriginalChans(meta);
    [AP,LF,SY] = ChannelCountsIM(meta);    
    chans = chans(1:AP);        %1-based channel numbers

    % Trim elecInd and shankInd to include only saved channels
    elecInd = elecInd(chans);
    shankind = zeros(size(elecInd));
    
    % Get XY coords for saved channels
    [xcoords, ycoords] = XYCoord10(meta, elecInd);
    
   
else

    % Parse imro table for shank and electrode indicies
    [elecInd, shankind, bankMask, connected] = NP20_ElecInd(meta);

    % Get saved channels
    chans = OriginalChans(meta);
    [AP,LF,SY] = ChannelCountsIM(meta);
    chans = chans(1:AP);        %1-based channel numbers

    % Trim elecInd and shankInd to include only saved channels
    elecInd = elecInd(chans);
    shankind = shankind(chans);

    % Get XY coords for saved channels
    [xcoords, ycoords] = XYCoord20(meta, elecInd, bankMask, shankind);

end

switch outType
    case 0      %tab delimited, chan, x, y, shank
        chanMapFile= [fname,'-siteCoords.txt'];
        fid = fopen( fullfile(chanMapPath,chanMapFile), 'w');
        for i = 1:numel(elecInd)
            currX = shankind(i)*shankSep + xcoords(i);
            fprintf( fid, '%d\t%d\t%d\t%d\n', chans(i)-1, currX, ycoords(i), shankind(i));
        end
        fclose(fid);
        
    case 1     %KS2 *.mat
        chanMapFile = [fname,'_kilosortChanMap.mat'];
        chanMap = (1:numel(chans))';
        chanMap0ind = chanMap - 1;
        connected = logical(connected);
        xcoords = shankind*shankSep + xcoords;   %KS2 not yet using kcoords, so x coord includes shank sep
        kcoords = shankind + 1;     %KS1 uses kcoords to force templates to be on one shank
        name = fname;
        save( fullfile(chanMapPath, chanMapFile), 'chanMap', 'chanMap0ind', 'connected', 'name', 'xcoords', 'ycoords', 'kcoords' );
    
    case 2  %strings to copy into JRC prm file
       chanMapFile = [fname,'_forJRCprm.txt'];
       nchan = numel(chans);    
       fid = fopen( fullfile(chanMapPath,chanMapFile), 'w' );     
       fprintf( fid, 'shankMap = [' );       
       for i = 1:nchan-1
           fprintf( fid, '%d,', shankind(i) + 1 ); % switch to 1-based for MATLAB
       end
       fprintf( fid, '%d];\n',shankind(nchan) + 1 );
       
       xcoords = shankind*shankSep + xcoords; 
       
       fprintf( fid, 'siteLoc = [' );
       for i = 1:nchan-1
           fprintf(fid, '%d,%d;', xcoords(i), ycoords(i));
       end
       fprintf( fid, '%d,%d];\n', xcoords(nchan), ycoords(nchan) );
       
       fprintf( fid, 'siteMap = [' );
       for i = 1:nchan-1
           fprintf( fid, '%d,', chans(i) );
       end
       fprintf( fid, '%d];\n', chans(nchan) );
       fclose(fid);
end

end


function [meta] = ReadMeta(metaName, path)

    % Parse ini file into cell entries C{1}{i} = C{2}{i}
    fid = fopen(fullfile(path, metaName), 'r');
% -------------------------------------------------------------
%    Need 'BufSize' adjustment for MATLAB earlier than 2014
%    C = textscan(fid, '%[^=] = %[^\r\n]', 'BufSize', 32768);
    C = textscan(fid, '%[^=] = %[^\r\n]');
% -------------------------------------------------------------
    fclose(fid);

    % New empty struct
    meta = struct();

    % Convert each cell entry into a struct entry
    for i = 1:length(C{1})
        tag = C{1}{i};
        if tag(1) == '~'
            % remake tag excluding first character
            tag = sprintf('%s', tag(2:end));
        end
        meta = setfield(meta, tag, C{2}{i});
    end
end % ReadMeta


% =========================================================
% Return shank and electrode number for NP2.0.
%
% Index into these with original (acquired) channel IDs.
%
function [elecInd, shankInd, bankMask, connected] = NP20_ElecInd(meta)     
    pType = str2num(meta.imDatPrb_type);
    if pType == 21
        % Single shank probe
        % imro table entries: (channel, bank, refType, electrode #)
        C = textscan(meta.imroTbl, '(%*s %d %*s %d', ...
            'EndOfLine', ')', 'HeaderLines', 1 );
        elecInd = int32(cell2mat(C(2)));
        bankMask = int32(cell2mat(C(1)));
        shankInd = zeros(size(elecInd));
        connected = ones(size(elecInd));
        exChan = findDisabled(meta);        
        for i = 1:numel(exChan)        	
            connected(elecInd == exChan(i)) = 0;
        end
        
    else
        % 4 shank probe
        % imro table entries: (channel, shank, bank, refType, electrode #)
        C = textscan(meta.imroTbl, '(%d %d %d %*s %d', ...
            'EndOfLine', ')', 'HeaderLines', 1 );
        chan = double(cell2mat(C(1)));
        elecInd = int32(cell2mat(C(4)));
        bankMask = int32(cell2mat(C(3)));
        shankInd = double(cell2mat(C(2)));
        connected = ones(size(chan));
        exChan = findDisabled(meta);
        %exChan = [127];
        for i = 1:numel(exChan)       	
            connected(chan == exChan(i)) = 0;
        end
    end
end % NP20_ElecInd


% =========================================================
% Return shank and electrode number for NP1.0.
%
% Index into these with original (acquired) channel IDs.
%
function [elecInd, connected] = NP10_ElecInd(meta)     

    % 3A or 3B data?
    % 3A metadata has field "typeEnabled" which was replaced
    % with "typeImEnabled" and "typeNiEnabled" in 3B.
    % The 3B imro table has an additional field for the
    % high pass filter enabled/disabled
    % Note that the textscan funtion places line breaks at each
    % instance of the 'EndofLine' character -- here, ')'
    % 'HeaderLines' = 1 skips the initial entry in the table with
    % the probe type and number of entries.
    if isfield(meta,'typeEnabled')
        % 3A data
        C = textscan(meta.imroTbl, '(%d %d %*s %*s %*s', ...
            'EndOfLine', ')', 'HeaderLines', 1 );
        exChan = findDisabled(meta);
        %exChan = [36, 75, 112, 151, 188, 227, 264, 303, 340, 373];
    else
        % 3B data
        C = textscan(meta.imroTbl, '(%d %d %*s %*s %*s %*s', ...
            'EndOfLine', ')', 'HeaderLines', 1 );
        exChan = findDisabled(meta);
        %exChan = [191];
        
    end
    chan = double(cell2mat(C(1)));
    bank = double(cell2mat(C(2)));
    elecInd = bank*384 + chan;
    connected = ones(size(chan));
    for i = 1:numel(exChan)       	
        connected(chan == exChan(i)) = 0;
    end
    
end % NP10_ElecInd

% =========================================================
% Read shank map for any probe type and return list
% of channels that are disabled. This will include the 
% reference channels
%
% Note that the textscan funtion places line breaks at each
% instance of the 'EndofLine' character -- here, ')'
% 'HeaderLines' = 1 skips the initial entry in the table with
% the number of shanks, columns, and rows
function [exChan] = findDisabled(meta)     
    % read in the shank map    
    C = textscan(meta.snsShankMap, '(%d:%d:%d:%d', ...
            'EndOfLine', ')', 'HeaderLines', 1 );
    enabled = double(cell2mat(C(4)));
    % There's an entry in the shank map for each saved channel.
    % Get the array of saved channels:
    chan = OriginalChans(meta);
    % Find out how many are non-SY chans
    [AP,~,~] = ChannelCountsIM(meta);
    exChan = [];
    for i = 1:AP
        if enabled(i) == 0
            exChan = [exChan, chan(i)];
        end
    end
end % findDisabled

% =========================================================
% Return x y coords for electrode index for 2.0 probes
%
% 
function [xCoord, yCoord] = XYCoord20(meta, elecInd, bankMask, shankind)   

    pType = str2num(meta.imDatPrb_type);

    nElec = 1280;   %per shank; pattern repeats for the four shanks
    vSep = 15;   % in um
    hSep = 32;

    elecPos = zeros(nElec, 2);   

    elecPos(1:2:end,1) = 0;         %sites 0,2,4...
    elecPos(2:2:end,1) = hSep;      %sites 1,3,5...

    % fill in y values        
    viHalf = (0:(nElec/2-1))';                %row numbers
    elecPos(1:2:end,2) = viHalf * vSep;       %sites 0,2,4...
    elecPos(2:2:end,2) = elecPos(1:2:end,2);  %sites 1,3,5...
    
   
    xCoord = elecPos(elecInd+1,1);
    yCoord = elecPos(elecInd+1,2);
    
    if pType == 21
        % single shank probe. Plot only lowest selected electrode
        figure(1)
        % plot all positions
        scatter( elecPos(:,1), elecPos(:,2), 150, 'k', 'square' ); hold on;
        scatter( xCoord, yCoord, 100, 'b', 'square', 'filled' );hold on;   
        xlim([-16,64]);
        ylim([-10,10000]);
        title('NP 2.0 single shank view');
        hold off;
    else
        % four shank probe, no multiple connections        
        figure(1)
        shankSep = 250;
        for sI = 0:3
            cc = find(shankind == sI);
            scatter( shankSep*sI + elecPos(:,1), elecPos(:,2), 30, 'k', 'square' ); hold on;
            scatter( shankSep*sI + xCoord(cc), yCoord(cc), 20, 'b', 'square', 'filled' ); hold on; 
        end
        xlim([-16,3*shankSep+64]);
        ylim([-10,10000]);
        title('NP2.0 MS shank view');
        hold off;
    end

      
end % XY20Coord

% =========================================================
% Return x y coords for electrode index for 1.0 probes
%
% 
function [xCoord, yCoord] = XYCoord10(meta, elecInd)   

    nElec = 960;   %per shank; pattern repeats for the four shanks
    vSep = 20;   % in um
    hSep = 32;

    elecPos = zeros(nElec, 2);
    
    elecPos(1:4:end,1) = hSep/2;            %sites 0,4,8...
    elecPos(2:4:end,1) =  (3/2)*hSep;       %sites 1,5,9...
    elecPos(3:4:end,1) = 0;                 %sites 2,6,10...
    elecPos(4:4:end,1) =  hSep;             %sites 3,7,11...
    elecPos(:,1) = elecPos(:,1) + 11;       %x offset on the shank
    
    % fill in y values        
    viHalf = (0:(nElec/2-1))';                %row numbers
    elecPos(1:2:end,2) = viHalf * vSep;       %sites 0,2,4...
    elecPos(2:2:end,2) = elecPos(1:2:end,2);  %sites 1,3,5...
    
    xCoord = elecPos(elecInd+1,1);
    yCoord = elecPos(elecInd+1,2);
    
    % single shank probe. Plot only lowest selected electrode
    figure(1)
    % plot all positions
    scatter( elecPos(:,1), elecPos(:,2), 150, 'k', 'square' ); hold on;
    scatter( xCoord, yCoord, 100, 'b', 'square', 'filled' );hold on;   
    xlim([0,70]);
    ylim([-10,8000]);
    title('NP 1.0 single shank view');
    hold off;
    
end % XY10Coord


% =========================================================
% Return array of original channel IDs. As an example,
% suppose we want the imec gain for the ith channel stored
% in the binary data. A gain array can be obtained using
% ChanGainsIM() but we need an original channel index to
% do the look-up. Because you can selectively save channels
% the ith channel in the file isn't necessarily the ith
% acquired channel, so use this function to convert from
% ith stored to original index.
%
% Note: In SpikeGLX channels are 0-based, but MATLAB uses
% 1-based indexing, so we add 1 to the original IDs here.
%
function chans = OriginalChans(meta)
    if strcmp(meta.snsSaveChanSubset, 'all')
        chans = (1:str2double(meta.nSavedChans));
    else
        chans = str2num(meta.snsSaveChanSubset);
        chans = chans + 1;
    end
end % OriginalChans


% =========================================================
% Return counts of each imec channel type that compose
% the timepoints stored in binary file.
%
function [AP,LF,SY] = ChannelCountsIM(meta)
    M = str2num(meta.snsApLfSy);
    AP = M(1);
    LF = M(2);
    SY = M(3);
end % ChannelCountsIM

