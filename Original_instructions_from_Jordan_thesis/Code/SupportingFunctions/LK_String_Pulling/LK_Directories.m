function D = LK_Directories()
D.Data_Dir = [];
D.Box_Dir = [];
D.LFP_Dir = [];
D.Video_Dir = [];
D.Analysis_Dir = [];
D.SessionList_File = [];

txt = userpath;
ix =  strfind(txt,'Documents');
pth = txt(1:(ix-1));

try
    if exist('D:\R56_Single_Unit\Videos','dir')
        D.Video_Dir = 'D:\R56_Single_Unit\Videos';
    end
    if exist('D:\R56_Single_Unit\Videos','dir')
        D.Video_Dir = 'D:\R56_Single_Unit\Videos';
    end
    if exist(fullfile(pth,'Box','Cowen Laboratory'),'dir')
        D.Box_Dir = fullfile(pth,'Box','Cowen Laboratory');
    end
    if ~isempty(D.Box_Dir)
        D.SessionList_File = fullfile(D.Box_Dir,'!Projects\LID_Ketamine_Single_Unit_R56\Meta_Data\SessionInfo.xlsx');
        assert(exist(D.SessionList_File ,'file') > 0,'SessionInfo.xlsx not found')
    end
    if ~isempty(D.Box_Dir)
        D.Data_Dir = fullfile(D.Box_Dir,'Data','LID_Ketamine_Single_Unit_R56');
        assert(exist(D.Data_Dir,'dir') > 0,'Data Dir Not Found')
    end
    %%%%%%%%%%
    % NOTE: Should put a place here for the LFP directory. This is a big
    % directory so it will likely have to be in its own space.
    %%%%%%%%%%
    D.Analysis_Dir = Analysis_dir();
end