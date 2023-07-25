%% prepare sequences of tones for presentation to rats
%
%  Cowen 2009, JRI 2009

sf = 44100;                 % sample frequency (Hz)
d = 0.4;                    % duration (s)
gapdur = d/4;               % gap between tones (* different from before??)
rise = 0.025;               % risefall
nSounds = 5

% Create tone bursts (they sound crappy though)
for ii = 1:nSounds
    cf = 1500*(ii);              % carrier frequency (Hz)
    FQ(ii) = cf;
    %n = sf * d;                 % number of samples
    %s = (1:n) / sf;             % sound data preparation
    %snd{ii} = sin(2 * pi * cf * s);   % sinusoidal modulation
    %sound(snd{ii}, sf);               % sound presentation
    burst{ii} = toneburst(cf, d, [], sf, 0.025,'sine'); %JRI's func
end
blanksound = 0*burst{1};
gapsound = 0*toneburst(cf, gapdur, [], sf, 0.025,'sine');

%% sequence patterns
% Share a common central element. Is the common element represented differently?
seq = [1 2 3 4 5;
       5 4 3 2 1;
       4 2 3 1 5];
     
%% generate the sounds
for iS = 1:size(seq,1),
  stim{iS} = [];
  stim_missing3{iS} = [];
  for iT = 1:size(seq,2),
    stim{iS} = cat(2,stim{iS},burst{seq(iS,iT)}, gapsound);
    if iT==3,
      stim_missing3{iS} = cat(2,stim_missing3{iS},blanksound, gapsound);
    else
      stim_missing3{iS} = cat(2,stim_missing3{iS},burst{seq(iS,iT)}, gapsound);
    end
  end
end

%%
save Markov_Tones_sounds.mat stim_missing3 stim sf seq FQ