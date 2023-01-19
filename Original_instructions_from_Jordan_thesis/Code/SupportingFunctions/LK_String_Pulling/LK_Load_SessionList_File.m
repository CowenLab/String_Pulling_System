function ALLSES = LK_Load_SessionList_File(fname)
ALLSES = readtable(fname);
ALLSES.Sorted = ALLSES.Sorted > 0;
ALLSES.DeepLabCutFile = ALLSES.DeepLabCutFile > 0;
ALLSES.StringPulling = contains(ALLSES.Behavior,'String','IgnoreCase',true);
ALLSES.Treadmill = contains(ALLSES.Behavior,'Tread','IgnoreCase',true);
ALLSES.Ketamine = contains(ALLSES.Drugs,'Ketam','IgnoreCase',true);
ALLSES.Saline = contains(ALLSES.Drugs,'Salin','IgnoreCase',true);
ALLSES.LDOPA = contains(ALLSES.Drugs,'DOPA','IgnoreCase',true);
ALLSES.RatType = categorical(ALLSES.RatType);

