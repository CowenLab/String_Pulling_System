function RemoveCoincidenceSE(files, Nevents, precision_us)
% files: cell array of file names and paths
%
%function gPar = CleanSpikeFiles(gPar, fPar, Nevents, precision, tmpl)
% 
% Cleans list of SE files and generates TT files with Coincidences and
% bad waveforms removed
%Nevents = 20;

% files = gPar.FileList;
[thepath,thename,theext] = fileparts(files{1});
CleanedSE = 'CleanedSEtoMAT';
fixed_prefix = gPar.CleanedSpikeFilesPrefix;
fixed_postfix = gPar.CleanedSpikeFilesPostfix;
fixed_ext = theext;

indir = thepath;
outdir = fullfile(thepath,CleanedSE);
if ~exist(outdir,'dir')
   eval(['! mkdir ' outdir]);
end

TST = [];
id = [];
idx = [];


for ii = 1:length(files)
    [T,b]=nlx2MatSE(files{ii});
    %[T, ScNumbers, CellNumbers, Params, DataPoints] = nlx_SERead(files{ii});
    TST = [TST T];
    id = [id ii * ones(1, length(T))]; % Which tt file it came from.
    idx  = [idx 1:length(T)];
end

[TST, I] = sort(TST);
id = id(I);
idx = idx(I);

   
Noise_idx = FindCoincidences(TST, Nevents, precision_us/100); % Multiply by 100 to convert to times in 
% We now have the indices of the spikes that must be removed. Load each tfile and remove them.
% id (in cell array) of the spikes to remove.
id = id(Noise);
idx = idx(Noise);

for ii = 1:length(files)
   [the_path, the_name, the_ext] = fileparts(files{ii});
   newfile = fullfile(the_path,,[the_name '.mat']);
   good_times_idx = find(id ~= ii);
   % Read in the entire SE file (waveform as well).
   [T,b,sd,s,WV]=nlx_readSE(files{ii});
   noriginalspikes = length(T);
   if ~isempty(good_times_idx)
       % We CANNOT DO THIS. IT'S STUPID!!! Creating  a tt file for SE data!
       %WriteSE(files{ii}, t, wv);
       T=T(good_times_idx);
       WV = WV(good_times_idx,:);
       save(newfile,'T','WV');
   else
       % Create an empty SE file.
       % WriteSE(files{ii}, [], []);
       T=[]);
       WV =[];
       save(newfile,'T','WV');
   end
   disp([' CleanSpikeFiles ' files{ii} ': removed ' num2str(noriginalspikes - length(good_times_idx)) ' coincidences, ' num2str(length(good_times_idx)) ' of ' noriginalspikes ' spikes remain.']);  
end

