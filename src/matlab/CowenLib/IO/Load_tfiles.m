function [S,SP] = Load_tfiles(tfl,isBigEndian) %,Lratio_IsolationDist_thresh)
% Load in all of the tfiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT: A cell array of tfile paths (full) or a filename
% OUTPUT: a cell array of vectors of timestamps or a vector of timestamps (if a filename was passed)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S = []; SP = [];
if nargin == 1
    isBigEndian = 1; % PCs are littleendian, Unix is bigendian, but for some reason, tfiles are stored bigendian. The question is how was the tfile saved.
end

if iscell(tfl)
    for ii = 1:length(tfl)
        S{ii} = loadit(tfl{ii}, isBigEndian);
    end
else
    S = loadit(tfl, isBigEndian);
end
if nargout > 1 || nargin > 2
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % If the user asks for a second output, assume that they want the cluster
    % info data as well. This is only loaded if the ClusterSummary file exists.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for ii = 1:length(tfl)
        SP(ii).t = S{ii};
        SP(ii).fname = tfl{ii};
        % Load the data.
        [p,n] = fileparts(tfl{ii});
        csfname = strrep(n,'_', '_ClusterSummary_');
        fn = fullfile(p,[csfname '.mat']);
        if exist(fn,'file');
            SP(ii).ClustInfo = load(fn);
        else
            SP(ii).ClustInfo = [];
        end
    end
%     if nargin > 2
%         % THIS IS NOT COMPLETE. DO NOT USE YET. 
%         count = 1;
%         newS = []; newSP = [];
%         for iCell = 1:length(S)
%             if SP(iCell).ClustInfo.L_Ratio < Lratio_IsolationDist_thresh(1) && SP(iCell).ClustInfo.Isolation_Dist > Lratio_IsolationDist_thresh(2)
%                 newS{count} = S{iCell};
%                 newSP(count) = SP(iCell);
%                 count = count + 1;
%             end
%         end
%         S = newS;
%         SP = newSP;
%     end
end

function o = loadit(Filename,isBigEndian)
% loads the data.
if isBigEndian
    tfp = fopen(Filename, 'rb','b');
else
    tfp = fopen(Filename, 'rb');
end

if (tfp == -1)
    warning([ 'Could not open tfile ' Filename]);
    o = [];
else
    ReadHeader(tfp);
    o = fread(tfp,inf,'uint32');	%read as 32 bit ints
    fclose(tfp);
end