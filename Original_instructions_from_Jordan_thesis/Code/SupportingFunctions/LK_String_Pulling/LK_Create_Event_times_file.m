function LK_Create_Event_times_file()
%%
load('EVT.mat')
IMU = LK_Load_and_Process_IMU('Inertial_data.mat');
load('POS.mat','POS')
load('Meta_data.mat')
ROT = LK_Rotary_Encode_Speed(EVT, META);
E = [];
if exist('Event_times.xlsx','file')
    E = LK_Load_Events_From_Excel('Event_times.xlsx');
end
%%
[~,sc] = pca(IMU.data_V);

figure
plot(IMU.t_uS/60e6,sc(:,1))
yyaxis right
P = [POS.Green_xy POS.Red_xy ];
if sum(POS.Green_xy(:,1)) == 0
    P = P(:,3:4);
end

P(P<10) = nan;
[~,sc2] = pca(P);
plot(POS.Time_uS/60e6,sc2(:,1))

if ~isempty(E)
    plot_markers_simple(E.MinFromStart)
end
[X,Y,notes] = ginput_cowen(inf,true);

T = [];
for ii = 1:length(X)
    t_uS = X(ii)*60e6;
    T(ii).EventID = notes{ii};
    T(ii).HMS = 0;
    T(ii).MinFromStart = X(ii);
    T(ii).Notes = '';
end
writetable(struct2table(T),'Event_times.csv')
