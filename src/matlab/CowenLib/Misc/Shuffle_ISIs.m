function out = Shuffle_ISIs(spikes,method,jitter_std)
% Go through each cell in a ctsa and randomly shuffle the 
% spike times keeping the same ISI distribution.(so same freq)
% NOTE: If you have interval data, use Restrict_and_shuffle.
%
% INPUT
%   a vec of timestamps or a cell array of ts objects or a cell array of timestamp vectors
% OUTPUT
%   a vec of timestamps or a cell array of ts object shuffled or a cell array of timestamp vectors
%
% cowen -- improvement over Shuffle_ISIs_in_ctsa. More general.
if nargin < 2 
    method = 'no_replacement';
%     method = 'logn';
end
if nargin < 3
    jitter_std = []; % add some jitter if not empty.
end

if iscell(spikes)
    nCells = length(spikes);
    for ii = 1:nCells
        out{ii} = Shuffle_ISIs(spikes{ii},method);
    end
else
    is_ts = 0;
    if isa(spikes,'ts')
        spikes = Data(spikes);
        is_ts = 1;
    end
    
    if isempty(spikes)
        out = [];
        return
    end
    if length(spikes) == 1
        out = spikes;
        return
    end
    spikes = sort(spikes);

    D = diff(spikes);
    % Shuffle the ISIs
    switch method
        case 'with_replacement'
            D = D(ceil(length(D).*rand(1,length(D))));
        case 'no_replacement'
            D = D(randperm(length(D)));
        case 'gamma'
            % fit a gamma (cont of poisson) to the dist of ISIs
            % hippocampal data just does not match this very well..
            % A start but real spikes are mostly below gamma estimates for
            % most of the psd. Not that accurate for hippocampus.
            params = gamfit(D);
            D = gamrnd(params(1),params(2),size(diff(D)));
        case 'logn'
            % log normal
            params = lognfit(D);
            D = lognrnd(params(1),params(2),size(diff(D)));
            D = abs(D);
        otherwise
            error('Improper method')
    end
    if ~isempty(jitter_std)
        Dorig = D;
%         D = D + randn(size(D))*jitter_std;
        D = D + (rand(size(D))-.5)*jitter_std;
        D(D<0) = Dorig(D<0); % Just in case some went negative.
    end
    % Make those shuffled ISIs into spike times.
    lD = length(D);
    start_time = spikes(1) + D(ceil(rand(1,1)*lD)) - D(ceil(rand(1,1)*lD));
    out = sort([start_time; cumsum(D) + start_time]);
    % Add one more point so that you get the same number of spikes out.
    %out(end+1) = out(end) + D(ceil(rand(1,1)*lD));
    if is_ts
        out = ts(out);
    end
end

