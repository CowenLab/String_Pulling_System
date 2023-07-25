function RunBatch(batchfile,prevRunMat,StartStep)
%
% RunBatch(batchfile)
%          or
% RunBatch(batchfile,prevRunMat,StartStep)
% 
% BBClust Batch run; Parses input lists from a text file 'batchfile' and 
% waveform templates from a matlab file "templ.mat", which needs to be in the current directory, 
% and processes all spike files in the list.
% The processing is logged in an output text file 'RunMMDDHHMM.log' with the date and
% time in the filename (to distinguish multiple runs).
% The function also saves all parameters gPar,fPar, def in a file 'RunMMDDHHMM.log' so 
% that a batch run can be reloaded and reprocessed after a certain step (e.g. after the cleaning 
% or the subsampling step). In this case 3 arguments need to be provided:
%
% INPUT: 
%   batchfile .... matlab string with the filename of the batch command file (usually Batch.txt)
%   prevRunMat ... matlab .mat file with saved gPar, fPar, def struct arrays from a previous run
%                  if some processing stages are to be skipped
%   StartStep  ... Step number (0,1...3) from which on processing shall be repeated.
%
% There are 3 processing steps:
%   StartStep       0 .... Coincidence Detection accross multiple files 
%                          (equivalent to full reprocessing)
%                   1 .... Subsampling
%                   2 .... Feature extraction
%                   3 .... BubbleClust run
%
% PL 2000


global gPar fPar def


c = clock;
BatchName = ['Run' num2str(c(2)) num2str(c(3)) num2str(c(4)) num2str(c(5))];
logname = [BatchName '.log'];
diary(logname);


disp(' ');
disp('==================================================');
disp(['COWEN VERSION Batch run: ' datestr(now)                       ]);
disp('==================================================');
disp(' ');

% process input
if nargin > 1
   if nargin ~= 3
      error('RunBatch takes one or three arguments');
      help RunBatch
   end
   % resume processing at stage StartStep: load previous gPar,fPar and def
   load(prevRunMat);
   StartAtStep = StartStep;
else
   % only one input argument: start from scratch ....
   [gPar,fPar,def] = ParseBatchFile(batchfile);
   StartAtStep = 0;
end

%go to processing directory
pushdir(gPar.ProcessingDirectory);

%%%%%%%%%%%%%%%%%%%%
%  STEP 0   
% Clean Spike files
%%%%%%%%%%%%%%%%%%%
disp(' ');
disp('==================================================');
disp(' Cleaning Spike files: '                           );
disp('==================================================');
disp(' ');

tmpl_fname = 'tmpl.mat';
disp([' Loading waveform template file: ' tmpl_fname ]); 
disp(' ');
load('tmpl.mat','-mat');
if ~exist('tmpl')
   error('Templates files did not load correctly!');
end


Nevents = min(20,length(gPar.FileList));   % minimum number of channels with coincidence
precision = 10;         % 10 msec time window for coincidences
if StartAtStep <= 0
   gPar = CleanSpikeFiles(gPar, fPar, Nevents, precision, tmpl);
end
save(BatchName, 'gPar', 'fPar', 'def');

%%%%%%%%%%%%%%%%%%%%%%%%%
%  STEP 1   
%subsample Cleaned Files
%%%%%%%%%%%%%%%%%%%%%%%%
if StartAtStep <= 1
   disp(' ');
   disp('==================================================');
   disp(' Subsampling Cleaned Spike files if necessary: '   );
   disp('==================================================');
   disp(' ');
   
   nFiles = length(gPar.CleanedFileNames);
   s_prefix = gPar.SubsampledFilesPrefix;
   s_postfix = gPar.SubsampledFilesPostfix;
   s_ext = gPar.SubsampledFilesExt;
   outdir = gPar.SubsampledFilesSubDir;
   if ~exist(outdir,'dir')
      eval(['! mkdir ' outdir]);
   end
   
   for i = 1:nFiles
      if fPar{i}.SubsampleMethod > 0
         fin_name = gPar.CleanedFileNames{i};
         gPar.SubsampledFileNames{i} =  fin_name;
         TT = LoadTT(fin_name);
         nSpikes_pre = length(Range(TT, 'ts'));
         ToNSpikes = fPar{i}.SubsampleToNSpikes;
         if nSpikes_pre > ToNSpikes 
            [path, infn, ext] = fileparts(fin_name);
            fout_name = [outdir filesep s_prefix infn s_postfix s_ext];
            gPar.SubsampledFileNames{i} = fout_name;
            chVal = fPar{i}.ChannelValidity;
            minTh = fPar{i}.SubsampleParameters(1);
            out_tsd = TruncateWaveForms(TT, chVal, tmpl, minTh,ToNSpikes);
            WriteTT(fout_name, out_tsd);
            nSpikes_post = length(Range(out_tsd,'ts'));
            ndiff = nSpikes_pre - nSpikes_post;
            disp([' Subsampling ' fin_name ' ---> ' fout_name ': removed ' num2str(ndiff) ' Spikes. '  ...
                  fout_name ' has ' num2str(nSpikes_post) ' spikes in total.' ]);  
            disp(' ');
         end%if
      end%if   
   end%for
      
      
   save(BatchName, 'gPar', 'fPar', 'def');
end%if STEP 1

%%%%%%%%%%%%%%%%%%%%%%%%%
%  STEP 2  
% make feature data files
%%%%%%%%%%%%%%%%%%%%%%%%%
if StartAtStep <= 2
   disp(' ');
   disp('==================================================');
   disp(' Creating FeatureData files: COWEN/Working VERSION' );
   disp('==================================================');
   disp(' ');
   
   files = gPar.SubsampledFileNames;
   nFiles = length(gPar.SubsampledFileNames);
   
   FeaturesToUse = {'energy','stdPC1','stdPC2','wavePC1','wavePC2','sw'};

   nFeatures = length(FeaturesToUse);

   nChFiles = 4;
   for i = 1:nFiles
      TT = LoadTT(files{i});
      ChVal = fPar{i}.ChannelValidity;
      ChIDs = find(ChVal);
      nChFiles = length(ChIDs);
      ttChannelValidity{i} = zeros(1,4);
      for ich = 1:nChFiles
         ttChannelValidity{i}(ChIDs(ich)) = 1;
      end%for
      
      FeatureData = [];

      FeatureNames = {};
      FeaturePar = {};

      ChannelValidity = ttChannelValidity{i};
      for iF = 1:nFeatures

         [nextFeatureData, nextFeatureNames, nextFeaturePar] = ...
            feval(['feature_', FeaturesToUse{iF}], TT, ChannelValidity);

         FeatureData = [FeatureData nextFeatureData];

         FeatureNames = [FeatureNames; nextFeatureNames];
         if isempty(nextFeaturePar), nextFeaturePar = 'empty'; end%if

         FeaturePar{iF} = nextFeaturePar;    
      end%for
      
      % normalize data to zero mean and unit variance
      [nSpikes,nF] = size(FeatureData);
      FD_av = mean(FeatureData);                % row mean vector
      FD_sd = std(FeatureData);                 % row std vector
      FeatureData =(FeatureData-repmat(FD_av,nSpikes,1))./repmat(FD_sd,nSpikes,1); % standardize data to zero mean and unit variance
      [fpath, fname, fext] = fileparts(files{i});
      FDfname = [fpath filesep fname '.fd'];
      save(FDfname, 'FeatureData', 'FeaturesToUse', 'ChannelValidity', 'FeatureNames', 'FeaturePar','FD_av','FD_sd', '-mat');
      gPar.FeatureDataFileNames{i} = FDfname;
      if(strcmpi(gPar.ClusterAlgorithm,'KlustaKwik'))
          FDTextFname = [fpath filesep fname];
          WriteFeatureData2TextFile(FDTextFname, FeatureData);
          gPar.FeatureDataFileNames{i} = FDTextFname ;
      end
      gPar.FeatureDataNumberOfSpikes{i} = nSpikes; 
      disp([ files{i} ' ---> ' gPar.FeatureDataFileNames{i}]);
   end%for
   
   save(BatchName, 'gPar', 'fPar', 'def');
end%if STEP 2

%%%%%%%%%%%%%%%%%%%%%%%%%
%  STEP 3  
% run BubbleClust 
%%%%%%%%%%%%%%%%%%%%%%%%%
if StartAtStep <= 3
   
   disp(' ');
   disp('==================================================');
   disp(' run BubbleClust on FeatureData files: '           );
   disp('==================================================');
   disp(' ');
   
   nFiles = length(gPar.FeatureDataFileNames);
   for i = 1:nFiles
       IN = gPar.FeatureDataFileNames{i};
       if(strcmpi(gPar.ClusterAlgorithm,'KlustaKwik')) 
           file_no = 1;
           parameter_string = '';
           [status, result] = dos(['Z:\matlab\bin\KlustaKwik.exe ' IN ' ' num2str(file_no) ' ' parameter_string ]); 
           disp(status);
           disp(result);
           
       elseif(strcmpi(gPar.ClusterAlgorithm,'BBClust')) 
           [fpath, fname, ext] = fileparts(IN);
           OUT = [fpath filesep fname];
           nSpikes = gPar.FeatureDataNumberOfSpikes{i};
           NNat5k = fPar{i}.NN;
           NN = max(15,floor(NNat5k*0.0046*sqrt(nSpikes)));    % scaling of NN smoothing proportional to sqrt(nSpikes)
           COMMAND = ['! BubbleClust -fd ' IN ' -prefix ' OUT ' -nn ' num2str(NN)]; 
           disp(' ');
           disp(COMMAND);
           eval(COMMAND);
           [fpath, fname, fext] = fileparts(IN);
           dos(['del ' fpath filesep '*_nn.dat']);
       end%if
       disp(' ')
   end
end%if STEP 3

disp(' ');
disp('==================================================');
disp([' End of Batch run: ' datestr(now)                 ]);
disp('==================================================');
disp(' ');


popdir;
diary off;




%===============================================================================
function WriteFeatureData2TextFile(file_name, FeatureData)
%
% write featuredata from memory to a text file for input into KlustaKwick.exe
%
file_no = 1;
fid = fopen([ file_name '.fet.' num2str(file_no)],'w');
[n_points, n_features] = size(FeatureData);
fprintf(fid,'%3d \n',n_features);
for ii = 1:n_points
    fprintf(fid,'%f\t',FeatureData(ii,:));
    fprintf(fid,'\n');
end
fclose(fid);


