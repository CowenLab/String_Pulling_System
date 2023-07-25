function INTAN_Sync_DeepLabCut_To_Intan(deeplab_file, frame_times_uS, outfile, sFreq)
% function INTAN_Sync_DeepLabCut_To_Intan(deeplab_file, frame_times_uS, outfile, sFreq)
%
% Cowen 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  deeplab_file = 'C:\Temp\5.1DLC_resnet50_Digit Tracking +Nov22shuffle1_1030000.csv'; % note:Day 4 seems like we lost the timestmaps.
%  load('C:\Users\Stephen Cowen\Box Sync\Cowen Laboratory\Data\LID_Ketame_Single_Unit_R56\Rat315\05\EVT.mat');
%  sFreq = 30000; % sampling rate of data acquisition.
%  frame_times_uS = 1e6*EVT.front_camera_frame_ID/sFreq;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% deeplab_file='G:\DATA\LID_Ketamine_SingleUnit_R56\315\24\24DeepCut_resnet50_Digit Tracking +Nov22shuffle1_1030000.csv';
% load('C:\Users\Sam.Jordan\Box\Cowen Laboratory\Data\LID_Ketame_Single_Unit_R56\Rat315\24\EVT.mat');
% sFreq = 30000; % sampling rate of data acquisition.
% frame_times_uS = 1e6*EVT.front_camera_frame_ID/sFreq;

[out_dir,fname,ext] = fileparts(deeplab_file);
if nargin < 3
    outfile = fullfile(out_dir,'DeepLabCutCoords.mat');
end
opts = delimitedTextImportOptions();
opts.DataLines = [2 3];
H = readmatrix(deeplab_file,opts);
% Create new variable names
new_vbl = [];
for iV = 1:length(H)
    new_vbl{iV} = [H{1,iV} '_' H{2,iV}];
end
new_vbl{1} = 'frame';
T = readtable(deeplab_file,'HeaderLines',2);
% Convert to singles to save space.
f = fieldnames(T);
for iF = 1:size(T,2)
    T.(f{iF}) = single(T.(f{iF}));
end
% rename the variables...
T.Properties.VariableNames = new_vbl;

nrecs = [length(frame_times_uS) size(T,1)];

if length(frame_times_uS)  > size(T,1)
    disp('Intan events > data file. Assuming the video recording terminated prematurely')
end

if length(frame_times_uS)  < size(T,1)
    disp('Intan events < data file. Assuming intan crashed prematurely or the video recording lasted longer than the intan recording')
end

min_recs = min(nrecs);
T.Time_uSec = ones(size(T,1),1)*-1;
T.Time_uSec = double(T.Time_uSec);

T.Time_uSec(1:min_recs) = frame_times_uS(1:min_recs);
% isa(T.x,'single')
% isa(T.Time_uSec,'single')
% isa(T.Time_uSec,'double')
NOTES = 'Created using INTAN_Sync_DeepLabCut_To_Intan.m';
save(outfile,'T','NOTES');

if nargout == 0
    coords_to_plot = [];
    coords_to_plot{1,1} = 'L0_x';
    coords_to_plot{1,2} = 'L0_y';
    coords_to_plot{2,1} = 'L5_x';
    coords_to_plot{2,2} = 'L5_y';
    coords_to_plot{3,1} = 'R0_x';
    coords_to_plot{3,2} = 'R0_y';
    coords_to_plot{4,1} = 'R5_x';
    coords_to_plot{4,2} = 'R5_y';
    coords_to_plot{5,1} = 'Nose_x';
    coords_to_plot{5,2} = 'Nose_y';
    
    for iC = 1:Rows(coords_to_plot)
        figure
        plot(T.(coords_to_plot{iC,1}),T.(coords_to_plot{iC,2}),'.','Markersize',1)
        xlabel(coords_to_plot{iC,1})
        ylabel(coords_to_plot{iC,2})
        axis tight
        
    end
    
    % Now plot against time... and include likelihood.
    for iC = 1:rows(coords_to_plot)
        figure
        plot(T.Time_uSec/60e6,T.(coords_to_plot{iC,1}))
        hold on
        plot(T.Time_uSec/60e6,T.(coords_to_plot{iC,2}))
        newvbl = [(coords_to_plot{iC,2}(1:end-1)) 'likelihood'];
        yyaxis right
       
        plot(T.Time_uSec/60e6,T.(newvbl),'c')
        
        title([coords_to_plot{iC,1} coords_to_plot{iC,2}])
        axis tight
        xlabel('min')
    end
end
