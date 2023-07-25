function [S, par] = GaussPoissonNeurons_Simulation(type,T0,T1,Q) 
%
% S = GaussPoissonNeurons_Simulation(type,Q) 
%
%  Driver for Simulation of a set of correlated Gauss-Poisson Neurons
%
%  Input:
%    type  ... integer switch to select simulation type; the parameters for the simulation are select
%               in a switch statement according to type
%    T0,T1 ... start and end timestamp of simulation; all neurons generate
%               timestamps in interval [T0,T1];  timestamps are in 0.1 msec
%               units (NSMA timestamps)
%    Q      ... a data Q-Matrix, used to extract variable or constant mean firing
%               rates for each neuron (depending on type). 
%
% Output:
%    S ...      S-Matrix of simulated neurons (cell array of ts-objects with NSMA 0.1 msec
%               timestamps)
%    par ...    the paramter struct used for the simulation (as reference)
%
%  PL July 3, 2005
%  Version 2.0
%

% extract shape of Q-Matrix
QD = Data(Q)';
[nCells,nBins] = size(QD);


% set simulation interval for all types
par.StartEndTS = [T0,T1];


switch type

    case 1
        % pure homogenous poisson with all cells at identical mean rate = 0.5 Hz 
        par.CellRates = 0.5*ones(nCells,1);
        par.ClusterProcessFraction = 0;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;

    case 2
        % pure homogenous poisson with all cells at identical mean rate = 1 Hz 
        par.CellRates = ones(nCells,1);
        par.ClusterProcessFraction = 0;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;

        
    case 20
        % pure gaussian clusters (100% gaussian clusters,sigma = 1 sec), extending uniformly over
        % all neurons
        par.CellRates = ones(nCells,1);
        par.ClusterProcessFraction = 1;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;


    case 30
        % variable sinusoidal rates with random phases across neurons and
        % 50% gaussian clusters
        t = repmat((T0/10000):2:(T1/10000),nCells,1);    
        nbins = size(t,2);
        lambda = 300;       % wavelength
        omega = pi/lambda;
        phase = repmat(rand(nCells,1)*2*pi,1,nbins);        % random phase for each cell
        rateAmplitude = 0.2 + repmat(rand(nCells,1)*1.6,1,nbins);   % uniformly distributed ampltudes in [0.2,1.8], mean = 1;
        rates = rateAmplitude.*(0.5 + sin(omega*t+phase).^2);
        
        %figure; plot(rates(1:2,:)');
        par.CellRates = rates;
        par.ClusterProcessFraction = 0.5;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;

     case 1000
        % pure posson neurons (0% gaussian clusters) with CONSTANT experimental mean rates from
        % data QMatrix Q (Q needs to be in workspace!)
        if ~exist('Q','var')
            error('need a QMatrix with name Q in workspace!');
        end
        %%figure; imagesc(Data(Q)');title('Original input Q');      % plot original input Q
        QD = Data(Q);
        t = Range(Q,'sec');     % timestamps of Q-bins in sec
        binSize_sec = mean(diff(t)); 
        meanQRates = transpose(full(mean(QD)))/binSize_sec; % median didn't work...
        %%figure; plot(meanQRates); title('Mean Firing Rates of each Cell');
        %
        %%par.StartEndTS = [StartTime(Q),EndTime(Q)];
        par.CellRates = meanQRates;
        par.ClusterProcessFraction = 0;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;

        
     case 1010
        % gauss-posson clusters (50% gaussian clusters) with CONSTANT experimental mean rates from
        % data QMatrix Q (Q needs to be in workspace!)
        if ~exist('Q','var')
            error('need a QMatrix with name Q in workspace!');
        end
        %%figure; imagesc(Data(Q)');title('Original input Q');      % plot original input Q
        QD = Data(Q);
        t = Range(Q,'sec');     % timestamps of Q-bins in sec
        binSize_sec = mean(diff(t)); 
        meanQRates = transpose(full(mean(QD)))/binSize_sec; % median didn't work...
        %%figure; plot(meanQRates); title('Mean Firing Rates of each Cell');
        %
        %%par.StartEndTS = [StartTime(Q),EndTime(Q)];
        par.CellRates = meanQRates;
        par.ClusterProcessFraction = 0.5;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;


     case 2000
        % pure posson neurons (0% gaussian clusters) with VARIABLE experimental mean rates from
        % data QMatrix Q smoothed over 1 min and subsampled every 3 sec. 
        % (Q needs to be in workspace!)
        smoothQ_sigma_sec = 60;          % half-width of smoothing gaussian (in sec)
        subSampleInterval_sec = 3;      % distance between sample points of sub-sampled Q (in sec) 
        if ~exist('Q','var')
            error('need a QMatrix with name Q in workspace!');
        end
        %%figure; imagesc(Data(Q)');title('Original input Q');      % plot original input Q
        %
        t = Range(Q,'sec')';     % timestamps of Q-bins in sec
        binSize_sec = mean(diff(t));
        % smooth Q and get variable rates
        QD = Smooth_Q(Data(Q)', binSize_sec*1000, smoothQ_sigma_sec*1000)/binSize_sec;  % variable firing rates in spikes/sec;  nCells*nBins full array
        % subsample QD
        t1 = StartTime(Q,'sec'):subSampleInterval_sec:EndTime(Q,'sec');     % timestamps of sub-sampled QD in sec
        QRates = zeros(size(QD,1), length(t1));
        for iC=1:size(QRates,1)
            QRates(iC,:) = interp1(t,QD(iC,:),t1);
        end
        %%figure; imagesc(QRates);colorbar; title('Slow varying mean firing rates of input Q');
        %
        %%par.StartEndTS = [StartTime(Q),EndTime(Q)];
        par.CellRates = QRates;
        par.ClusterProcessFraction = 0;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;
        
        
     case 2001
        % pure posson neurons (0% gaussian clusters) with VARIABLE experimental mean rates from
        % data QMatrix Q smoothed over 5 mins and subsampled every 15 sec. 
        % (Q needs to be in workspace!)
        smoothQ_sigma_sec = 5*60;          % half-width of smoothing gaussian (in sec)
        subSampleInterval_sec = 15;      % distance between sample points of sub-sampled Q (in sec) 
        if ~exist('Q','var')
            error('need a QMatrix with name Q in workspace!');
        end
        %%figure; imagesc(Data(Q)');title('Original input Q');      % plot original input Q
        %
        t = Range(Q,'sec')';     % timestamps of Q-bins in sec
        binSize_sec = mean(diff(t));
        % smooth Q and get variable rates
        QD = Smooth_Q(Data(Q)', binSize_sec*1000, smoothQ_sigma_sec*1000)/binSize_sec;  % variable firing rates in spikes/sec;  nCells*nBins full array
        % subsample QD
        t1 = StartTime(Q,'sec'):subSampleInterval_sec:EndTime(Q,'sec');     % timestamps of sub-sampled QD in sec
        QRates = zeros(size(QD,1), length(t1));
        for iC=1:size(QRates,1)
            QRates(iC,:) = interp1(t,QD(iC,:),t1);
        end
        %%figure; imagesc(QRates);colorbar; title('Slow varying mean firing rates of input Q');
        %
        %%par.StartEndTS = [StartTime(Q),EndTime(Q)];
        par.CellRates = QRates;
        par.ClusterProcessFraction = 0;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;
        
        
     case 2010
        % gauss-posson neurons (50% gaussian clusters) with VARIABLE experimental mean rates from
        % data QMatrix Q smoothed over 1 min and subsampled every 3 sec. 
        % (Q needs to be in workspace!)
        smoothQ_sigma_sec = 60;          % half-width of smoothing gaussian (in sec)
        subSampleInterval_sec = 3;      % distance between sample points of sub-sampled Q (in sec) 
        if ~exist('Q','var')
            error('need a QMatrix with name Q in workspace!');
        end
        %%figure; imagesc(Data(Q)');title('Original input Q');      % plot original input Q
        %
        t = Range(Q,'sec')';     % timestamps of Q-bins in sec
        binSize_sec = mean(diff(t));
        % smooth Q and get variable rates
        QD = Smooth_Q(Data(Q)', binSize_sec*1000, smoothQ_sigma_sec*1000)/binSize_sec;  % variable firing rates in spikes/sec;  nCells*nBins full array
        % subsample QD
        t1 = StartTime(Q,'sec'):subSampleInterval_sec:EndTime(Q,'sec');     % timestamps of sub-sampled QD in sec
        QRates = zeros(size(QD,1), length(t1));
        for iC=1:size(QRates,1)
            QRates(iC,:) = interp1(t,QD(iC,:),t1);
        end
        %%figure; imagesc(QRates);colorbar; title('Slow varying mean firing rates of input Q');
        %
        %%par.StartEndTS = [StartTime(Q),EndTime(Q)];
        par.CellRates = QRates;
        par.ClusterProcessFraction = 0.5;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;

     case 2011
        % gauss-posson neurons (50% gaussian clusters) with VARIABLE experimental mean rates from
        % data QMatrix Q smoothed over 5 min and subsampled every 15 sec. 
        % (Q needs to be in workspace!)
        smoothQ_sigma_sec = 5*60;          % half-width of smoothing gaussian (in sec)
        subSampleInterval_sec = 15;      % distance between sample points of sub-sampled Q (in sec) 
        if ~exist('Q','var')
            error('need a QMatrix with name Q in workspace!');
        end
        %%figure; imagesc(Data(Q)');title('Original input Q');      % plot original input Q
        %
        t = Range(Q,'sec')';     % timestamps of Q-bins in sec
        binSize_sec = mean(diff(t));
        % smooth Q and get variable rates
        QD = Smooth_Q(Data(Q)', binSize_sec*1000, smoothQ_sigma_sec*1000)/binSize_sec;  % variable firing rates in spikes/sec;  nCells*nBins full array
        % subsample QD
        t1 = StartTime(Q,'sec'):subSampleInterval_sec:EndTime(Q,'sec');     % timestamps of sub-sampled QD in sec
        QRates = zeros(size(QD,1), length(t1));
        for iC=1:size(QRates,1)
            QRates(iC,:) = interp1(t,QD(iC,:),t1);
        end
        %%figure; imagesc(QRates);colorbar; title('Slow varying mean firing rates of input Q');
        %
        %%par.StartEndTS = [StartTime(Q),EndTime(Q)];
        par.CellRates = QRates;
        par.ClusterProcessFraction = 0.5;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;

        
        
    otherwise
        error('Simulation Type %d is not implemented!',type);

end

S = GaussPoissonNeurons(par);

%Q = MakeQfromS(S,200*10);
%
% figure;
% RasterPlot(S);
% 
% figure;
% imagesc(Data(Q)'); colorbar