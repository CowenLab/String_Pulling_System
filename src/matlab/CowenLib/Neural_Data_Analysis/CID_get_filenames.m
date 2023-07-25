function FN = CID_get_filenames(CID,root_data_dir)
%function CID_get_filenames(CID,root_data_dir)
% Get the filenames for the CIDs passed in 
%see Cell_ID for a description of a CID
for ii =1:length(CID)
   [CIDv CIDs] = Cell_ID(CID(ii));
   if CIDv(3) == 1000
       prefix = 'HIPP';
       CIDs{3} = '';
   elseif CIDv(3) == 1001
       prefix = 'R1';
       CIDs{3} = '';
   elseif CIDv(3) == 1002
       prefix = 'R2';
       CIDs{3} = '';
   else
       prefix = 'TT';
   end
   clufilename = [prefix CIDs{3} '_ClusterSummary_' CIDs{4} '.mat'];
   tfilename   = [prefix CIDs{3} '_' CIDs{4} '.t'];
   ndbfilename  = [prefix CIDs{3} '_' CIDs{4} '_NDB.mat'];
   FN.cluster_summary{ii} = fullfile(root_data_dir,[CIDs{1} '_' CIDs{2}],'tfiles',clufilename);
   FN.tfiles{ii}   = fullfile(root_data_dir,[CIDs{1} '_' CIDs{2}],'tfiles',tfilename);
   FN.ndbfilename{ii} = fullfile(root_data_dir,[CIDs{1} '_' CIDs{2}],'tfiles',ndbfilename);
end
