% test script for
% S = GaussPoissonNeurons(par)

test = 22;



switch test

    case 1
        % pure homogenous poisson with all cells at identical mean rate = 0.5 Hz
        par.StartEndTS = [0,5000*10000];
        par.CellRates = 0.5*ones(20,1);
        par.ClusterProcessFraction = 0;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;

    case 2
        % pure homogenous poisson with all cells at identical mean rate = 1 Hz
        par.StartEndTS = [0,5000*10000];
        par.CellRates = ones(20,1);
        par.ClusterProcessFraction = 0;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;        

    case 20
        % pure gaussian clusters (100% gaussian clusters,sigma = 1 sec), extending uniformly over
        % all neurons
        par.StartEndTS = [0,5000*10000];
        par.CellRates = ones(20,1);
        par.ClusterProcessFraction = 1;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;
        
    case 21
        % pure gaussian clusters (70% gaussian clusters,sigma = 1 sec), extending uniformly over
        % all neurons
        par.StartEndTS = [0,5000*10000];
        par.CellRates = ones(20,1);
        par.ClusterProcessFraction = 0.7;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;
        
    case 22
        % pure gaussian clusters (70% gaussian clusters,sigma = 1 sec), extending over
        % sigma = 3 neurons
        par.StartEndTS = [0,5000*10000];
        par.CellRates = ones(20,1);
        par.ClusterProcessFraction = 0.7;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = 3;
        
    case 30
        nCells = 20;
        t = repmat(1:2:5000,nCells,1);    % 20 cells 
        nbins = size(t,2);
        lambda = 300;       % wavelength
        omega = pi/lambda;
        phase = repmat(rand(nCells,1)*2*pi,1,nbins);        % random phase for each cell
        rateAmplitude = 0.2 + repmat(rand(nCells,1)*1.6,1,nbins);   % uniformly distributed ampltudes in [0.2,1.8], mean = 1;
        rates = rateAmplitude.*(0.5 + sin(omega*t+phase).^2);
        
        figure; plot(rates(1:2,:)');
        par.StartEndTS = [0,5000*10000];
        par.CellRates = rates;
        par.ClusterProcessFraction = 0.5;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;

        
     case 1000
        % pure posson neurons (0% gaussian clusters) with constant experimental mean rates from
        % data QMatrix Q (Q needs to be in workspace!)
        if ~exist('Q','var')
            error('need a QMatrix with name Q in workspace!');
        end
        figure; imagesc(Data(Q)');title('Original input Q');      % plot original input Q
        QD = Data(Q);
        t = Range(Q,'sec');     % timestamps of Q-bins in sec
        binSize_sec = mean(diff(t)); 
        meanQRates = transpose(full(mean(QD)))/binSize_sec;
        figure; plot(meanQRates);
        %
        par.StartEndTS = [StartTime(Q),EndTime(Q)];
        par.CellRates = meanQRates;
        par.ClusterProcessFraction = 0;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;

        
     case 1010
        % gauss-posson clusters (50% gaussian clusters) with constant experimental mean rates from
        % data QMatrix Q (Q needs to be in workspace!)
        if ~exist('Q','var')
            error('need a QMatrix with name Q in workspace!');
        end
        figure; imagesc(Data(Q)');title('Original input Q');      % plot original input Q
        QD = Data(Q);
        t = Range(Q,'sec');     % timestamps of Q-bins in sec
        binSize_sec = mean(diff(t)); 
        meanQRates = transpose(full(mean(QD)))/binSize_sec;
        figure; plot(meanQRates);
        %
        par.StartEndTS = [StartTime(Q),EndTime(Q)];
        par.CellRates = meanQRates;
        par.ClusterProcessFraction = 0.5;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf; % uniform across cells


     case 2000
        % pure posson neurons (0% gaussian clusters) with VARIABLE experimental mean rates from
        % data QMatrix Q smoothed over 1 min and subsampled every 3 sec. 
        % (Q needs to be in workspace!)
        smoothQ_sigma_sec = 60;          % half-width of smoothing gaussian (in sec)
        subSampleInterval_sec = 3;      % distance between sample points of sub-sampled Q (in sec) 
        if ~exist('Q','var')
            error('need a QMatrix with name Q in workspace!');
        end
        figure; imagesc(Data(Q)');title('Original input Q');      % plot original input Q
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
        figure; imagesc(QRates);colorbar; title('Slow varying mean firing rates of input Q');
        %
        par.StartEndTS = [StartTime(Q),EndTime(Q)];
        par.CellRates = QRates;
        par.ClusterProcessFraction = 0;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;

    
    case 2001
        % pure posson neurons (0% gaussian clusters) with VARIABLE experimental mean rates from
        % data QMatrix Q smoothed over 5 min and subsampled every 15 sec. 
        % (Q needs to be in workspace!)
        smoothQ_sigma_sec = 5*60;          % half-width of smoothing gaussian (in sec)
        subSampleInterval_sec = 15;      % distance between sample points of sub-sampled Q (in sec) 
        if ~exist('Q','var')
            error('need a QMatrix with name Q in workspace!');
        end
        figure; imagesc(Data(Q)');title('Original input Q');      % plot original input Q
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
        figure; imagesc(QRates);colorbar; title('Slow varying mean firing rates of input Q');
        %
        par.StartEndTS = [StartTime(Q),EndTime(Q)];
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
        figure; imagesc(Data(Q)');title('Original input Q');      % plot original input Q
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
        figure; imagesc(QRates);colorbar; title('Slow varying mean firing rates of input Q');
        %
        par.StartEndTS = [StartTime(Q),EndTime(Q)];
        par.CellRates = QRates;
        par.ClusterProcessFraction = 0;
        par.ClusterRate = 0.1;
        par.ClusterWidthTime = 1;
        par.ClusterWidthCell = Inf;

        
    otherwise
        error('case %d is not implemented!',test);

end

S = GaussPoissonNeurons(par);

Q = MakeQfromS(S,200*10);

figure;
S = flipud(S); % ----- Masami 2005-07-06 ----- 
RasterPlot(S);

figure;
imagesc(Data(Q)'); colorbar; title('Simulated Q');