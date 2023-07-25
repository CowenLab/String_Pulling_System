function RemoveCoincidenceSE(files, Nevents, precision_us, start_and_end_times,dest_dir)
% files: cell array of file names and paths
%
%function RemoveCoincidenceSE(files, Nevents, precision_us, start_and_end_times)
%  If 10 files have timestamps within 10 msec of each other, then remove these timestamps.
%
%
% Nevents = 20;
% NOT WORKING
% files = gPar.FileList;
if nargin < 4
    start_and_end_times = [];
    dest_dir = [];
end
if nargin < 5
    dest_dir = [];
end

[thepath,thename,theext] = fileparts(files{1});

TST = [];

% timestamp id index
for ii = 1:length(files)
    [the_path, the_name, the_ext] = fileparts(files{ii});
    if isempty(start_and_end_times)
        [TimeStamps]=nlx2MatSE([the_name the_ext],1,0,0,0,0,0);
    else
        [TimeStamps]=nlx2MatSE([the_name the_ext],1,0,0,0,0,0,start_and_end_times(1), start_and_end_times(2));
    end
    
    %[T, ScNumbers, CellNumbers, Params, DataPoints] = nlx_SERead(files{ii});
    nspikes(ii) = length(TimeStamps);
    TST = [TST; TimeStamps(:) ii * ones(nspikes(ii),1) [1:nspikes(ii)]' zeros(nspikes(ii),1)];
end
% TST is timestamps, file id, spike number, number of files that have timestamps close to this one.

TST = sortrows(TST);
   
Noise_idx = FindCoincidences(TST(:,1), Nevents, precision_us/100); % divide by 100 to convert to times in 
% Create a matrix that adds the number of unique files to the end of the index.
for ii = 1:length(files)
    TST(Noise_idx,end) = TST(Noise_idx,end) + (TST(Noise_idx,2)== ii);
end
% We now have the indices of the spikes that must be removed. Load each tfile and remove them.
% id (in cell array) of the spikes to remove.
%id = id(Noise_idx);
%idx = idx(Noise_idx);
TST(Noise_idx,:) = []; % All that's left are the good indices.

for ii = 1:length(files)
   [the_path, the_name, the_ext] = fileparts(files{ii});
   newname = ['c' the_name '.dat'];
   if isempty(start_and_end_times)
       [TimeStamps, ScNumbers, CellNumbers, Params, DataPoints, NlxHeader] = Nlx2MatSE(files{ii} ,1,1,1,1,1,1);
   else
       [TimeStamps, ScNumbers, CellNumbers, Params, DataPoints, NlxHeader] = Nlx2MatSE(files{ii} ,1,1,1,1,1,1, start_and_end_times(1), start_and_end_times(2));
   end
     
   subTST = TST(find(TST(:,2) == ii),:);
   good_times_idx = subTST(:,3);
   % Read in the entire SE file (waveform as well).tt   [T,b,sd,s,WV]=nlx_readSE(files{ii});

   noriginalspikes = length(TimeStamps);
   if ~isempty(good_times_idx)
       Mat2NlxSE(fullfile(dest_dir,newname), TimeStamps(good_times_idx), ScNumbers(good_times_idx), CellNumbers(good_times_idx), Params(:,good_times_idx), DataPoints(:,:,good_times_idx), length(good_times_idx));
   else
       % Create an empty SE file.
       Mat2NlxSE(fullfile(dest_dir,newname),0,0,0,zeros(8,1),zeros(32,1,1),0);
       disp('No spikes left, a dummy file was saved.')
   end
   disp(['  RemoveCoincidenceseSE ' fullfile(dest_dir,newname) ': removed ' num2str(noriginalspikes - length(good_times_idx)) ' coincidences, ' num2str(length(good_times_idx)) ' of ' num2str(noriginalspikes) ' spikes remain.']);  
end

