function OUT = LSTM_interpolation(t_and_data, n_bins_to_predict)
% Use an LSTM trained on multi-dimensional data to fill in missing and or
% smooth data that is already there.
% It sort of works - but was working MUCH better. I broke it somehow
% t_and_data: co1 is time, the rest are dimensions in the data
% if any value in col 2:end is nan - then these rows will be filled with the LSTM estimate..
% ALL OF THIS PRESUMES AND DEMANDS THAT THE TIME STEP BETWEEN ROWS IS THE
% SAME for each row - an unwavering sampling rate.
% Upshot so far: very sensitive to the design of the trainning set and I
% found it difficult to replicate sucesses. It does fit. It does predict-
% better than chance, but highly doubtful that it is any better and
% probably a lot worse than ARIMA or sgolayfilt or other things.
% There is more to learn here though - especially the specific applications
% to regression.
% TODO https://www.mathworks.com/help/deeplearning/ug/long-short-term-memory-networks.html
% Cowen 2023
if nargin ==0
    %%
    clearvars
    close all
    % NOTES: does as advertised but does not generalize to signals with
    % different underlying oscillations - which would be expected.
    % If trained on input patterns like a chirp, it is perhaps more likely
    % that it would learn to generalize across frequencies. That might be a
    % smart way to train the network - insert a sin with a varying
    % frequency and amplitude - give it a range of interest say 6 to 40 Hz.
    % Still not convinced any of this would be better than a common sense
    % polynomial fit or sgolay filter.

    % Why is the starting point for each prediction block zero? This is a
    % problem - seems like the prediction for the test set is not working.
    % how does it deal with NANs?
    n_bins_to_predict = 200;
    lstm_n_params = 100;
    n_epoch = 2200;
    pad_dir = 'left';
    sz = 1000;
    % Demonstration on how this works...
    % Create artificial data.
    t_and_data = [[0:.1:sz]' sin((0:.1:sz)'/10) cos((0:.1:sz)'/14)];
    t_and_data(:,2) = t_and_data(:,2) + randn(size(t_and_data(:,2)))*.4 + sin((0:.1:sz)'/100);
    t_and_data(:,3) = t_and_data(:,3) + randn(size(t_and_data(:,3)))*.6 + sin((0:.1:sz)'/140);;
    t_and_data(:,4) = t_and_data(:,2).*t_and_data(:,3);

    mn = mean(t_and_data(:,2:end));
    sd = std(t_and_data(:,2:end));
    t_and_data_z = t_and_data;
    t_and_data_z(:,2:end) = (t_and_data_z(:,2:end) - mn)./sd;

    % Create test set
    %     t_and_data_test = [[0:.1:sz]' sin((0:.1:sz)'/7) cos((0:.1:sz)'/19)];
    t_and_data_test = [[0:.1:sz]' sin((0:.1:sz)'/10) cos((0:.1:sz)'/14)];
    t_and_data_test(:,2) = t_and_data_test(:,2) + randn(size(t_and_data_test(:,2)))*.4 + sin((0:.1:sz)'/100);
    t_and_data_test(:,3) = t_and_data_test(:,3) + randn(size(t_and_data_test(:,3)))*.6 + sin((0:.1:sz)'/140);;
    t_and_data_test(:,4) = t_and_data_test(:,2).*t_and_data_test(:,3);

    mn_test = mean(t_and_data_test(:,2:end));
    sd_test = std(t_and_data_test(:,2:end));
    t_and_data_z_test = t_and_data_test;
    t_and_data_z_test(:,2:end) = (t_and_data_z_test(:,2:end) - mn_test)./sd_test;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    numChannels = Cols(t_and_data)-1;

    % Create the training data.

% look into this https://www.mathworks.com/help/deeplearning/ug/sequence-to-sequence-regression-using-deep-learning.html
% lstmLayer(lstm_n_params,'OutputMode','sequence') - this seems like where
% things should go.... but not what is used on one demo.
    layers = [
        sequenceInputLayer(numChannels)
        lstmLayer(lstm_n_params)  
        fullyConnectedLayer(numChannels)
        regressionLayer];

    options = trainingOptions("adam", ...
        MaxEpochs=n_epoch, ...
        SequencePaddingDirection=pad_dir, ...
        Shuffle="every-epoch", ...
        Plots="training-progress", ...
        Verbose=0);
    % gpuDevice
    % ExecutionEnvironment 'cpu'
    INse1 = []; INse2 = [];
    IN = t_and_data_z(:,2:end)';
    TEST = t_and_data_z_test(:,2:end)';

    edges = 1:n_bins_to_predict:(Cols(IN)-n_bins_to_predict);
    INse1(:,1) = [edges(1:2:length(edges))]';
    INse1(:,2) = INse1(:,1) + n_bins_to_predict -1;
    INse2(:,1) = [edges(2:2:length(edges))]';
    INse2(:,2) = INse2(:,1) + n_bins_to_predict-1;
    INse1 = INse1(1:Rows(INse2),:);
    % to improve training - it could grab just adjactent bins but slide
    % over so increase the sample considerably. Right now, the training set
    % is quite small.
    INstep1 = [];INstep2 = [];

    set_cnt = 1;
    IN(:,end:end+1000) = IN(:,1:1001);
    for ii = 1:Rows(INse1)
        IN1{ii} = IN(:,INse1(ii,1):INse1(ii,2));
        IN2{ii} = IN(:,INse2(ii,1):INse2(ii,2));
        IN1test{ii} = TEST(:,INse1(ii,1):INse1(ii,2));
        IN2test{ii} = TEST(:,INse2(ii,1):INse2(ii,2));
%         for ishift = 0:50:200
          ishift = 0;
            INstep1{set_cnt} = IN(:,ishift + (INse1(ii,1):INse1(ii,2)));
            INstep2{set_cnt} = IN(:,ishift + (INse2(ii,1):INse2(ii,2)));
            %
%             INstep1test{set_cnt} = TEST(:,ishift + (INse1(ii,1):INse1(ii,2)));
%             INstep2test{set_cnt} = TEST(:,ishift + (INse2(ii,1):INse2(ii,2)));
            set_cnt = set_cnt + 1;
%         end
    end

    net = trainNetwork(INstep1,INstep2,layers,options);
%      net = trainNetwork(IN1,IN2,layers,options);
    figure
    subplot(2,1,1)
    plot(IN','k')
    hold on
    subplot(2,1,2)
    plot(TEST','k')
    hold on
        resetState(net)

    [net] = predictAndUpdateState(net,INstep1{1},SequencePaddingDirection=pad_dir);

    for ii = 1:Rows(INse1)
        %          YTest = predict(net,INstep1{ii},SequencePaddingDirection=pad_dir);
        [net,YTest] = predictAndUpdateState(net,IN1{ii},SequencePaddingDirection=pad_dir);
        %         resetState(net)
        subplot(2,1,1)
        plot(INse1(ii,1):INse1(ii,2), IN1{ii}')
        plot(INse2(ii,1):INse2(ii,2), YTest','LineWidth',4)
        title('Train Set')
    end
    resetState(net)
    [net] = predictAndUpdateState(net,INstep1{1},SequencePaddingDirection=pad_dir);
    for ii = 1:Rows(INse1)
%         YTest2 = predict(net,INstep1test{ii},SequencePaddingDirection=pad_dir);
        [net,YTest2] = predictAndUpdateState(net,IN1{ii},SequencePaddingDirection=pad_dir);
        subplot(2,1,2)
        plot(INse1(ii,1):INse1(ii,2), IN1test{ii}')
        plot(INse2(ii,1):INse2(ii,2), YTest2','LineWidth',4)
        title('Test Set')
    end
    % net = trainNetwork(t_and_data_z(1:2:end-1,2:end)',t_and_data_z(2:2:end,2:end)',layers,options);
end

