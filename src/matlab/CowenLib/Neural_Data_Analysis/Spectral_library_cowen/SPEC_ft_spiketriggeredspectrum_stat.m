function [out,spike] = SPEC_ft_spiketriggeredspectrum_stat(TS_uS,freq_oi,LFP)
% THIS IS A MUCH CONDENSED VERSION OF THE FT version. Does not need FT at
% all.
% this presupposes spike already fourier decomposed. 
% TODO: Read paper again. I think I grasp enough about the code for now.
% With another runthrough with the paper, I think I can get this done.
%
% TODO: Need to figure out how the decomposition to fft is done.
% For now, assume we will only choose one channel at a time.
% INPUTS - if this was the actual FT version...
% cfg = 
% 
%   struct with fields:
% 
%           method: 'ppc0'
%     spikechannel: 'sig002a_wf'
%          channel: {3×1 cell}
%      avgoverchan: 'unweighted'
%           timwin: 'all'
%          latency: [0.3 2.198]
% stsConvol = 
% 
%   struct with fields:
% 
%          lfplabel: {4×1 cell}
%              freq: [20 30.12 40.323 50 60.976 71.429 80.645 89.286 100]
%             label: {'sig002a_wf'  'sig003a_wf'}
%     fourierspctrm: {[55028×4×9 double]  [32513×4×9 double]}
%              time: {[55028×1 double]  [32513×1 double]}
%             trial: {[55028×1 double]  [32513×1 double]}
%            dimord: '{chan}_spike_lfpchan_freq'
%         trialtime: [600×2 double]
%               cfg: [1×1 struct]

% Prior to calling, calls
% ft_spiketriggeredspectrum_convol
% this bins spikes into samples of 0's and 1's with indices corresponding
% to points int eh LFP signal. The big thing here is phase_est


% frequencies of interest
nSpikes = length(TS_uS);
freq_oi = [20        30.12       40.323           50       60.976       71.429       80.645       89.286          100];
cfg.spikesel = indices into fourier thing where spikes occurred.
spike.fourierspctrm = spike.fourierspctrm{unitsel}(cfg.spikesel,chansel,freqindx); % their code averages across channels so this can be done as well here or ignored.
spike.fourierspctrm = spike.fourierspctrm ./ abs(spike.fourierspctrm); % normalize the angles before averaging
nSpikes = sum(~isnan(spike.fourierspctrm));% fyi - one fourier for each spike

spike.time = the times in seconds of hte spike.s
spike.trial  = the trial id for each spike - but I don't have trials so i may have to window the data or just have one trial
out  = ppc(spike.fourierspctrm); % this is it - computes power in each frequency.



This is what it dumps out...
    freq = 

  struct with fields:

        time: 'all'
        ppc0: [-0.0088747 -0.0107 0.0032653 0.016043 0.0095038 0.030795 0.0070558 0.0092502 -0.005477]
     nspikes: [92 92 92 92 92 92 92 92 92]
    labelcmb: {'sig002a_wf'  'avgLFP'}
        freq: [20 30.12 40.323 50 60.976 71.429 80.645 89.286 100]
      dimord: 'chancmb_freq_time'
     
      
      
      


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION set 1 from  ft_spiketriggeredspectrum_convol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [spctrm,foi, numsmp] = phase_est(cfg,dat,time,fsample)

% Phase estimation function

% Determine fsample and set total time-length of data
if nargin<4
  fsample = 1./mean(time(2:end)-time(1:end-1)); % round off errors!
end
numsmp  = round(cfg.t_ftimwin .* fsample);
numsmp(~mod(numsmp,2)) = numsmp(~mod(numsmp,2))+1; % make sure we always have uneven samples, since we want the spike in the middle
faxis         = linspace(0,fsample,numsmp);
findx         =  nearest(faxis,cfg.foi);
[cfg.foi,foi] = deal(faxis(findx)); % this is the actual frequency used, from the DFT formula
timwinSamples = numsmp;

% Compute tapers per frequency, multiply with wavelets and compute their fft
switch cfg.taper
  case 'dpss'
    % create a sequence of DPSS tapers
    taper = double_dpss(timwinSamples, timwinSamples .* (cfg.tapsmofrq ./ fsample))';
    taper = taper(1:(end-1), :); % removing the last taper

    % give error/warning about number of tapers
    if isempty(taper)
      error('%.3f Hz: datalength to short for specified smoothing\ndatalength: %.3f s, smoothing: %.3f Hz, minimum smoothing: %.3f Hz',...
        cfg.foi, timwinSamples/fsample,cfg.tapsmofrq,fsample/timwinSamples);
    elseif size(taper,1) == 1
      warning('using only one taper for specified smoothing for %.2f Hz', cfg.foi)
    end

  case 'sine'
    taper = sine_taper(timwinSamples, timwinSamples .* (cfg.tapsmofrq ./ fsample))'; 
    taper = taper(1:(end-1), :);

  otherwise
    % create a single taper according to the standard window specification 
    if isempty(cfg.taperopt)
      taper = window(cfg.taper, timwinSamples)';
    else       
      try
        taper = window(cfg.taper, timwinSamples,cfg.taperopt)';
      catch
        error('taper option was not appropriate for taper');
      end
    end
end

% do some check on the taper size
if size(taper,1)==numsmp, taper = taper'; end

% normalize taper if there's 1 and all are positive
if size(taper,1)==1 && all(taper>=0)
  taper = numsmp*taper./sum(taper); % magnitude of cosine is now returned
end

%%%% fit linear regression for every datapoint: to remove mean and ramp of signal  
sumKern = ones(1,timwinSamples);
avgKern = sumKern./timwinSamples;
xKern   = timwinSamples:-1:1; % because of definition conv2 function
meanX   = mean(xKern);
sumX    = sum(xKern);

% beta1 =  (sum(x.*y) - sum(x)*sum(y)/n) ./ (sum((x-meanx).^2): standard linear regr formula
beta1 = (conv2(dat(:),xKern(:),'same') - sumX.*conv2(dat(:),sumKern(:),'same')/timwinSamples ) ./ sum((xKern-meanX).^2);
beta0 = conv2(dat(:),avgKern(:),'same') - beta1.*meanX; % beta0 = mean(dat) - beta1*mean(x)  

% DFT formula: basefunctions: cos(2*pi*k*[0:numsmp-1]/numsmp) and sin(2*pi*k*[0:numsmp-1]/numsmp)
% center the base functions such that the peak of the cos function is at the center. See:
% f = findx-1; ax = -(numsmp-1)/2:(numsmp-1)/2; y = cos(2*pi.*ax.*f/numsmp);figure, plot(ax,y,'sr'); 
% y2 = cos(2*pi.*linspace(-(numsmp-1)/2,(numsmp-1)/2,1000).*f/numsmp); 
% hold on, plot(linspace(-(numsmp-1)/2,(numsmp-1)/2,1000),y2,'r-')

% correcting for phase rotation (as with multitapering)
nTapers   = size(taper,1);  
indN      = -(numsmp-1)/2:(numsmp-1)/2;
spctrmRot = complex(zeros(1,1));
for iTaper = 1:nTapers
    coswav    =  taper(iTaper,:).*cos(2*pi*(findx-1)*indN/numsmp);
    sinwav    =  taper(iTaper,:).*sin(2*pi*(findx-1)*indN/numsmp);
    wavelet   = complex(coswav(:), sinwav(:));
    cosSignal = cos(2*pi*(findx-1)*indN/numsmp);
    spctrmRot = spctrmRot + sum(wavelet.*cosSignal(:));
end
phaseCor = angle(spctrmRot);

%%%% compute the spectra
nTapers = size(taper,1);  
indN    = -(numsmp-1)/2:(numsmp-1)/2;
spctrm = complex(zeros(length(dat),1));
for iTaper = 1:nTapers
    coswav  = taper(iTaper,:).*cos(2*pi*(findx-1)*indN/numsmp);
    sinwav  = taper(iTaper,:).*sin(2*pi*(findx-1)*indN/numsmp);
    wavelet = complex(coswav(:), sinwav(:));       
    fftRamp = sum(xKern.*coswav) + 1i*sum(xKern.*sinwav); % fft of ramp with dx/ds = 1 * taper 
    fftDC   = sum(ones(1,timwinSamples).*coswav) + 1i*sum(ones(1,timwinSamples).*sinwav); % fft of unit direct current * taper
    spctrm  = spctrm + (conv_fftbased(dat(:),wavelet) - (beta0*fftDC + beta1.*fftRamp))/(numsmp/2);           
                       % fft                       % mean            %linear ramp      % make magnitude invariant to window length                             
end
spctrm = spctrm./nTapers; % normalize by number of tapers
spctrm = spctrm.*exp(-1i*phaseCor);

% set the part of the spectrum without a valid phase to NaNs
n = (timwinSamples-1)/2;
spctrm(1:n) = NaN; 
spctrm(end-n+1:end) = NaN;

function [taper] = double_dpss(a, b, varargin)
taper = dpss(double(a), double(b), varargin{:});


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION set 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [P] = rayleightest(x)

n = sum(~isnan(x),1);
R = resultantlength(x);    
Z = n.*R.^2;
    
P = exp(-Z).*...
(1 + (2*Z - Z.^2)./(4*n) -(24.*Z - 123*(Z.^2) + 76*(Z.^3) - 9*(Z.^4))./(288*n.^2)); %Mardia 1972

function [resLen] = resultantlength(angles)

n = sum(~isnan(angles),1);
resLen = abs(nansum(angles,1))./n; %calculate the circular variance

function [y] = ppc(crss)

dim = 1;
dof = sum(~isnan(crss),dim);
sinSum = abs(nansum(imag(crss),dim));
cosSum = nansum(real(crss),dim);
y = (cosSum.^2+sinSum.^2 - dof)./(dof.*(dof-1));     
 
function [angMean] = angularmean(angles)

angMean = angle(nanmean(angles,1)); %get the mean angle


function [cfg] = trialselection(cfg,spike)

% get the number of trials or change DATA according to cfg.trials
nTrials = size(spike.trialtime,1);
if  strcmp(cfg.trials, 'all')
  cfg.trials = 1:nTrials;
elseif islogical(cfg.trials) || all(cfg.trials==0 | cfg.trials==1)
  cfg.trials = find(cfg.trials);
end
cfg.trials = sort(cfg.trials(:));
if max(cfg.trials)>nTrials, warning('maximum trial number in cfg.trials should not exceed length of DATA.trial')
end
if isempty(cfg.trials), error('No trials were selected');
end

function m = nansum(x,dim)

% Find NaNs and set them to zero
nans = isnan(x);
x(nans) = 0;

if nargin == 1 % let sum deal with figuring out which dimension to use
    % Count up non-NaNs.
    n = sum(~nans);
    n(n==0) = NaN; % prevent divideByZero warnings
    % Sum up non-NaNs, and divide by the number of non-NaNs.
    m = sum(x);
else
    % Count up non-NaNs.
    n = sum(~nans,dim);
    n(n==0) = NaN; % prevent divideByZero warnings
    % Sum up non-NaNs, and divide by the number of non-NaNs.
    m = sum(x,dim);
end
