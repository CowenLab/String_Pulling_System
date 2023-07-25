function [OUT] = SPEC_cross_fq_coupling_comod_dupre2017(signal,sFreq,low_range, method, chunk_size, n_surrogates)
%% function [OUT] = SPEC_cross_fq_coupling_comod_dupre2017(signal,sFreq,low_range, method)
% Requires python and the pactools library installed and tested.
%  Requires that you have a C:\Temp directory on your computer.
%  Requires that the path to python is 'C:\ProgramData\Anaconda3\'
%
% Use Anaconda python and then follow the instructions on the pactools
% github website for install. You will need to figure out where the path is
% to the pythonw.exe. If the pactools install fails, you can also download
% the whole pactools project and subdirs from github and then, using the
% Anaconda command window, go to the root directory and run this...
%   >> python setup.py install
%
% See the pactools on github for more details. here are the methods.
% 'ozkurt', 'canolty', 'tort', 'penny', 'vanwijk', 'duprelatour', 'colgin', 
% 'sigl', 'bispectrum' 
%
% Cowen 2018 wrote this wrapper function.
% Uninformed opinions: duprelatour is nicest for better freq res. Tort has
% bad high freq resoluton and is slow. Canolty is good. Bispectrum is a bit
% strange.
% 
% Cowen 2020 - alowed chunking data. More testing. 
% NOTE: the python code by default dumps out 80 high frequencies bewween
% lowfq(max) and nyquist. (NOTE: pactools doc mistakenly says 40 bins. It's
% 80. Changing this is possible if we change the python code which would
% not be hard. 
%
% Started to work on surrogate approach for confidence intervals. Problem:
% the output does not seem reliable- even for simulated data. Makes no
% sense. Could it be my artificial data? I tried it with artificial data -
% seems to kinda work. I think that the issue is that the artifial data I
% created has a fixed perfect period and so regardless of the shifting, you
% still get CFC? Maybe. In contrast, real data - the frequency and period
% varies considerably so that shifting the phase or amplitude should have
% a much larger effect. That's my guess anyway. 
% THe bootstrapping is also obscenely slow (20 min for maybe 100) and so
% not practical for most situation.


% This Assumes only one Anaconda installation but if more, it just chooses the first. 
d = dir('C:\ProgramData\Anaconda*');
ppath = [fullfile('C:\ProgramData\', d(1).name) '\'];

tmppath = 'C:\Temp\';

% Defaults.
if nargin < 6
    n_surrogates = -1;
end
if nargin < 5
    chunk_size = [];
end
if nargin < 4
    %     ozkurt', 'canolty', 'tort', 'penny', 'vanwijk', 'duprelatour', 'colgin', 'sigl', 'bispectrum'
    method = 'duprelatour';
%     method = 'tort';
end
if nargin ==0 
    % For testing: Generate CFC between 2 frequencies.
    sFreq = 200;
    lowfq = 11; highfq = 71;
    low_range = 1:.5:15;
    method = 'duprelatour';

    dur_sec = 50;
%     n_surrogates = 30; % BEWARE: this output does not make sense with simulated data.
    n_surrogates = -1; % -1 to not do bootstrapping.
    
    [L1, INFO] = Artificial_LFP(sFreq, dur_sec, [lowfq], [0], 0.01 );
    [L2] = Artificial_LFP(sFreq, dur_sec, [highfq], [0], 0.01 );
    signal = L1 + abs(L1 > 0).*(L2*.5);
    signal = signal + randn(size(signal))*.8;
    figure; plot(signal)
end
% NOTE: they screwed up in that range is not a range but a list of
% frequencies.
OUT.CM = nan(80,length(low_range));
OUT.low_fq_range = low_range;
OUT.high_fq_range = linspace(low_range(1),sFreq/2,80);
OUT.method = method;
if ~isempty(chunk_size)
    % break up the data into smaller chunks and average. 
    % This can be considerably faster than doing it all at once.
    edges = 1:chunk_size:length(signal);
    if length(edges) == 1
        edges = [1 length(signal)];
    end
    edges(end) = length(signal);
    CM = nan(80,length(low_range),(length(edges)-1)); 
    for ii = 1:(length(edges)-1)
        [OUT] = SPEC_cross_fq_coupling_comod_dupre2017(signal(edges(ii):edges(ii+1)),sFreq,low_range, method);
        % TODO- add n_surrogates?
        CM(:,:,ii) = OUT.CM;
        fprintf('.%d/%d',ii,(length(edges)-1))
    end
    fprintf('\n')
    OUT.CM = nanmean(CM,3);
    OUT.CM_all = CM;
    OUT.edges = edges;
    %     figure;imagesc(OUT.low_fq_range,OUT.high_fq_range, mean(CM,3));axis xy
    return
end
%%


signal = signal(:)'; % ensure it's a horizontal vector.
signal = signal(~isnan(signal));
if length(signal) < sFreq*2
    return
end
save(fullfile(tmppath,'cm_signal.mat'),'signal','sFreq','low_range','method','n_surrogates','-v6');
if exist('C:\Temp\cm_out.mat','file')
    delete('C:\Temp\cm_out.mat')
end
pth = which('SPEC_cross_fq_coupling_comod_dupre2017');
pth(end-1:end+1) = '.py'; % there is python code of the same name in this dir.
cmd = ['"' ppath 'pythonw.exe" "' pth '"'];
%  system (cmd, '-echo') % run the python code.
[a,b] = system(cmd); % run the python code.
if exist('C:\Temp\cm_out.mat','file')
    OUT = load('C:\Temp\cm_out.mat'); % load the result and spit them out
else
    b
    error('Python code failed to complete.')
end
OUT.CM = OUT.CM'; % like most comodulograms.
if n_surrogates > 0
    OUT.CMz = OUT.CMz'; % like most comodulograms.
end

if nargout == 0
    figure
    imagesc(OUT.low_fq_range,OUT.high_fq_range,OUT.CM)
    xlabel('Low Frequency (Hz)')
    ylabel('High Frequency (Hz)')
    title (method)
    axis xy
    colorbar
    colormap(viridis) % viridis is the same color map as in the python code.
    
    if n_surrogates > 0
        figure
        imagesc(OUT.low_fq_range,OUT.high_fq_range,OUT.CMz)
        xlabel('Low Frequency (Hz)')
        ylabel('High Frequency (Hz)')
        title ('Z SCORES SURROGATE')
        axis xy
        colorbar
        colormap(viridis) % viridis is the same color map as in the python code.
    end

end