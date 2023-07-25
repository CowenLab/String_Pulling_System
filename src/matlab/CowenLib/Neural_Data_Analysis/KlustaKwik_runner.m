function K = KlustaKwik_runner(filename, times_usec, KKwikMinClusters, KKwikMaxClusters)
% Runs KlustaKwik on a selected datafile given the passed in parameters.
%  THIS IS FOR SE FILES.
% For now, I am hard-coding the paraemters that will be used by klustakwik.
% It's my experience that once these things get decided, they stay
% relatively fixed anyway.
%
%
max_points = 300000; % if above this, break up the file and then merge it. How? just find the closest match in the sub-files and combine them together.
parameter_string = ['-MinClusters ' num2str(KKwikMinClusters) ' -MaxClusters ' num2str(KKwikMaxClusters) ' -MaxPossibleClusters 39'];
KlustaKwikPath = which('KlustaKwik-1.5.exe');
output_directory = 'KKwik_results';
if ~isempty(KlustaKwikPath)
    disp(['KlustaKwikPath undefined, using ' KlustaKwikPath]);
else
    disp('Did not find KlustaKwik-1.5.exe.');
    return
end
try
    mkdir(output_directory)
end
[spiketimes_usec,  wv, header] = Nlx2MatSpike( filename, [1 0 0 0 1], 1, 1, times_usec );
wv = squeeze(wv)';
% Make parameter files 



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


