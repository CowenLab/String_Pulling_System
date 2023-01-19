function [kinematics] = Q7_What_Are_Segment_Kinematics()
%Q7_WHAT_ARE_SEGMENT_KINEMATICS Summary of this function goes here
%   Function to calculate the movement kinematics for the identified
%   segments.
%   Currently calculates: movement speed, movement time,
%   eucleadian distance moved, total distance moved, path circuitry
%   might want to add number of Id pulls if we can stitch together matching
%   reaches/withdraws
%   INPUTS: None at this point
%   OUTPUTS: kinematics struct containing concatenated vectors of values
%   for all id segments. Also have been converted to useful units

%load/initialize variables and pulling coords



Behavior_sFreq = 367;
PXmap   =  [386,386,387];
pxPerCm=median(PXmap)/10;   %mapping of pixels per centimeter
totalDistance=0;

paws={'Right' 'Left'};
phases={'Reach' 'Withdraw'};
segmentNames={'Lift' 'Advance' 'Grasp' 'Push' 'Pull' };
%measurements= {'movementSpeed' 'peakSpeed' 'eucleadianDistance' 'totalDistance' 'movementTime' 'pathCircuitry' 'avgSpeed'};
measurements= {'peakSpeed' 'eucleadianDistance' 'totalDistance' 'movementTime' 'pathCircuitry' 'avgSpeed'};

load('EVT.mat')
if ~isempty(EVT.front_camera_frame_ID) && ~isempty(EVT.rotary_encoder_ID)
    fprintf("Detected Neural Recording Session\n")
    ePhys=1;
else
    fprintf("Detected Behavior Session\n")
    ePhys=0;
end
clear EVT


if ~isfile('good_string_pull_intervals_uSec.mat')
    
    if ePhys
        LK_Determine_good_pull_bouts()
    else
        load('Filtered_Time_Stamped_Coordinates_Corrected_Ori.mat')
        plot(T3.Time_uSec,T3.Left_y,'b')
        hold on
        plot(T3.Time_uSec,T3.Right_y,'r')
        hold off
        set(gcf,'Position',get(0,'Screensize'))
        good_string_pull_intervals_uSec=Ginput_pairs()
        close
        save('good_string_pull_intervals_uSec.mat','good_string_pull_intervals_uSec')
    end
end



if ePhys
    [MT, string_pull_intervals_uSec,PAW,~,~,~,EVENTS] = LK_Combine_All_String_Pull_Motion_To_Table(Behavior_sFreq, false);
else
    load('Filtered_Time_Stamped_Coordinates_Corrected_Ori.mat')
    load('good_string_pull_intervals_uSec.mat');
    [PAW, EVENTS] = LK_process_paw_data(T3, good_string_pull_intervals_uSec);
end


segments=LK_Segment_Pulls_Further;
close

kinematics.Notes="Distances are given in cm, Speeds are in cm/s, time is in s";

%%

for i=1:2
    %iterate through phases
    for j=1:2
        
        
        %iterate through segments until end of phase
        for col=0:width(segments.(paws{i}).(phases{j}))-1
            for row=1:height(segments.(paws{i}).(phases{j}))
                
                for m=1:length(measurements)
                    measure = measurements{m};
                    
                    
                    %get current segment name
                    if col==0
                        currSegName=segments.(paws{i}).(phases{j}).Properties.VariableNames{1};
                        switch currSegName
                            
                            case 'Lift'
                                currSegName='Reach';
                                
                            case 'Pull'
                                currSegName='Withdraw';
                        end
                    else
                        currSegName=segments.(paws{i}).(phases{j}).Properties.VariableNames{col};
                    end
                    
                    
                    
                    if row==1
                        
                        clear movementSpeed peakSpeed eucleadianDistance totalDistance movementTime pathCircuitry
                        %movementSpeed=nan([height(segments.(paws{i}).(phases{j})),1]);
                        peakSpeed=nan([height(segments.(paws{i}).(phases{j})),1]);
                        eucleadianDistance=nan([height(segments.(paws{i}).(phases{j})),1]);
                        totalDistance=nan([height(segments.(paws{i}).(phases{j})),1]);
                        movementTime=nan([height(segments.(paws{i}).(phases{j})),1]);
                        pathCircuitry=nan([height(segments.(paws{i}).(phases{j})),1]);
                        %avgSpeed=nan([height(segments.(paws{i}).(phases{j})),1]);
                        
                        
                        %kinematics.(paws{i}).(currSegName)=table(movementSpeed,  peakSpeed, eucleadianDistance, totalDistance, movementTime, pathCircuitry);
                        kinematics.(paws{i}).(currSegName)=table(peakSpeed, eucleadianDistance, totalDistance, movementTime, pathCircuitry);
                        
                    end
                    
                    
                    %segIdx holds start of current segment and start of
                    %next segment, then puts into startIdx and endIdx vars
                    
                    if strcmp(currSegName,'Reach') | strcmp(currSegName,'Withdraw')
                        segIdx=[segments.(paws{i}).(phases{j}){row,1},segments.(paws{i}).(phases{j}){row,width(segments.(paws{i}).(phases{j}))}];
                    else
                        segIdx=segments.(paws{i}).(phases{j}){row,col:col+1};
                    end
                    
                    
                    
                    
                    startIdx=segIdx(1);
                    endIdx=segIdx(2);
                    
                    %nans make it blow up so if either is nan just skip it
                    if isnan(startIdx) || isnan(endIdx)
                        continue
                    end
                    
                    
                    %Each calc for the different kinematics is different,
                    %this is all just math tho
                    %results in 1xn vector of the the kinematic values for
                    %all identified segments except framexframe velocity
                    
                    switch measure
                        
                        case 'movementSpeed'
                            
                            switch paws{i}
                                case 'Right'
                                    speed=...
                                        PAW.Right_speed(startIdx:endIdx)/pxPerCm;
                                    
                                case 'Left'
                                    speed=...
                                        PAW.Left_speed(startIdx:endIdx)/pxPerCm;
                            end
                            
                            kinematics.(paws{i}).(currSegName).movementSpeed(row) = speed;
                            
                            
                        case 'peakSpeed'
                            switch paws{i}
                                case 'Right'
                                    peakSpeed=...
                                        max(PAW.Right_speed(startIdx:endIdx))/pxPerCm;
                                    
                                case 'Left'
                                    peakSpeed=...
                                        max(PAW.Left_speed(startIdx:endIdx))/pxPerCm;
                                    
                            end
                            
                            kinematics.(paws{i}).(currSegName).peakSpeed(row)= peakSpeed;
                            
                        case 'eucleadianDistance'
                            
                            switch paws{i}
                                case 'Right'
                                    startpt=[PAW.Right_x(startIdx) PAW.Right_y(startIdx)];
                                    endpt=[PAW.Right_x(endIdx) PAW.Right_y(endIdx)];
                                    
                                case 'Left'
                                    startpt=[PAW.Left_x(startIdx) PAW.Left_y(startIdx)];
                                    endpt=[PAW.Left_x(endIdx) PAW.Left_y(endIdx)];
                            end
                            
                            distance=...
                                sqrt(  ((endpt(1)-startpt(1))^2) + ...
                                ((endpt(2)-startpt(2))^2)   ...
                                )/pxPerCm;
                            kinematics.(paws{i}).(currSegName).eucleadianDistance(row)= distance;
                            
                        case 'totalDistance'
                            
                            totalDistance=0;
                            for frame=startIdx:endIdx-1
                                
                                switch paws{i}
                                    case 'Right'
                                        startpt=[PAW.Right_x(frame) PAW.Right_y(frame)];
                                        endpt=[PAW.Right_x(frame+1) PAW.Right_y(frame+1)];
                                        
                                    case 'Left'
                                        startpt=[PAW.Left_x(frame) PAW.Left_y(frame)];
                                        endpt=[PAW.Left_x(frame+1) PAW.Left_y(frame+1)];
                                end
                                
                                totalDistance =...
                                    totalDistance + ...
                                    (sqrt(   ((endpt(1)-startpt(1))^2) + ...
                                    ((endpt(2)-startpt(2))^2)   ...
                                    )/pxPerCm);
                            end
                            
                            kinematics.(paws{i}).(currSegName).totalDistance(row)= totalDistance;
                            clear totalDistance
                            
                            
                        case 'movementTime'
                            
                            time=...
                                (PAW.Time_uSec(endIdx)-PAW.Time_uSec(startIdx))/(1e6);
                            if time < 0
                                disp("neg time fault")
                            end
                            
                            kinematics.(paws{i}).(currSegName).movementTime(row)= time;
                            
                        case 'pathCircuitry'
                            %pathCircuitry=euDist/totalDist
                            %increase from 0.0 to 1.0 = more direct path
                            
                            kinematics.(paws{i}).(currSegName).pathCircuitry=...
                                kinematics.(paws{i}).(currSegName).eucleadianDistance ./ kinematics.(paws{i}).(currSegName).totalDistance;
                            
                        case 'avgSpeed'
                            kinematics.(paws{i}).(currSegName).avgSpeed=...
                                kinematics.(paws{i}).(currSegName).eucleadianDistance./kinematics.(paws{i}).(currSegName).movementTime;
                            
                    end
                end
            end
        end
    end
end









end

