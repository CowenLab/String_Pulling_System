function [phase,pow,filtsig,edge,convresphase_out] = SPEC_waveletdecomp(f,S,srate,width,USE_GPU,PLOT_IT)
%[phase,pow,filtsig] = waveletdecomp(f,S,srate,width)
%   returns phase, power (scaled to amplitude of input), and
%   the original signal filtered at each frequency
%   f = frequencies to analyze
%   S = signal
%   srate = sampling rate (hz)
%   width = wavelet width
% f = logspace(low,hi,100)

if nargin < 5
    USE_GPU = false; % use the gpu array
end
if nargin < 6
    PLOT_IT = false; % use the gpu array
end


if isa(S,'gpuArray')
    USE_GPU = true;
    disp('Using GPU')
end
if USE_GPU
    S = gpuArray(S);
end
% disp('This is  slow - about 2x slower than SPEC_cwt_cowen and matlab wavelet toolbox.')

PAD_DATA = false; PAD_SIZE = round(srate)*2; % The lowest we can possibly resolve is around .5 hz so 2 seconds of padding should be more than enough.

if nargin == 0
    % Validate the method
    t = 0:1/1e3:20; % 2 seconds of data
    y = chirp(t,0,20,200); % go from 1 to 250 hz over those n seconds.
    fq = 1:200;
    wv_sz = 4;
    %%
    
    [phase,pow,filtsig,edge] = SPEC_waveletdecomp(fq,y,1e3,wv_sz);
    subplot(4,1,1)
    plot(t,y);axis tight
    colorbar;
    
    subplot(4,1,2)
    imagesc(t,fq,pow)
    ylabel('Hz')
    xlabel('s')
    title(['wavelet ' num2str(wv_sz)])
    axis xy
    colorbar
    
    subplot(4,1,3)
    % Always good to keep in mind how much wavelets smear and distort high frequencies
    % - relative to sfft. Important for ripples!
    spectrogram(y,blackman(256),250,fq,1e3,'yaxis') % Blackman is nice-  seems to narrow the range a bit- better snr.
    title('spectrogram - fft')
    colormap(hot)
    subplot(4,1,4)
    
    [~,~,~,S]=spectrogram(y,blackman(256),250,fq,1e3); % Blackman is nice-  seems to narrow the range a bit- better snr.
    plot(linspace(0,20,Cols(S)),S([5 20 100],:),'b')
    yyaxis right
    plot(linspace(0,20,Cols(pow)),pow([5 20 100],:),'r')
    %     legend('spec','wavelet')
    
    return
    %%
end
    
if f(1) == 0
    disp('Frequency is zero - not possible. Converting to .5 Hz.')
    f(1) = 0.5;
end

if size(S,1)>1
    S = S'; % we want columns for data. 
end

if PAD_DATA
    z = zeros(1,PAD_SIZE,class(S));
    S = [z S z];
%     disp('padding')
end

if nargout > 1
    pow = NaN(length(f),length(S));
end

if nargout > 2
    filtsig = NaN(length(f),length(S),class(S));
    edge = false(length(f),length(S));
    convresphase_out = NaN(length(f),length(S),class(S));
end

phase = NaN(length(f),length(S));
wavetime=-3:(1/srate):3;% 2 seems arbitrary. Seems like we should use a value dependent on teh question.

for i = 1:length(f)
    wavef=f(i); % wavelet frequency
    % create wavelet
    w = 2*( width/(2*pi*wavef) )^2;
    mwave =  exp(1i*2*pi*wavef.*wavetime) .* exp( (-wavetime.^2)/w );
    % convolution variables
    halfwavsize = floor(length(wavetime)/2);
    Lconv = length(mwave) + length(S) -1;
    
    if USE_GPU 
        mwave = gpuArray(mwave);
        Lconv = gpuArray(Lconv);
        %         S = gpuArray(S);
    end

    mwavefft = fft(mwave,Lconv);
    % run convolution
    Sfft=fft(S,Lconv);
    convresphase = ifft(mwavefft .* Sfft ,Lconv);   
    convresphase = convresphase(halfwavsize:end-halfwavsize-1);
    if length(convresphase) < Cols(phase)
        convresphase(end+1) = 0;
    end
    
    if nargout > 4
        convresphase_out(i,:) = convresphase;
    end
    if USE_GPU
        phase(i,:)= gather(angle(convresphase/2));
    else
        phase(i,:)= angle(convresphase/2);
    end

    if nargout > 1
        % POWER
        %smooth edges
        halfwidth = round((srate*width)/(2*f(i)));
        convrespow = ifft((mwavefft./max(mwavefft)) .* Sfft ,Lconv);
        convrespow = 2*convrespow(halfwavsize:end-halfwavsize-1);
        if length(convrespow) < Cols(pow)
            convrespow(end+1) = 0;
        end
        x = ones(size(convrespow),class(convrespow));
        y = hanning(round(2*halfwidth));
        x(1:min(halfwidth,length(S))) = y(1:min(halfwidth,length(S)));
        if length(S)<round(2*halfwidth)
            x(end-round(length(S)/2)+1:end) = y(end-round(length(S)/2)+1:end);
        else
            x(end-halfwidth:end) = y(end-halfwidth:end);
        end
        % create power and phase
        if USE_GPU
          x = gather(x);
          convrespow = gather(convrespow);
        end
        pow(i,:) = x.*abs(convrespow).^2;

    end
    if nargout > 2
        filtsig(i,:)= x.*sign(real(convrespow)).*real(convrespow).^2;
    end
    if nargout > 3
        edge(i,x==1) = true;
    end
    %     pow(i,:) = abs(convrespow).^2;
    %     phase(i,:)= angle(convresphase/2);
    %     filtsig(i,:)= sign(real(convrespow)).*real(convrespow).^2;
end
%
if PAD_DATA
    phase = phase(:,PAD_SIZE+1:(end-PAD_SIZE));
    pow = pow(:,PAD_SIZE+1:(end-PAD_SIZE));
    if nargout > 2
        filtsig = filtsig(:,PAD_SIZE+1:(end-PAD_SIZE));
        edge = edge(:,PAD_SIZE+1:(end-PAD_SIZE));
        convresphase_out = convresphase_out(:,PAD_SIZE+1:(end-PAD_SIZE));
    end
end


if PLOT_IT
    t = (1:length(S))/srate;
    subplot(3,1,1)
    plot(t,S)
    axis tight
    subplot(3,1,2:3)
    imagesc(t,f,pow)
    ylabel('Hz')
    xlabel('s')
    axis xy
    
end

