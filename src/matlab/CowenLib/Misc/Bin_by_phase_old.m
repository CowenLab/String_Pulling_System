function [Qtsd, spike_phase_count, mean_bin_size_msec, mean_inter_peak_msec] = Bin_by_phase(S, F, phases_per_cycle,varargin)
% INPUT:
%  ctsa array of ts objects whose spikes will be binned by the phase of F
%  F = a filtered tsd object of EEG data. The size of the Q matrix is determined 
%    by the start and end point of this 
%  phases_per_cycle - the number of bins to use per cycle. Default is 4
%    WARNING: ONLY 4 bins per cycle works right now. (peak zero_up, trough, zero down)
%
% OUTPUT:
%  
%  a ts object that is a cell by spike time matrix where time is measured with reference to the theta cycle.
%  the range of this object is the actual time for each column.
%
% cowen Adapted from ADRs MakeQFromS



if ~isa(S, 'cell')
   error('Type error: S should be a cell array of ts objects.');
end
for iC = 1:length(S)
   if ~isa(S{iC}, 'ts')
      error('Type error: S should be a cell array of ts objects.');
   end
end

if nargin ~= 3
    phases_per_cycle = 4;
end

if phases_per_cycle ~=4
    error('SORRY: Only phases_per_cycle = 4 is valid')
end

%-------------------------------------------------------------
% Find the start and end times.
%-------------------------------------------------------------
T_start = StartTime(F);
T_end   = EndTime(F);
% Get rid of cycles that had an interval longer or shorter than these two
% parameters.
max_peak_interval_msec = [];
min_peak_interval_msec = [];
phases_per_cycle       =  4; % This is hard wired for now.

if ~isfinite(T_start) | ~isfinite(T_end)
  Q = tsd([], []);
  return
end

ProgressBar = 'text';

if nargout == 0
    plotit = 1;
else
    plotit = 0;
end

Extract_varargin;

S = Restrict_tsarray(S,T_start,T_end);


switch ProgressBar
case 'text', flagProgressBar = 1;
case 'graphics', flagProgressBar = 2;
otherwise, flagProgressBar = 0;
end

%--------------------
% Build Q Matrix
%--------------------
%-------------------------------------------------------------
fprintf('Getting phase information...')
[phase, PhaseTimes, PhasesPerCycle,bad_peak_start_times, bad_peak_end_times] = ...
    Phase_detector(S, F, 'TStart', T_start, 'TEnd', T_end, ...
    'max_peak_interval_msec', max_peak_interval_msec, ...
    'min_peak_interval_msec', min_peak_interval_msec);
fprintf(' Done. \n')

% Get rid of spikes that do not fall within 'legal' theta waves.
removed_spikes = 0;
total_spikes = 0;

for iC = 1:length(S)
    ss = Data(S{iC});
    nSpikes = length(ss);
    for ii = 1:length(bad_peak_start_times)
        ss = ss(find(ss < bad_peak_start_times(ii) | ss > bad_peak_end_times(ii)));
    end
    S{iC} = ts(ss);
    removed_spikes = removed_spikes + nSpikes - length(ss);
    total_spikes = total_spikes + nSpikes;
end

fprintf('Got rid of %g (%3.1f percent) spikes.',removed_spikes,100*(removed_spikes/total_spikes))
spikeTotal =0; cellIndx = []; phasecount = []; phasetime = [];

nCells = length(S);                                % number of cells
nTime = Rows(PhaseTimes);

spike_phase_count = zeros(nCells,PhasesPerCycle);

QData = zeros(nCells,nTime); % no spikes, it's a zero-matrix

for iC = 1:nCells
   
   if flagProgressBar == 1
      DisplayProgress(iC, nCells, 'UseGraphics', 0, 'Title', ['Converting ', num2str(nCells), ' cells: ']);
   elseif flagProgressBar == 2
      DisplayProgress(iC, nCells, 'UseGraphics', 1, 'Title', ['Converting ', num2str(nCells), ' cells: ']);
   end
   spikeTimes = Restrict(S{iC}, T_start, T_end);
   nSpikes = length(Data(spikeTimes));
   spikeTotal = spikeTotal + nSpikes;
   QData(iC,:) = hist(Data(spikeTimes)',PhaseTimes(:,1)');
   if ~isempty(phase{iC}.phase_id)  
       %-------------------------------------------------------------
       % Calculate the time in phase units. Take current cycle*phasesPerCycle - phases per cycyle
       % + the phase number. That should give you a linearly increasing 
       % count for the phases.
       %-------------------------------------------------------------
       phasecount = [phasecount; phase{iC}.phase_count;];
       
       phasetime  = [phasetime;  phase{iC}.interp_phasetime];
       b          = ones(nSpikes,1).*iC ;  % set element to 1 if there is a
       % spike. sparse() does the binning  
       cellIndx   = [cellIndx; b];
       % Calculate the number of spikes at each phase of the eeg.
       for ii = 1:PhasesPerCycle
           spike_phase_count(iC,ii) = length(find(phase{iC}.phase_id==ii));
       end
       
   end  % if ~empty                           
end		% for all cells


if 0
    s = ones(spikeTotal,1);
    
    if isempty(phasecount)
        QData = zeros(nTime, nCells); % no spikes, it's a zero-matrix
    else
        % some matlab functions require full(Q)
        QData  = sparse(phasecount, cellIndx, s, nTime, nCells); 
    end
end

Qtsd = tsd(PhaseTimes(:,1),QData');

idx = find(PhaseTimes(:,2)==1);
PeaksTimes = PhaseTimes(idx,1);

mean_bin_size_msec   = mean(diff(PhaseTimes(:,1)))/10;
mean_inter_peak_msec = mean(diff(PeaksTimes))/10;

disp(['Mean bin size: ' num2str(mean_bin_size_msec) ...
        ' msec, Std: '  num2str(std(diff(PhaseTimes(:,1)/10))) ' msec.'])
disp(['Mean inter peak interval: ' num2str(mean_inter_peak_msec) ...
        ' msec, Std: '  num2str(std(diff(PeaksTimes)/10)) ' msec.'])
%-------------------------------------------------------------
% Plot a load of stuff to verify everything is working.
%-------------------------------------------------------------

if plotit
    figure

    Error_bars(spike_phase_count)
    xlabel('Phase')
    ylabel('Mean number of matches per cell')
    title('Mean Phase count')
    
    if 0
        figure
        plot(Range(F,'ts'), Data(F)/max(Data(F)))
        hold on 
        D = Data(phase{1});
        plot(Range(phase{1},'ts'), D(:,1)/max(D(:,1)),'r+')  
        D = Data(phase{2});
        plot(Range(phase{2},'ts'), D(:,1)/max(D(:,1)),'g+')
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot sample data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure
    chunksize = 200000;
    sF = Restrict(F,T_start,T_start + chunksize);

    sp_phase{1} = Restrict(phase{1},T_start,T_start + chunksize);
    sp_phase{2} = Restrict(phase{2},T_start,T_start + chunksize);
    sp_phase{3} = Restrict(phase{3},T_start,T_start + chunksize);
    
    
    [sph, sPhaseTimes] = Phase_detector(Range(sF,'ts'), sF);
    
    sph{1} = Restrict(sph{1},T_start,T_start + chunksize);
    
    sPeaksTimes   = PhaseTimes(find(sPhaseTimes(:,2)==1),1);
    sTroughsTimes = PhaseTimes(find(sPhaseTimes(:,2)==3),1);
    sZeroDownTimes= PhaseTimes(find(sPhaseTimes(:,2)==2),1);
    sZeroUpTimes  = PhaseTimes(find(sPhaseTimes(:,2)==4),1);
    
    
    AD = Data(sph{1});
    plot(Range(sph{1},'ts'),AD(:,1)./max(AD(:,1)),'y+')
    hold on;
    plot(sPeaksTimes,ones(length(sPeaksTimes),1),'gp'); %Peaks
    plot(sTroughsTimes,ones(length(sTroughsTimes),1),'kp'); %Peaks
    plot(sZeroUpTimes,ones(length(sZeroUpTimes),1),'mp'); %Peaks
    plot(sZeroDownTimes,ones(length(sZeroDownTimes),1),'cp'); %Peaks
    plot(Range(sF,'ts'), Data(sF)./max(Data(sF)),'r');
    newCR = Restrict(F,T_start,T_start + chunksize);
    plot(Range(newCR,'ts'), Data(newCR)./max(Data(newCR)),'m');
    D = Data(sp_phase{1});
    plot(Range(sp_phase{1}, 'ts' ), D(:,1) / max(D(:,1)), 'r*' )  
    D = Data(sp_phase{2});
    plot(Range(sp_phase{2}, 'ts' ), D(:,1) / max(D(:,1)), 'g*' )
    D = Data(sp_phase{3});
    plot(Range(sp_phase{3}, 'ts' ), D(:,1) / max(D(:,1)), 'c*' )
     
    title(['Filtered data and spikes'])
    % Plot the Q matrix with the waveform and some spikes super imposed. Cool.
    % DO NOT USE IMAGE or something like it, it will fu
    figure
    sQtsd = Restrict(Qtsd, T_start, T_start + chunksize);
    QD = Data(sQtsd);
    QR = Range(sQtsd,'ts');
    plot(QR,QD(:,1),'r')
    hold on
    plot(QR,QD(:,2),'g')
    plot(QR,QD(:,3),'c')
    ncells = Cols(Data(sQtsd));
    plot(Range(sph{1},'ts'),(AD(:,1)./max(AD(:,1)))*.8,'y+')
    plot(Range(newCR,'ts'), (Data(newCR)./max(Data(newCR))+1)*.8,'m');
    D = Data(sp_phase{1});
    plot(Range(sp_phase{1},'ts'), (D(:,1)/max(D(:,1)))*.8,'r*')  
    D = Data(sp_phase{2});
    plot(Range(sp_phase{2},'ts'), (D(:,1)/max(D(:,1)))*.8,'g*')
    D = Data(sp_phase{3});
    plot(Range(sp_phase{3},'ts'), (D(:,1)/max(D(:,1)))*.8,'c*')
  
    %plot(Data(S{3}),ones(length(Data(S{3})),1),'ko')
    figure 
    R = Range(sp_phase{3},'ts');
    plot(R,ones(length(R),1),'ro')
    hold on
    DD = Data(sQtsd);
    
    plot(Range(sQtsd,'ts'),DD(:,3))
    
end

disp('')
%--------------------
% Build standard data structure
%--------------------
%Q = ctsd(T_start, DT, QData);

