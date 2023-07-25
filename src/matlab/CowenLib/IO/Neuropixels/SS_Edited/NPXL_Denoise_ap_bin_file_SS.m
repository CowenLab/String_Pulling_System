function NPXL_Denoise_ap_bin_file_SS(varargin)
%
% 
% Assumes https://github.com/djoshea/neuropixel-utils is in your GitHub
% Uses regression from channels distant to the target to predict activity
% at the target channel. The residuals from this prediction become the new
% cleaned data. This gets rid of a lot of common noise and also
% zero-aligns. 
%
% Assumes CowenLib
%
% IDEAS: Maybe it would work better if a new model is made for each block.
% 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fclose all;
clearvars
% NEED: https://github.com/djoshea/neuropixel-utils 
NEUROPIXEL_UTILS_DIR = fullfile(Git_dir,'neuropixel-utils'); % if this works for you, go for it
% Otherwise, do this if you do not have the folder.
% NEUROPIXEL_UTILS_DIR = 'C:\Users\cowen\Documents\GitHub\neuropixel-utils';
addpath(NEUROPIXEL_UTILS_DIR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Things that will change with each dataset
% bin_fname = 'mouse_bank0_run3_g0_t0.imec0.ap.bin';
% data_dir = 'G:\Data\Transcranial_Optogenetics\Mouse5\1\mouse_bank0_run3_g0\mouse_bank0_run3_g0_imec0';
% additional_bad_channels = [42 138 280 281 286 293 355 373 377 ]; % APx Values on SpikeGLX start at ZERO so add one to these values.

%%%%%%%%%Change the following parameters to const if you dont want to use it in post process function 

bin_fname = 'mPFC_L23_PP3_g0_tcat.imec0.ap.bin';

data_dir = "F:\Data\vHPC_stim_mPFC_excitability_project\vHC_StimCoordinate_test\10831\mPFC_L23_PP3_g0\mPFC_L23_PP3_g0_imec0";


cleanedPath = 'F:\Denoised\10831\3_PP'; % Where the processed data should go. ie the ap.bin file

additional_bad_channels = [25 96 122 192 133 212 230 340 ];

% The file that codes for the probe. If you have a tetrode neuropixels
% config, you will need something different
channelMapFile = 'C:\Users\CowenLab\Documents\GitHub\Kilosort\configFiles\vHP_DV7pt2_mPFC_DV7_tetrodeconfig_g0_tcat0x2Eimec00x2Eap_kilosortChanMap.mat';


% how cleaning will be performed.
perform_car_before_regression = true; % Does CAR before proceding and creates a new denoised copy of the mec file.
remove_coincidences = true; % removes (or fills) data when an artifact was simultaneously detected on multiple channles.
fill_artifact_with_residuals = true; % takes time, but fills the artifact areas with the residuals of a prediction from the other channels.
% skip_copy = true; % you already copied the data to cleanedPath and just want to start...
% cleanedPath = fullfile(data_dir,'Denoised'); % put it in the data dir.PRM_

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Things that may or may not change.
PLOT_IT = true;
n_training_data = 10000; % enough to train the model. Probably only really need 800
regression_type = 'linear'; % stepwise linear fitrlinear quadratic, LINEAR is best so far.
blocksize_min = 2;
forbidden_radius = 5; % do not use these points for regression
outer_radius = 23; % use up to this radius of points for regression.
% For coincidence artifact detection should you decide to use it.
z_thresh = 3; % has to be above thresh AND on n_chan_thresh to be counted.
n_chan_thresh = 30; % has to be above z threshold this many channels simultaneously.
points_to_blank = 15; % points around crossing to eliminate.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Things that should not change.
blocksize_recs = 30000*60*blocksize_min;
fname_in_bin = fullfile(data_dir, bin_fname);
fname_in_meta = strrep(fname_in_bin,'.bin','.meta');
% This is where the data will go...
[p,n] = fileparts(cleanedPath);
fname_out_bin = fullfile(cleanedPath, [n '.imec.ap.bin']);
fname_out_meta = strrep(fname_out_bin,'.bin','.meta');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist(cleanedPath,'dir')
    mkdir(cleanedPath)
else
    if length(fullfile(cleanedPath,'*.bin')) > 0
        if strcmpi(input('You sure you want to delete the processed .bin and .mat? [y,n]',"s"),'y')
            delete(fullfile(cleanedPath,'*.bin'))
            delete(fullfile(cleanedPath,'*.meta'))
        end
    end
end
tic;
% if skip_copy
%     disp('Skipping copying of file.')
% else
%     % Copy the data to this directory first and the work with and write to this
%     % data.
% 
%     disp('Copying files: this may take a while.')
%     % matlab's copyfile just does not work sometimes. Use xcopy.
%     sysout = system(sprintf('xcopy %s %s /Y /-I',fname_bin,fname_in_bin ));
%     sysout = system(sprintf('xcopy %s %s /Y /-I',fname_meta,fname_in_meta ));
%     % copyfile(fname_bin, fname_in_bin,'f')
%     % copyfile(fname_meta, fname_in_meta,'f')
% end

if perform_car_before_regression % I don't think that this is necessary.
    % Wouldn't it be more efficient just to do this in the main loop?
    imec = Neuropixel.ImecDataset(fname_in_bin, 'channelMap',channelMapFile);
    disp('Performing CAR before regression.')
    % This helps a lot. In fact, it might not be that
    % worth it to do the regression - improves but not by that much. The
    % artifact removal really helps. 
              fnList = {@Neuropixel.DataProcessFn.commonAverageReference};
    %fnList = {@Neuropixel.DataProcessFn.commonAverageReferenceMovMean};
    
    imec = imec.saveTransformedDataset(cleanedPath, 'transformAP', fnList);  %'gpuArray',false - default - does not seem to work
    disp('Finished CAR.')
    extraMeta.performed_CAR = true;
    extraMeta.processing_function = fnList;
else
    % Presume that the out file has already been created.
    imec = Neuropixel.ImecDataset(fname_out_bin, 'channelMap',channelMapFile);
    extraMeta.processing_function = [];
    extraMeta.performed_CAR = false;
end
% imec.channelIds
[channelInds, channelIds] = imec.lookup_channelIds(imec.channelIds);
hrs = (double(imec.nSamplesAP)/30000)/3600;
% Make sure we are't wasting our time on bad data...
imec.markBadChannelsByRMS('rmsRange', [3 100]); % [low high] range of RMS in uV
[more_bad_channelInds, more_bad_channelIds] = imec.lookup_channelIds(additional_bad_channels(:));
imec.markBadChannels(unique(more_bad_channelInds));
% sd = std(single(mmap.Data.x(:,1:40000:end)),1,2); % another way to do
%
% Set the bad channels to zero.
badchanMask  = ismember(channelInds, imec.badChannels);
badChannels  = channelIds(badchanMask);
goodChannels = setdiff(imec.channelIds,imec.badChannels);
chanMask = ~badchanMask; % Don't forget that the last channel is the sync.

% mmap the data
mmap = imec.memmapAP_full('Writable', true);

fprintf( 'Zeroinng out bad channels in %f hrs of total data. \n',hrs)

mmap.Data.x(badchanMask,:) = 0;
% The first time mmap is called, it can take a while.
train_ix   = round(linspace(1,double(imec.nSamplesAP),n_training_data)); % 1000 points is good enough for the model
train_data = single(mmap.Data.x(channelInds,train_ix)); % access a specific sample
test_ix   = round(linspace(30000,double(imec.nSamplesAP),n_training_data)); % 1000 points is good enough for the model
test_data = single(mmap.Data.x(channelInds,test_ix)); % access a specific sample
% Make the models...
disp('Starting model creation.')
good_ch_ix = find(chanMask);
mod = cell(length(chanMask),1);
all_ch_mask = cell(length(chanMask),1);
y_hat = zeros(size(train_data),'single');
good_ch_ix(good_ch_ix == 385) = []; % make ch 385 a 'bad channel' as this contains the sync pulse.

for iCh = 1:length(good_ch_ix)
    row_ix = good_ch_ix(iCh);
    permitted_ch_mask = channelInds < (row_ix-forbidden_radius) | channelInds > (row_ix+forbidden_radius);
    permitted_ch_mask = permitted_ch_mask & chanMask; % get rid of bad channels
    permitted_ch_mask(end) = false; % get rid of the sync channel.
    bad_outer = channelInds > (row_ix+outer_radius) | channelInds < (row_ix-outer_radius);
    permitted_ch_mask = permitted_ch_mask & ~bad_outer;
    all_ch_mask{row_ix} = permitted_ch_mask; % need this for saving and running on the full dataset.
    if sum(permitted_ch_mask) < 3
        disp('WARNING: too few channels for regression. Not creating a model.')
        row_ix
        mod{row_ix} = [];
        continue
    end
    warning off        % Consequently, it might be best just to compute a new model for
    % each block OR just compute it once? Not sure.
    % todo maybe: I would think models would work better if they
    % incorporated time or at least the derivative. 
    switch regression_type
        case 'fitrlinear'
            % This should be faster and also uses SVM. Should be better for
            % large datasets. Should... On first pass it does not look any
            % difference than the regression fitlm approach - in fact it
            % was a little worse on the test set.
            mod{row_ix} = fitrlinear(train_data(permitted_ch_mask,:)',train_data(row_ix,:)'); 
            %             mod{row_ix} = compact(mod{row_ix});
        case 'linear_fast'
            % Maybe this is faster. You need the ones to get the
            % intercept.
            X = [ones(size(train_data,2),1), train_data(permitted_ch_mask,:)'];
            B = X\train_data(row_ix,:)'; % yhat = X*B I think
        case 'linear' % !! BEST !! seems to do best - even better than vanilla fitrlinear
            %,'RobustOpts','on' % does not seem to help at all.
            mod{row_ix} = fitlm(train_data(permitted_ch_mask,:)',train_data(row_ix,:)'); % get a lot of rank defficient errors. Not sure why.
            mod{row_ix} = compact(mod{row_ix}); %saves a lot of space
            % still takes up space so the following gets us what we need...
            %             COEF{row_ix} = mod{row_ix}.Coefficients.Estimate; % includes intercept
        case 'purequadratic' % quadratic alone OVERFITS!!! First pass - this is MUCH better than linear and svm. Slow. bout 5x slower than linear.
            %,'RobustOpts','on' % does not seem to help at all.
            % PERHAPS it would do better if I gave it a bigger dataset to
            % limit overfitting.
            mod{row_ix} = fitlm(train_data(permitted_ch_mask,:)',train_data(row_ix,:)','purequadratic'); % get a lot of rank defficient errors. Not sure why.
            mod{row_ix} = compact(mod{row_ix}); %saves a lot of space
            % still takes up space so the following gets us what we need...
            %             COEF{row_ix} = mod{row_ix}.Coefficients.Estimate; % includes intercept
        case 'stepwise' % slow - maybe 30x slower than linear when dataset is large. Does not seem to be worth the time.
            mod{row_ix} = stepwiselm(train_data(permitted_ch_mask,:)',train_data(row_ix,:)','Verbose',0);
            mod{row_ix} = compact(mod{row_ix});
        otherwise
            error('unknown regression type.')
    end
    warning on
    %     y_hat(row_ix,:) = int16(predict(mod{row_ix},data(permitted_ch_mask,:)'))';
    % feval is a tiny bit faster I believe than predict
    %      y_hat(row_ix,:) = int16(data(permitted_ch_mask,:)'*B)';
    y_hat(row_ix,:) = predict(mod{row_ix},test_data(permitted_ch_mask,:)')';
end
res = test_data - y_hat;

disp('Model creation complete.')
extraMeta.rms_before_regress = rms(test_data');
extraMeta.rms_after_regress = rms(res');


if PLOT_IT
    figure
    subplot(2,1,1)
    plot(train_data(1:3,:)','k')
    hold on
    plot(res(1:3,:)','r')

    subplot(2,1,2)
    plot(rms(train_data'))
    hold on
    plot(rms(res'))
    title(sprintf('mean rms %f', mean(rms(res))))
    xlabel('ch')
end
clear res train_data;

%% Apply the model to the data.
blocks = 1:blocksize_recs:double(imec.nSamplesAP);
blocks(end) = double(imec.nSamplesAP);
for iB = 1:(length(blocks)-1)
    orig_data = mmap.Data.x(channelInds,blocks(iB):blocks(iB+1)); % access a specific block
    y_hat = orig_data*0; % to save memory, I could do this row by row, not copy the entire matrix.
    % but this would likely slow things down as I woul dhave to save
    % results each row.
    % perform the model action on these data... NOTE: feval does not work
    % on compact models.
    for iCh = 1:length(good_ch_ix)
        row_ix = good_ch_ix(iCh);
        y_hat(row_ix,:) = int16(predict(mod{row_ix},single(orig_data(all_ch_mask{row_ix},:))')');
        %         y_hat(row_ix,:) = int16(feval(mod{row_ix},single(orig_data(all_ch_mask{row_ix},:))')');
    end
    if remove_coincidences
        % an additional thing we can do now that the data is cleaned is to
        % blank out times where more than a certain portion of channels had an
        % artifact.
        extraMeta.remove_coincidences = true;
        res = orig_data-y_hat; % overwrite to save space
        SIX = abs(Z_scores(single(res'))')>z_thresh;
        BIX = sum(SIX) > n_chan_thresh; % the columns that have coincidences
        BIX = convn(BIX(:),ones(points_to_blank,1),"same")'>0;
        SIX(:,~BIX) = false; % clear out the threshold crossings without cross-channel coincidences.
        SIX = convn(SIX',ones(points_to_blank,1),"same")'>0;
        if PLOT_IT
            f = find(BIX);
            if ~isempty(f)
                figure(101)
                clf
                subplot (3,1,1)
                imagesc(SIX(:,(f(1)):(f(end))))
                subplot (3,1,2)
                imagesc(res(:,(f(1)):(f(end))))
                caxis([-15 15])
                subplot (3,1,3)
                plot(res(1:20:end,:)')
                hold on
                plot(find(BIX),ones(sum(BIX),1),'r.')
                axis tight
                drawnow
            end
        end
        if fill_artifact_with_residuals
            if PLOT_IT
                % plot all the data SIX before
                figure(102)
                v = res(SIX);
                plot(v(:))
                hold on
            end
            for iCh = 1:length(good_ch_ix)
                row_ix = good_ch_ix(iCh);
                if sum(SIX(row_ix,:)) > 10
                    X = res(all_ch_mask{row_ix},SIX(row_ix,:))';
                    y = res(row_ix,SIX(row_ix,:))';
                    %                     plot(y)
                    m = fitrlinear(single(X), single(y));
                    %                     p = predict(m,single(X))
                    res(row_ix,SIX(row_ix,:)) = int16(single(res(row_ix,SIX(row_ix,:))) - predict(m,single(X))');
                else
                    res(row_ix,SIX(row_ix,:)) = 0;
                end
                %         y_hat(row_ix,:) = int16(feval(mod{row_ix},single(orig_data(all_ch_mask{row_ix},:))')');
            end
            % If there are still artifacts, convert them to zeros
            if PLOT_IT
                % plot all the data SIX before
                figure(102)
                hold on
                v = res(SIX);
                plot(v(:))
                SIXo = SIX;
            end
            SIX = abs(Z_scores(single(res'))')>z_thresh;
            BIX = sum(SIX) > n_chan_thresh; % the columns that have coincidences
            BIX = convn(BIX(:),ones(points_to_blank,1),"same")'>0;
            SIX(:,~BIX) = false; % clear out the threshold crossings without cross-channel coincidences.
            SIX = convn(SIX',ones(points_to_blank,1),"same")'>0;
            % TODO: merge intervals that are within x points of each other.

            res(SIX) = 0;
            if PLOT_IT
                % plot all the data SIX before
                figure(102)
                hold on
                v = res(SIXo);
                plot(v(:))
                legend('before svm','after svm', 'zero')
            end


        else
            % convert artifact areas to just zeros... Faster, but probably
            % not as good.
            res(SIX) = 0;
        end
        mmap.Data.x(channelInds,blocks(iB):blocks(iB+1)) = res;

    else
        % save some time and memory if you do not have coincident artifact.
        mmap.Data.x(channelInds,blocks(iB):blocks(iB+1)) = orig_data-y_hat;
        extraMeta.remove_coincidences = false;

    end
    fprintf('%d/%d,',iB,(length(blocks)-1))
end
%%
fclose all; % Seems to ensure that the data is written to disk I think.
% update the meta file...
toc_time = toc;
imec.writeModifiedAPMeta(); % not sure if I need to call this or if it will be done autmatically wiht the extrameta thing.
extraMeta.cleaned = true;
extraMeta.cleaningAlgorithm = regression_type;
extraMeta.processing_time_hrs = toc_time/3600;
extraMeta.processing_function = 'NPXL_Denoise_ap_bin_file';

imec.writeModifiedAPMeta('extraMeta', extraMeta);

fprintf('\nThat took %f hours to process %f hours of recording.\n', toc_time/3600, single(imec.nSamplesAP)/30000/3600)
if PLOT_IT
    % verify that the final data is truly cleaned and updated.
    imec_orig = Neuropixel.ImecDataset(fname_in_bin, 'channelMap',channelMapFile);
    mmap_orig = imec_orig.memmapAP_full();
    channelInds = 1:384;
    ix = 100000:200000;
    orig = mmap_orig.Data.x(channelInds,ix)';
    new = mmap.Data.x(channelInds,ix)';

    figure
    subplot(2,1,1)
    plot(orig,'k')
    hold on
    plot(new,'r')

    subplot(2,1,2)
    plot(rms(orig))
    hold on
    plot(rms(new))
    title(sprintf('mean rms old %f new %f', mean(rms(orig)), mean(rms(new))))
    xlabel('ch')
end