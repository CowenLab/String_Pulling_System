%% Test the alignment of the timestamps from the TRACKER AND the event
%% file.
%
% There are many ways to do this. My first attempt at finding the degree to
% which the position time and the tracker time corresponded was through:
%
% 1) turn the headstage on and off. This creates an artifact in the CSC
% channel and ALSO causes the position tracker to trigger on and off. I
% then manually go through the CSC and position tracking data and use
% ginput to mark the point at which the CSC artifact began and the time the
% position tracking indicated a point > 0. This analysis gave me an offset
% between the tracker data and the CSC data of 144224 usec. Quite
% substantial. I am not sure if this offset is biased a little as there 
% may be a difference between the camera/cheetah system registering an 
% on/off signal vs. registering a change in position - but overall this 
% like a reasonable approach. 
%
% 2) I had the zbasic running so that it was detecting and timestamping
% event. I then took a glowing tracker ball and while I was recording, I
% slammed the ball into the start_trial pressure switch. I again used ginput 
% to mark the time at which the event code was sent and the time that the
% position changed (indicating that I hit the pressure switch). Using this
% approach, I got an offset of 60000 usec. A big difference. BUT this is an 
% underestimate as there is also an offset built into the step
% sensor as the sensor needs to debounce the noisy step signal before it
% send it off to cheetah. Consequently, the event timestamp is actually
% occuring a little later than the actual step so this isn't entirely
% valid. I need to quantify this offset as well. For my Effort data, this event
% time offset should not be a factor as it is not used to align position  
% (I better double check this though).l Instead I use a virtual infrared LED
% as the trigger.

% New way:
% EVENT OFFSET DETERMINATION: 
%  There are two offsets that are important:
%   1) The builtin Cheetah offset: any delay that is a result of the
%   cheetah harware not perfectly aligning the CSC data with the event
%   data.
%   2) Delay built into the microcontroller - debouncing and other stuff -
%   that causes the event pulse triggered by say the touch pad to yield an
%   event in the cheetah system. NOTE: This offset would ONLY apply to
%   debounced signals from the touchpads and not from other events like
%   solenoid delivery. These offsets would have to be tested separately but
%   are likely to be near zero.
%
%  DETERMINATION: SPlit the event line out so that one line goes to a free CSC channel
%  and the other line goes to the event log. Write a line of code in the Zbasic 
%  program within the debouncer that sends out a signal THE FIRST time the
%  trigger is pressed. Turn the CSC sampling way up - say 30000Hz. 
%
%  OFFSET 1: measure the time difference between the manually identified TTL 
%  pulses in the CSC and the times of the events in the event file. THIS IS 
%  the CHEETAH HARDWARE OFFSET between events and the neural data. Very
%  important to know. Hopefuly there is no offset here. 

%  OFFSET 2: Compare this pre-trigger-pre-debounce value (measured in the CSC and event file) 
%  with the value after the true signal is registered (the pulse series that marks an event. 
%
% POSITION OFFSET DETERMINATION:
%  Although I agree in general with the headstage switching approach used
%  above, another way would be to attach an accelerometer to the headstage.
%
% If all is well, then the difference in the offsets that I observed
% between the step trigger and the position tracker will be due to the
% combination of the cheetah hardware offset + the Z basic debounce offset.
%

OFFSET.touchpad_touch_to_event_pulse_from_zbasic_msec = 42; % From using the oscilliscope I measured the time between the artifact from touching the trigger pad to the time the first pulse was emitted for the event code. The delay was ~42 msec - of course there is some slop in this.
OFFSET.position_to_csc_from_flicker_headstage_msec = 144.224; % From looking at artifact on CSC channel.
OFFSET.position_to_csc_from_inertial_measure_msec = nan; % Put inertial sensor on tracker ball and sent to CSC and compared this reading to position reading. Hopefully this is similar to the flicker measure otherwise I will be confused. This is a sanity check.
OFFSET.event_port_to_CSC_msec= 0; % The offset from sending a pulse to the CSC and simultaneously sending it to the event trigger. They should be identical and no offset but this is to double check this. I tested this by sending simultaneous signals to the CSC channel and to the event port - pretty much simultaneous.
OFFSET.position_to_trigger_touchpad_usec = 55; % from moving ball to the touchpad, bonking the touchpad, and triggering an event and then comparing this to the time the accleration changed in the position data (with no offset adjustment). Note,  

% Time from touching trigger pad to an event on cheetha.
pad_to_cheetah = OFFSET.position_to_trigger_touchpad_usec + OFFSET.touchpad_touch_to_event_pulse_from_zbasic_msec;
unexplained_time_msec = OFFSET.position_to_csc_from_flicker_headstage_msec - pad_to_cheetah;

% This leaves 47 msec of unexplained time. Hmmm. I still need to identify
% any delay in the cheetah timestamping.

% load events
[EVT.Nev.AllEvtTimestamps, EventIDs, EventCodes, Extras, EventStrings] = Nlx2MatEV( 'Events.Nev', [1 1 1 1 1], 0, 1, [] );

% load position

if exist('VT1.Nvt','file')
    disp('Processing position data.')
    POS = position_from_nvt();
    %POS_orig = POS;
    %POS = Clean_position_data(POS,15,[1 20]);
    % Correct the tracker offset. (See Analysis_Labbook_1.doc for my
    % analysiis of this offset.
    offset_usec = 144224;
    %POS(:,1) = POS(:,1) - offset_usec;
    save('POS.mat','POS');
    
else
    load('POS.mat')
    disp('Found POS.mat instead of VT1.mat')
end


figure
subplot(3,2,1:4)
plot(POS(1:3:end,2),POS(1:3:end,3),'k.-','MarkerSize',1)

title([pwd ' offset usec: ' num2str(offset_usec)])

subplot(3,2,5:6)
plot(POS(1:3:end,1)/1e6/60,POS(1:3:end,2),POS(1:3:end,1)/1e6/60,POS(1:3:end,3))
xlabel('min')
axis tight
%%
figure
zPOS = Z_Scores(POS(:,2:3));
plot(POS(:,1),zPOS(:,1),POS(:,1),zPOS(:,2));
hold on
plot(zPOS(2:end,1),Z_Scores(diff(POS(:,2))),'r',POS(2:end,1),Z_Scores(diff(POS(:,3))),'m')
a = axis;
plot(EVT.Nev.AllEvtTimestamps,repmat(a(3),1,length(EVT.Nev.AllEvtTimestamps)),'.')
plot(EVT.Nev.AllEvtTimestamps,repmat(a(4),1,length(EVT.Nev.AllEvtTimestamps)),'.')
xlabel('usec')
plot([EVT.Nev.AllEvtTimestamps(:) EVT.Nev.AllEvtTimestamps(:)]',repmat(a(3:4),length(EVT.Nev.AllEvtTimestamps),1)',':')

% my estimates
52683
x = ginput(2);
x(2) - x(1)

% My estimates: 61872 52767
% New mean estimate: 57319.5

