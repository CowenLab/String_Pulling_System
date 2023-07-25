function [OUT] = INTAN_EIB_to_Channel_Map(drive_type, fs, good_channels, out_file)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Translates the pinout on an EIB to a channel map file used by kilosort
% and other things.
% INPUT: drive type - the EIB or drive that defines the pinout.
%        fs - sampling frequency (chanMap needs this for kilosort)
%        optional good_channels: intan channels that are good. The rest
%        will be eliminated from the output.
%     
% Feel free to add any new designs - just give them a unique case code in
% the switch statemement.
%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% chanMap is the structure required by kilosort.
if nargin < 3
    good_channels = [];
end
if nargin < 4
    out_file = [];
end

OUT.chanMap.chanMap = [];
OUT.chanMap.chanMap0ind = [];
OUT.chanMap.connected = [];
OUT.chanMap.fs = fs;
OUT.chanMap.kcoords = [];
OUT.chanMap.xcoords = [];
OUT.chanMap.ycoords = [];

switch drive_type
    case 'CowenEIB'
        % The standard cowenlab EIB. Assuming cut flat so no y depth
        % differences. If cut at an angle, adjust the y coordinates
        % appropriately.
        % must be COLUMN vectors.
        OUT.EIBpinID = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31]';
        OUT.IntanCh0 = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31]';
        OUT.nTrodeID = [4 4 5 5 6 6 8 8 8 8 6  6  5  5  4  4   3 3   2  2  1  1  7  7  7  7  1  1  2  2  3  3]';
        % assumes a 2x4 linear array. my guess so double check
        % for dumb reasons, kilosort requires some variation in the y
        % coordinate. To deal with this, I'll just use the x coordinates
        % and swap with the y even though the Xpos was correct. It assumes
        % some form of linear array.
        % I think it even hates it when I have duplicate x pos.
         OUT.Xpos     = [3 3 3 3 4 4 4 4 4 4 4  4  3  3  3  3   2 2   1  1  1  1  2  2  2  2  1  1  1  1  2  2]';
%         OUT.Xpos     = ones(size(OUT.IntanCh0));
%         OUT.Ypos     = [1 1 1 1 1 1 1 1 1 1 1  1  1  1  1  1   1 1   1 1   1  1  1  1  1  1  1  1  1  1  1  1]';
%         OUT.Ypos     = [2 2 2 2 2 2 2 2 2 2 2  2  2  2  2  2   1 1   1 1   1  1  1  1  1  1  1  1  1  1  1  1]';
        OUT.Ypos     = [1:length(OUT.Xpos)]';
        OUT.Headstage= ones(size(OUT.nTrodeID));
end
if ~isempty(good_channels)
    [~,ix] = intersect(OUT.IntanCh0, good_channels );
    OUT.GoodChannelIX = false(size(OUT.IntanCh0 ));
    OUT.GoodChannelIX(ix) = true;
else
    OUT.GoodChannelIX = true(size(OUT.IntanCh0 ));   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create the chanMap data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OUT.chanMap.chanMap = 1:length(OUT.EIBpinID(OUT.GoodChannelIX));
OUT.chanMap.chanMap  = OUT.chanMap.chanMap(:);
OUT.chanMap.chanMap0ind = OUT.chanMap.chanMap-1;
OUT.chanMap.connected = [1:length(OUT.chanMap.chanMap)]'; % Assumed this was logical but apparently not - a list of channels.
OUT.chanMap.kcoords = OUT.nTrodeID(OUT.GoodChannelIX);
OUT.chanMap.xcoords = OUT.Xpos(OUT.GoodChannelIX);
OUT.chanMap.ycoords = OUT.Ypos(OUT.GoodChannelIX);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot as a sanity check.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
gscatter( OUT.Xpos+randn(size(OUT.Xpos))/10 , OUT.Ypos+randn(size(OUT.Ypos))/10, categorical(OUT.nTrodeID), lines(length(unique(OUT.nTrodeID))))
xlabel('XPos'); ylabel('YPos')

if ~isempty(out_file)
    tmp = OUT.chanMap;
    save(out_file,'-struct','tmp')
    disp(['Saved ' out_file])
    
end