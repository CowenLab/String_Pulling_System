function [CID, CIDs] = Cell_ID(animal, session, nTrode, cluster, subsession)
%function [CID, CIDs] = Cell_ID(animal, session, nTrode, cluster, subsession)
%
% Creates a unique cell_ID for this particular cell.
%  IF NOT A nTrode, use the following numbering scheme: R1=13, R2=14 for hyperdrives.
%    If a warp drive, just use the channel number (1-144).
%
%  IF NO SUBSESSION (when a recording session is divided into multpiple 
%    subsessions- usually not the case), use 1 (default)
% 
% If one argument is passed, then CellID reverse translates a given
% cell ID into a vector [animal, session, nTrode, cluster, subsession]
%
% e.g . [CID, CIDs] =Cell_ID(7998, 33, 4, 2, 1)
%                CIDs = 7998033040201
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2006.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 5
    subsession = 1;
end

if subsession == 0
    error('Subsession needs to be > 0 ')
end

if nargin > 1
	CIDs = sprintf('%4.0f%03.0f%04.0f%02.0f%02.0f',animal, session, nTrode, cluster, subsession);
	CID = str2num(CIDs);
else
    if length(animal) > 1
        for ii = 1: length(animal)
            CID(ii,:) = Cell_ID(animal(ii));
        end
        return
    end
	if isnumeric(animal)
		animal = mat2str(animal);
    end
	CID(1) = str2num(animal(1:4)) ;
	CID(2) = str2num(animal(5:7)) ;
	CID(3) = str2num(animal(8:11)) ;
	CID(4) = str2num(animal(12:13)) ;
	CID(5) = str2num(animal(14:15)) ;
    if nargout == 2
        for ii = 1:5
            CIDs{ii} = num2str(CID(ii)) ;
        end
    end
end