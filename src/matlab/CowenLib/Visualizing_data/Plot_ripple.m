function [fq,C]=Plot_ripple(x_msec, raw_lfp,sFreq,S,st_ed_ts)
%function [fq,C]=Plot_ripple(x_msec, raw_lfp,sFreq,S,st_ed_ts)
% Make a pretty picture of a ripple oscilaltion - requires wavelet toolbox.
% INPUT: the x val for each point in raw_lfp (unfiltered lfp) for a period
% around the ripple. I usually just have 60ms before and 90ms after.
% Remeber, zero is the start or middle of the ripple. the x values will go
% from negative to positive.
% raw_lfp - a vector of points - the raw lfp for each val in x_msec
% sFreq - the sampling rate of the lfp.
% S - a cell array of spike times This code widdles this down to just the
% ones that fire during the ripple.
% st_ed_ts = 2 element vector with the first being the start time of the
% ripple in 10ths of msec (the usual units of timestamps for spikes
% (unfortunately)) and the end time.
%
% Cowen 2014
%%%%%%%%%%%%%%%%%%%%
% Get rid of cells that do not fire.
%%%%%%%%%%%%%%%%%%%%
ripple_freqs = 75:.25:240;
SMOOTH_IT = true;
SPECTROGRAM_TYPE = 'wavelet';
rip_dur_ms = diff(st_ed_ts)/10;
if nargin == 0
    %% Test the function by generating some artificial data.
    sFreq = 1800;
    interval_s = 1/sFreq;
    t = 0:interval_s:0.800;
    fo = ripple_freqs(1); f1 = ripple_freqs(end);     % Frequency - linear increase from f0 to f1
    y = chirp(t,fo,t(end),f1);
    figure
    spectrogram(y,256,200,256,sFreq,'yaxis')
    figure
    plot(t,y)
    xlabel('s')
    x_msec = (t-t(end)/2)*1000;
    raw_lfp = y;
end

if nargin < 4
    S = []; st_ed_ts = [];
end

%% %%%%%%%%%%%%%%%%%%
clf
subplot(6,1,1:2)
%%%%%%%%%%%%%%%%%%%%
plot(x_msec,raw_lfp,'k','LineWidth',4)
axis tight;

 a = axis;
 a(3) = a(3)*1.1;
 a(4) = a(4)*1.2;
 df = (a(4)-a(3))/84;


% axis(a)
plot_vert_line_at_zero(0,3,'r')
plot_vert_line_at_zero(diff(st_ed_ts)/10,3,'r')

pubify_figure_axis
axis off
% Plot spikes if there are any.
if ~isempty(S)
    cnt = 1;
    SR =  Restrict(S,st_ed_ts(1) - 800, st_ed_ts(2) + 800);
    tmp = [];
    %         figure
    for iC = 1:length(SR)
        if ~isempty(SR{iC})
            tmp{cnt} = SR{iC};
            cnt = cnt + 1;
        end
    end
    SR = tmp;
    J = lines(length(SR));
    for iC = 1:length(SR)
%         plot(SR{iC}/10-st_ed_ts(1)/10, ones(size(SR{iC}))*a(4),'.','Color',J(iC,:))
        plot(SR{iC}/10-st_ed_ts(1)/10, ones(size(SR{iC}))*a(4) - df*(iC-1),'.','Color',J(iC,:),'MarkerSize',18)
        hold on
    end
end
set(gca,'XLim',[x_msec(1) x_msec(end)])
colorbar('hide')
%%%%%%%%%%%%%%%%%%%%
subplot(6,1,3:6)
%%%%%%%%%%%%%%%%%%%%
switch SPECTROGRAM_TYPE
    case 'fft'
        [C,fq,T] = Spectrogram_ripple(raw_lfp, sFreq, ripple_freqs);
        color_plot_label = 'Log Power (Db)';
    case 'wavelet'
        % requires wqvelet toolbox.
        [C,fq] = SPEC_cwt_cowen(raw_lfp,sFreq,ripple_freqs([1 end]));
        C = (abs(C)).^2;
        T = linspace(0,length(raw_lfp)/sFreq,Cols(C));
        color_plot_label = 'Log Power (Db)';
        
end

%
if SMOOTH_IT
    % Make it pretty (this is slow though)
    T2 = linspace(T(1),T(end), 200);
    Ci = interp1_matrix(T,C', T2,'spline')';
    T = T2;
    C = Ci;
end

dt_ms = median(diff(T*1000)); % for aligning the bins.
new_x_msec = linspace(x_msec(1)+dt_ms/2,x_msec(end)-dt_ms/2, length(T));

% plot it.
imagesc(new_x_msec,fq,C)
axis xy
colormap(jet)
[lohi] = prctile(C(:),[3 97]);
caxis(lohi)
axis tight;
ylabel ('Hz');xlabel('ms')
plot_vert_line_at_zero(0,3,'w')
plot_vert_line_at_zero(diff(st_ed_ts)/10,3,'w')

% c = colorbar('southoutside');
c = colorbar;
c.Label.String = color_plot_label;
c.Position(1) = 0.919523796900265 ;
c.FontSize = 10;
pubify_figure_axis
subplot(6,1,1:2)
% Compare with wavelet
if nargin == 0
    figure
    [~,~,fq_w,C_w, t]=Wavelet_ripple(raw_lfp, sFreq, [50 300]);
    imagesc(t*1000,fq_w,C_w)
    axis tight;
    ylabel ('Hz')
    plot_vert_line_at_zero(0,3,'w')
    pubify_figure_axis
    xlabel('ms')
end

