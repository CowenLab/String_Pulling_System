function SI = Load_Set_Info(what_to_load,varargin)
%function SI = Load_Set_Info(what_to_load,varargin)
%------------------------------------------------------------------------
% Load information about the animal from the text database (to be propagated to the sql database.)
% INPUT: what_to_load - a string specifying what to load (i.e. 'protocol')
%                     arguments describing the parameters 
% 
% OUTPUT: A structure database of the datasets in question.
%------------------------------------------------------------------------
    
[       SesInfo.AnimalNumber,...
        SesInfo.SessionNumber,...
        SesInfo.SubSessionNumber,...
        SesInfo.SubDirectory,...
        SesInfo.IsCut,...
        SesInfo.ProjectDirectory,...
        SesInfo.Protocol,...
        SesInfo.Notes ] = ...
    textread(fullfile(Database_dir,'session_database.txt'),'%d%d%d%s%d%s%s%s','commentstyle','matlab','delimiter','\t');


SesInfo.Protocol = deblank(SesInfo.Protocol);
SesInfo.SubDirectory = deblank(SesInfo.SubDirectory);
SesInfo.ProjectDirectory = deblank(SesInfo.ProjectDirectory);

if nargin == 0
    SI = SesInfo;
else
    switch lower(what_to_load)
    case 'all'
        idx = 1:length(SesInfo.AnimalNumber);
    case 'session'
        an = varargin{1};
        ses = varargin{2};
        subses = varargin{3};
        count = 1;
        for ii = 1:length(an)
            
           tmp = find(SesInfo.AnimalNumber == an(count) & SesInfo.SessionNumber == ses(count) & SesInfo.SubSessionNumber == subses(count));
           if ~isempty(tmp)
               idx(count) = tmp;
               count = count + 1;
           else
               error('Could not find dataset in the database')
           end
           
        end
    case 'protocol'
        prot = varargin{1};
        count = 1;
        for ii = 1:length(SesInfo.AnimalNumber)
            if strcmpi(SesInfo.Protocol{ii},prot)
                idx(count) = ii;
                count = count + 1;
            end
        end
    otherwise
        error('Improper load specifier')
    end
    
    for ii = 1:length(idx)
        SI.AnimalNumber(ii) = SesInfo.AnimalNumber(idx(ii));
        SI.SessionNumber(ii) = SesInfo.SessionNumber(idx(ii));
        SI.SubSessionNumber(ii) = SesInfo.SubSessionNumber(idx(ii));
        SI.SubDirectory{ii} = SesInfo.SubDirectory{idx(ii)};
        SI.IsCut(ii) = SesInfo.IsCut(idx(ii));
        SI.ProjectDirectory{ii} = SesInfo.ProjectDirectory{idx(ii)};
        SI.Protocol{ii} = SesInfo.Protocol{idx(ii)};
        SI.SessionName{ii} = [num2str(SI.AnimalNumber(ii)) '_' num2str(SI.SessionNumber(ii)) '_' num2str(SI.SubSessionNumber(ii))];
        SI.DataDirectory{ii} = fullfile(Data_dir,SI.ProjectDirectory{ii},num2str(SI.AnimalNumber(ii)),[num2str(SI.AnimalNumber(ii)) '_' num2str(SI.SessionNumber(ii)) ],SI.SubDirectory{ii});
        SI.Notes{ii} = SesInfo.Notes{idx(ii)};
    end
end