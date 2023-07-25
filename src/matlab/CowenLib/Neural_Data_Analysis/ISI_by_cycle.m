function  [ISI] = ISI_by_cycle(SP1,SP2)
% INPUT is a 3 col matrix. 
%       col 1 is the timestamp of the cell
%       col 2 is the phase as some measure of angle
%       col 3 is the cycle. Any identifier may be used as long as it stays constant
%          throughout a cycle: (1 1 1 2 2 3 3 3, etc..)
%
% OUTPUT is a 2 col matrix
%       each is a vector of intervals between pairs of spikes (one on each cell) that occur
%          within a cycle. The first col is the interval in real time, the second
%          in phase angle. There will be negative ISIs when spikes on cell 2 (SP2) fire
%          before cell 1 within a cycle. the third column identifies the cycle the pair was found.

% Loop thought the spikes, finding neurons that fire within the same cycle.
ISI = [];
SP1 = sortrows(SP1);
SP2 = sortrows(SP2);
cycles = unique(SP1(:,3));
for cycle = cycles(:)'
    c1_idx = find(SP1(:,3)==cycle);
    c2_idx = find(SP2(:,3)==cycle);
    if isempty(c1_idx) | isempty(c2_idx)
        % Do nothing
    else
        ISI = [ISI; (SP2(c2_idx(1),1) - SP1(c1_idx(1),1)), (SP2(c2_idx(1),2) - SP1(c1_idx(1),2)) , cycle];
    end
end


if ~isempty(ISI)
    fprintf('Found %d ISIs, mean: %6.3f, std: %6.3f realtime, mean: %6.3f, std: %6.3f phasetime.', ...
        num2str(size(ISI,1)), num2str(mean(ISI(:,1))), num2str(std(ISI(:,1))), ...
        num2str(mean(ISI(:,2))), num2str(std(ISI(:,2))));
else
    disp('No pairs found.')
end

