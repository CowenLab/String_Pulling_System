function [cmpac, cmpacp] = SPEC_cross_fq_coupling_comodulogram(values,sFreq,lf_range,hf_range,num_iter,GOODIX,USE_GPU)
% Ignore phase - just explore coupling between a range of low frequencies
% and high frequencies.
% This maps on pretty will to others like Colgin's and Canolty's approach.
% The dupre2017 paper explores a number of method and their python
% implementtion is MUCH faster than my implementation here. They also used
% all other leading methods.
if nargin < 6
    GOODIX = [];
end
if nargin < 7
    USE_GPU = false;
end
if nargin < 5
    num_iter = 100;
end
method = 1;
wavelet_size = 5;% From Cohen recommendation -see book.
PLOT_IT = true;

ALL_AT_ONCE = false; % this is about twice as fast for some datasets.
if length(values)*length(lf_range) * length(hf_range) < 10e8 % A guess based on a limited sample
    ALL_AT_ONCE = true; % this is about twice as fast for some datasets.
end

cmpac = NaN(length(hf_range), length(lf_range));
% tic
if ALL_AT_ONCE
    % This may be better if you have values is not too big. Otherwise,
    % avoid - memory issues.
    % Note- don't bother restricting to just significant LF power as these
    % values are always sig for some reason.
    [LF_phase] = SPEC_waveletdecomp(lf_range,values,sFreq,wavelet_size,USE_GPU);
    [~,HF_power] = SPEC_waveletdecomp(hf_range,values,sFreq,wavelet_size,USE_GPU);
    % Get rid of unwanted values.
    if ~isempty(GOODIX)
        LF_phase = LF_phase(:,GOODIX);
        HF_power = HF_power(:,GOODIX);
    end
    
    for iL = 1:length(lf_range)
        for iH = 1:length(hf_range)
            [cmpac(iH,iL)] = SPEC_cross_fq_coupling_pac_no_window(LF_phase(iL,:),HF_power(iH,:),num_iter,method);
        end
        fprintf('>')
    end
    disp('done')
else
    for iL = 1:length(lf_range)
        [LF_phase] = SPEC_waveletdecomp(lf_range(iL),values,sFreq,wavelet_size,USE_GPU);
        if ~isempty(GOODIX)
        LF_phase = LF_phase(:,GOODIX);
        end
        for iH = 1:length(hf_range)
            % Compute the spectral pwers
            [~,HF_power] = SPEC_waveletdecomp(hf_range(iH),values,sFreq,wavelet_size,USE_GPU);
            if ~isempty(GOODIX)
                HF_power = HF_power(:,GOODIX);
            end
            [cmpac(iH,iL)] = SPEC_cross_fq_coupling_pac_no_window(LF_phase,HF_power,num_iter,method);
        end
        fprintf('.')
    end
    disp('done')
end
% toc
if PLOT_IT || nargin == 0
    clf
    imagesc(lf_range,hf_range,cmpac)
    xlabel('Low Hz')
    ylabel('Hi Hz')
    axis xy
    colorbar_label('Comod above permut')
    colormap(jet)
    pubify_figure_axis
end
