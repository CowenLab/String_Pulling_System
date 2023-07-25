function phase = Phase_precession(ctsa_spikes,CR_tsd,PF_start_and_end_ts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function phase = Phase_precession(ctsa_spikes,CR_tsd,PF_start_and_end_ts,x_pos,y_pos)
%
% 
% INPUT:
%   ctsa_spikes - cell array of ts object (spike times)
%   CR_tsd - tsd object of the theta signal.
%   PF_start_and_end_ts - the start and end times of each segment of the record
%       that should be analyzed independently for phase precession. For instance, 
%       this could be the entry and departure times as the rat enters and leaves a PF
%       or the start and stop times of REM episodes.
%
% OUTPUT:
%   phase - a cell array of structures where each of the elements in a cell corresponds to each
%           timestamp in the ts object. This function adds to the structure created by 
%           phase_detector. The fields added are indicated by >>:
%
%     phase.time - the timestamps in the spike train.
%     phase.phase_id - an integer from 1-4. Each cycle is divided in 4 sections and phase ID
%                   corresponds to each of these segments.
%     phase.quarter_phase_time - Time of the nearest peak, zero cross, or trough.
%     phase.phase_count - Count of the phase (4 increments per phase then it starts again with a 1).
%     phase.cycle_count - Count of the cycles(4 counts per cycle.) starting from 1.
%     phase.ph_count_linked_to_phase - interpolated phase count. 
%     phase.interp_phasetime - the interpolated time (ts). Finds the spike time and then add 
%     phase.phase_angle - a number from 0 to 1 that specifies the phase angle (0 - 360 degrees).
%  >> phase.ZA_spikes - spike times for each run through the PF starting from the first spike.
%  >> phase.CA_spikes - CA spikes: are counted in phase counts (4/cycle) starting from 0. They are interpolated.
%                    For example, if the spike occured between phase count 43 and 44 then 
%                    the ZA spike would be 43.5.
%  >> phase.pass_no   - Keeps track of the pass through the PF.
%  >> phase.x         - The position of the animal (x) at each spike in time.
%  >> phase.y         - The position of the animal (y) at each spike in time.
%  
%  cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fh{1} = [];

if ~iscell(PF_start_and_end_ts)
    IN_TIMES = PF_start_and_end_ts;
    clear PF_start_and_end_ts;
    for cl = 1:length(ctsa_spikes)
        PF_start_and_end_ts{cl} = IN_TIMES;
    end
end

for cl = 1:length(ctsa_spikes)
    if isempty(PF_start_and_end_ts{cl}) | nargin <3
        PF_ctsa_spikes{cl} = ts([]);
    else
        PF_ctsa_spikes{cl} = Restrict(ctsa_spikes{cl},PF_start_and_end_ts{cl}(:,1),PF_start_and_end_ts{cl}(:,2));
    end
end

% Determine the phase of each spike in the record.
[phase] = Phase_detector(PF_ctsa_spikes, CR_tsd);
% Tack on some more information
for cl = 1:length(ctsa_spikes)
    phase{cl}.object_ID = cl;%get(ctsa_spikes{cl},'object_ID'); 
    phase{cl}.ZA_spikes = [];
    phase{cl}.CA_spikes = [];
    phase{cl}.pass_no   = [];
    if ~isempty(PF_start_and_end_ts{cl})
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Align timestamps on the timestamp of the first spike in each burst.
        %  this makes the first spike of a burst 0
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if ~isempty(phase{cl}.time) 

            nspikes = length(phase{cl}.time);
            phase{cl}.ZA_spikes = zeros(nspikes,1) * nan;
            phase{cl}.CA_spikes = zeros(nspikes,1) * nan;
            phase{cl}.pass_no   = zeros(nspikes,1) * nan; % Keeps track of the pass through the PF.
            % Align the spikes.
            for rr = 1:Rows(PF_start_and_end_ts{cl})
                sidx = binsearch(phase{cl}.time,PF_start_and_end_ts{cl}(rr,1));
                eidx = binsearch(phase{cl}.time,PF_start_and_end_ts{cl}(rr,2));
                if ~isempty(sidx) 
                    start = phase{cl}.time(sidx);
                    phase{cl}.ZA_spikes(sidx:eidx) = phase{cl}.time(sidx:eidx) - start;

                    start = phase{cl}.ph_count_linked_to_phase(sidx);
                    phase{cl}.CA_spikes(sidx:eidx) = phase{cl}.ph_count_linked_to_phase(sidx:eidx) - start;
                    phase{cl}.pass_no(sidx:eidx)   = rr;
                end
           end
        end
    end
end

