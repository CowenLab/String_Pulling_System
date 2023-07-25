function ts_object = Merge_t_files(fout, varargin)
%
% INPUT: the output filename
%        a list of the t file to merge. One file per input. (varargin)
% 
% OUTPUT: a ts object that contains the new spikes. 
%         a merged T files with duplicate spikes removed
%
% cowen
allspikes = [];
for ii = 1:length(varargin)
  tstmp = LoadSpikes({varargin{ii}});
  allspikes = [allspikes;Data(tstmp{1})];
end
ts_object = ts(sort(unique(allspikes)));
WriteT(fout,ts_object)
