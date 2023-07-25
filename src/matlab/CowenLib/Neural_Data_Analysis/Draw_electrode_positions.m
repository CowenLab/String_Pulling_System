function Draw_electrode_positions(electrode_text_id,locations_mm,plot_type)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [ATLAS] = Warp_electrode_display(electrode_text_id,locations_mm)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  INPUT: 
%        A cell array of text_id's like {'A1' 'B1' 'D3' }
%        the location of each electrode in mm (AP,ML,DV)
%        the plot type e.g. 'zilles'
% OUTPUT
%    pretty pictures.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 2
    plot_type = 'Zilles';
end
AP = 1;
ML = 2;
DV = 3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the results if no output arguments were specified.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch lower(plot_type)
    case 'zilles'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Plot a grid of the drive on top of a bitmap that indicates the location of the electrode.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        try
            %ATLAS.IMAGE = imread('Ziles1_cortex_cropped.bmp','bmp');
            [p,n,e] = fileparts(which(mfilename));
            load(fullfile(p,'ATLAS.mat'))
            x = linspace(ATLAS.Left_mm, ATLAS.Right_mm, size(ATLAS.IMAGE,2));
            y = linspace(ATLAS.Rostral_mm, ATLAS.Caudal_mm, size(ATLAS.IMAGE,1));
            imagesc(x,y,ATLAS.IMAGE)
            warning off
            alpha(.5)
            axis xy
            hold on
            warning on
        catch
            msgbox('Could not load in the ATLAS.mat file that contains the image.')
        end
        plot(locations_mm(:,ML),locations_mm(:,AP),'.');
        hold on
        for ii = 1:length(electrode_text_id)
            text(locations_mm(ii,ML),locations_mm(ii,AP),electrode_text_id{ii});
            plot(locations_mm(ii,ML),locations_mm(ii,AP),'ro','MarkerSize', abs(locations_mm(ii,DV)/2)+0.1);
        end
 %       figure; scatter(locations_mm(:,ML),locations_mm(:,AP) ,abs(locations_mm(:,DV)), abs(locations_mm(:,DV)))
    otherwise
        error('sdfafdasfd')
end