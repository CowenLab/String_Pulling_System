function [IMU, IMPC] = LK_Load_and_Process_IMU(fname)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load and smooth the IMU data.
%
% Cowen 2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 1
    fname = 'Inertial_data.mat';
end

load(fname,'IMU');
IMU.data_V = single(IMU.data_V);
smooth_win_sec = .2;
IMU.t_uS = IMU.t_uS(:);
% sFreq = 1/median(diff(IMU.t_uS(1:20)/1e6));
win_size = round(IMU.IMU_sFreq*smooth_win_sec);
IMU.speed = mean(abs(diff(IMU.data_V)),2); % abs of first derivative of mvt.
IMU.speed = convn(IMU.speed,hanning(win_size)/sum(hanning(win_size)),'same');
IMU.speed = single([0;IMU.speed]);

absjerk = mean(Jerk(IMU.data_V),2);
absjerksmt = convn(absjerk,hanning(win_size)/sum(hanning(win_size)),'same');
absjerksmt = [0;0;absjerksmt;0];
IMU.absjerk = single(absjerksmt);
[pco,sco,lato] = pca(IMU.data_V);

IMU.speed_pc1 = abs(diff(sco(:,1))); % abs of first derivative of pc1.
IMU.speed_pc1 = convn(IMU.speed_pc1,hanning(win_size)/sum(hanning(win_size)),'same');
IMU.speed_pc1 = single([0;IMU.speed_pc1]);

[~,sc] = pca(diff(IMU.data_V));

absjerkpc = mean(abs(diff(diff(sc(:,1:2)))),2); % one less diff since the pca was on the diff.
absjerkpcsmt = convn(absjerkpc,hanning(win_size)/sum(hanning(win_size)),'same');
absjerkpcsmt = [0;0;absjerkpcsmt;0];
IMU.absjerkpc = single(absjerkpcsmt);

if nargout > 1
    IMPC.SC = single(sco(1:3));
    IMPC.latent = lato;
    IMPC.pc = pco;
    
    IMPC.dfSC = single(sc(1:3));

end


if nargout == 0
    figure
    subplot(2,1,1)
    plot(IMU.absjerk)
    hold on
    plot(IMU.absjerkpc)
    legend('absjerk','absjerkpc')
    yyaxis right
    plot(IMU.speed)
    hold on
    plot(IMU.speed_pc1)
    subplot(2,1,2)
    plot(sco(:,1))
    hold on
    plot(sco(:,2))    
    
end
