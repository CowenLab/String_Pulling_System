function [featureCallList, ValidChannels] = FeatureFileNames(fn)
% 
% extract the features and the valid Channels from MClust's FeatureNames
%
% INPUT: fn ... cell array of feature name strings as provided by MClust
% 
% OUTPUT: 
%     featureCallList ..... cell array of 'feature_name.m' function names
%     ValidChannels ... boolean [4 1] array of switched on (1) and off (0) channels
%
%
% WARNING: relies heavily on naming convention of MCLUSTS feature names!
%          If all included features  don't stick to MClust's convention
%          of 'fname: channelID' ALL channels are included!!

% CCC: PL
%%%

ValidChannels = [0; 0; 0; 0];

%%% Create LookUp table with feature file names and feature 'titles' in MClust.
%%% Currently, new features have to be include here by hand!!! SORRY!!!
%%%
%   FLAG          FEATURE TITLE             FILE NAME (excluding: feature_)
ff(1) = 0;     ft{1} = 'Area';           ffn{1} = 'area'; 
ff(2) = 0;     ft{2} = 'energy';         ffn{2} = 'energy';
ff(3) = 0;     ft{3} = 'Peak/Valley';    ffn{3} = 'p2v_ratio';
ff(4) = 0;     ft{4} = 'Peak';           ffn{4} = 'peak';
ff(5) = 0;     ft{5} = 'SW';             ffn{5} = 'sw';
ff(6) = 0;     ft{6} = 'time (ts)';      ffn{6} = 'time';
ff(7) = 0;     ft{7} = 'valley';         ffn{7} = 'valley';
ff(8) = 0;     ft{8} = 'waveform';       ffn{8} = 'waveform';
ff(9) = 0;     ft{9} = 'wavePCA';        ffn{9} = 'wavePCA';
% Look, I am assuming everybody uses PCAE. Please forgive me.
ff(10)= 0;     ft{10}= 'wavePC1';        ffn{10}= 'wavePCAE';
ff(11)= 0;     ft{11}= 'wavePC2';        ffn{11}= 'wavePCAE';
ff(12)= 0;     ft{12}= 'wavePC3';        ffn{12}= 'wavePCAE';
ff(13)= 0;     ft{14}= 'wavePC4';        ffn{14}= 'wavePCAE';
ff(14)= 0;     ft{13}= 'wavePCVM';       ffn{13}= 'wavePCVM';
ff(15)= 0;     ft{15}= 'wavePCAE';        ffn{15}= 'wavePCAE';

for line = 1:length(fn)
   [fTitle, rest] = strtok(fn{line},':');
   
   %--- find fTitle in lookup table and set corresponding flag
   i = strmatch(fTitle,ft,'exact');
   if ~i
      error(['ExtractFeaturesAndChannels could not find the feature: ' fTitle]);
   end%if
   ff(i) = 1;
   
   %--- extract channel
   if rest
      chNum = str2num(rest(2:end));
      if (chNum>=1 & chNum<=4)
         % assume this channel was selected as Valid Channel
         ValidChannels(chNum) = 1;
      end%if
   end%if
end%for line


if ~sum(ValidChannels)
   error([' Could NOT identify any valid channel' ... 
      'in .cluster file!!! Include Features with channel ID!!']);   
end%if

%--- create a sorted featureCallList
featureCallList = unique(cellstr(sortrows(char( ffn(find(ff)) )))); 

