function ZONE = Identify_zones(POS,zones,description)
%function Identify_zones(POS,zones)
%% Indetify Zones on the maze for analysis.
%% Pass in the position data - when the animal is running on the maze.
% Cowen
if nargin == 1 || isempty(zones)
    zones = {'Turn_After_TrialStart'  'Divergence_After_TrialStart' 'Door_1' 'Door_5'  'Convergence_After_Doors' 'Turn_After_Doors' 'Reward' 'Turn_After_Reward' 'Bend_In_Return_Path' 'Turn_Before_TrialStart'};
end
door1_to_5_cm = 37; % observed
clf;
plot(POS(:,2), POS(:,3));
disp('Click left and right anywhere to indicate the estimated track width');
[x, y] = ginput(2);
ZONE.MazeWidthPixels = abs(diff(x));
for ii = 1:length(zones)
    title([ description '   '  zones{ii}]);
    disp(['Enter center location for (Door 5 is inside)' zones{ii}]);
    [x, y] = ginput(1);
    hold on
    plot(x,y,'ro')
    eval(['ZONE.' zones{ii} '=[' num2str(x) ' ' num2str(y) '];'])
    % Square 
    plot_boxes(x,y,ZONE.MazeWidthPixels,'g');
end
dist_pix = sqrt(sum((ZONE.Door_1-ZONE.Door_5).^2));

ZONE.CMPerPixel = door1_to_5_cm/dist_pix;
ZONE.MazeWidthCM = ZONE.MazeWidthPixels*ZONE.CMPerPixel; % Need to figure this out.

