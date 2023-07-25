function NPXL_Denoise_ap_bin_file(varargin)
% function NPXL_Denoise_ap_bin_file(varargin)
%
% BE SURE TO RUN THIS ON A tcat.ap.bin file - not the original data file as
% CatGT does some subtle but important inter-channel aligments.
%
% Assumes https://github.com/djoshea/neuropixel-utils is in your GitHub
% Uses regression from channels distant to the target to predict activity
% at the target channel. The residuals from this prediction become the new
% cleaned data. This gets rid of a lot of common noise and also
% zero-aligns.
% TODO: have it read the meta file and add the bad channels in this file to
% the list.
% Assumes CowenLib
% NEED: https://github.com/djoshea/neuropixel-utils
%
% IDEAS: Maybe it would work better if a new model is made for each block.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PRM_NEUROPIXEL_UTILS_DIR = fullfile(Git_dir,'neuropixel-utils'); % if this works for you, go for it
% Otherwise, do this if you do not have the folder.
% PRM_NEUROPIXEL_UTILS_DIR = 'C:\Users\cowen\Documents\GitHub\neuropixel-utils';
addpath(PRM_NEUROPIXEL_UTILS_DIR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Things that will change with each dataset
%
PRM_BIN_FNAME = [];
d = dir(fullfile(pwd,'*.ap.bin'));
if length(d)==1
    PRM_BIN_FNAME = fullfile(pwd,d(1).name); % Should be a tcat file.
else
    %     error('Could not find only one bin file here')
end
PRM_ADDITIONAL_BAD_CHANNELS0 = []; % Remember, channels in spikeGLX are 0-based, not 1. That's what the 0 means.
% channelMapFile: The file that codes for the probe. If you have a tetrode neuropixels
% config, you will need something different
CHANNEL_MAP_FILE = 'C:\Neuropixels\Kilosort-2.0\configFiles\neuropixPhase3B2_kilosortChanMap.mat';
% PRM_CLEANED_PATH: where the processed .ap.bin file will go...
% PRM_CLEANED_PATH = 'C:/Temp/Denoised'; % Where the processed data should go.
% PRM_PERFORM_CAR_BEFORE_REGRESSION = false; % Does CAR before proceding and creates a new denoised copy of the mec file.
PRM_REMOVE_COINCIDENCES = true; % removes (or fills) data when an artifact was simultaneously detected on multiple channles.
PRM_FILL_ARTIFACT_WITH_RESIDUALS = true; % takes time, but fills the artifact areas with the residuals of a prediction from the other channels.
PLOT_IT = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Other control parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_training_data = 8000; % enough to train the model. Probably only really need 800
regression_type = 'linear'; % stepwise linear fitrlinear quadratic, LINEAR is best so far.
blocksize_min = 1;
forbidden_radius = 5; % do not use these points for regression
outer_radius = 25; % use up to this radius of points for regression.
% For coincidence artifact detection should you decide to use it.
z_thresh = 3; % has to be above thresh AND on n_chan_thresh to be counted.
n_chan_thresh = 25; % has to be above z threshold this many channels simultaneously.
points_to_blank = 15; % points around crossing to eliminate.

Extract_varargin;
tic
if ~exist(PRM_BIN_FNAME,'file')
    PRM_BIN_FNAME
    error('Could not find file')
end
PRM_DATA_DIR = fileparts(PRM_BIN_FNAME);
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Things that should not change. %%%%%%%%%%%%%%%
blocksize_recs = 30000*60*blocksize_min;

% Read in dta and the meta file.
imec = Neuropixel.ImecDataset(PRM_BIN_FNAME, 'channelMap',CHANNEL_MAP_FILE);
extraMeta.processing_function = [];
[channelInds, channelIds] = imec.lookup_channelIds(imec.channelIds);
hrs = (double(imec.nSamplesAP)/30000)/3600;
% Make sure we are't wasting our time on bad data...
imec.markBadChannelsByRMS('rmsRange', [3 100]); % [low high] range of RMS in uV
%Maybe need to add one here
[more_bad_channelInds, more_bad_channelIds] = imec.lookup_channelIds(PRM_ADDITIONAL_BAD_CHANNELS0(:)+1);
imec.markBadChannels(unique(more_bad_channelInds));
% sd = std(single(mmap.Data.x(:,1:40000:end)),1,2); % another way to do
%
% Set the bad channels to zero. - Don't I just set the inds to zero? Seems
% obvious.
badchanMask  = ismember(channelInds, imec.badChannels);
% badChannels  = channelIds(badchanMask);
% goodChannels = setdiff(imec.channelIds,imec.badChannels);
chanMask = ~badchanMask; % Don't forget that the last channel is the sync.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mmap the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mmap = imec.memmapAP_full('Writable', true);

if any(badchanMask)
    fprintf( 'Zeroing out bad channels in %f hrs of total data. \n',hrs)
    mmap.Data.x(badchanMask,:) = 0;
end
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
allB = cell(length(chanMask),1);
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
            allB{row_ix} = mod{row_ix}.Coefficients.Estimate; % includes beta.
            %             [B b0] = fitlm_get_coefficients(mod{row_ix},Rows(train_data));
            %             allB(row_ix,:) = [b0 B]; % Wait- it needs to be shifted
            % still takes up space so the following gets us what we need...
            %             COEF{row_ix} = mod{row_ix}.Coefficients.Estimate; % includes intercept
        case 'purequadratic' % quadratic alone OVERFITS!!! First pass - this is MUCH better than linear and svm. Slow. bout 5x slower than linear.
            mod{row_ix} = fitlm(train_data(permitted_ch_mask,:)',train_data(row_ix,:)','purequadratic'); % get a lot of rank defficient errors. Not sure why.
            mod{row_ix} = compact(mod{row_ix}); %saves a lot of space
            % still takes up space so the following gets us what we need...
            %             COEF{row_ix} = mod{row_ix}.Coefficients.Estimate; % includes intercept
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

extraMeta.rms_before_regress = rms(test_data');
extraMeta.rms_after_regress = rms(res');

fprintf('Noise model complete. Median RMS before: %f RMS after: %f \n',median(extraMeta.rms_before_regress), median(extraMeta.rms_after_regress) )


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
clear res train_data test_data;

%% Apply the model to the data.
% This is slow and can be improved.
blocks = 1:blocksize_recs:double(imec.nSamplesAP);
blocks(end) = double(imec.nSamplesAP);
for iB = 1:(length(blocks)-1)

    orig_data = mmap.Data.x(channelInds,blocks(iB):blocks(iB+1)); % access a specific block
    y_hat = zeros(size(orig_data),'int16'); % to save memory, I could do this row by row, not copy the entire matrix.
    % 1.7 sec
    %     orig_data = gpuArray(orig_data); % not sure if it works - be careful it does not kill the regression.
%           tic
    % This loop is very slow and memory intensive. Tried parfor and does not
    % work. Maybe if I used a cell array? I doubt it though as it woudl run
    % out of memory. Gould try GPU array and that sped things up, but it
    % crashed so probably not worth it.
    for iCh = 1:length(good_ch_ix)
        row_ix = good_ch_ix(iCh);
        % Here I could generate a new model for each block and apply.
        %         y_hat(row_ix,:) = int16(predict(mod{row_ix},single(orig_data(all_ch_mask{row_ix},:))')');
        % feval is about the same speed as predict
        %         y_hat(row_ix,:) = int16(feval(mod{row_ix},single(orig_data(all_ch_mask{row_ix},:))')');
        % the multipleicatio below is about 20% faster than either feval
        % or predict. Won't make a huge difference, but it's defintely
        % something and now you don't need the 'mod' variables which are
        % somewhat memory intensive.
        y_hat(row_ix,:) = int16((allB{row_ix})'*[ones(Cols(orig_data),1,'single') single(orig_data(all_ch_mask{row_ix},:))']');
    end
%           toc
    % 215.482828 sec with predict, similar 214 sec with feval. Mihgt be a
    % lot faster with gpuarray. 20 sec with gpuArray. Too bad it crashes
    if PRM_REMOVE_COINCIDENCES
        % an additional thing we can do now that the data is cleaned is to
        % blank out times where more than a certain portion of channels had an
        % artifact.
        extraMeta.remove_coincidences = true;
        res = orig_data-y_hat; % overwrite to save space
        % note - bsxfun might speed this up. Z scores and other things.
        if 0
            tic
            SIX = abs(Z_scores(single(res'))')>z_thresh;
            BIX = sum(SIX) > n_chan_thresh; % the columns that have coincidences
            BIX = convn(BIX(:),ones(points_to_blank,1),"same")'>0;
            SIX(:,~BIX) = false; % clear out the threshold crossings without cross-channel coincidences.
            SIX = convn(SIX',ones(points_to_blank,1),"same")'>0;
            toc % 30 seconds
        else
            % FYI: gpuArray can't take the memory requirement here.
            SIX = abs(((single(res'))-mean(single(res')))./std(single(res')))' > z_thresh;
            BIX = sum(SIX) > n_chan_thresh; % the columns that have coincidences
            BIX = conv(BIX(:), ones(points_to_blank,1),"same")'>0;
            SIX(:,~BIX) = false; % clear out the threshold crossings without cross-channel coincidences.
            SIX = convn(SIX', ones(points_to_blank,1),"same")'>0; % Slower. Can't get bsxfun to work on this - dkw
            
        end
        if 0
            f = find(BIX);
            if ~isempty(f)
                figure(101)
                clf
                subplot (3,1,1)
                imagesc(SIX(:,(f(1)):(f(end))))
                subplot (3,1,2)
                imagesc(res(:,(f(1)):(f(end))))
                clim([-15 15])
                subplot (3,1,3)
                plot(res(1:20:end,:)')
                hold on
                plot(find(BIX),ones(sum(BIX),1),'r.')
                axis tight
                drawnow
            end
        end
        if PRM_FILL_ARTIFACT_WITH_RESIDUALS
            if 0
                % plot all the data SIX before
                figure(102)
                clf
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
            if 0
                % plot all the data SIX before
                figure(102)
                hold on
                v = res(SIX);
                plot(v(:))
                SIXo = SIX;
            end
            SIX = abs(((single(res'))-mean(single(res')))./std(single(res')))' > z_thresh;
            %             SIX = abs(Z_scores(single(res'))')>z_thresh;
            BIX = sum(SIX) > n_chan_thresh; % the columns that have coincidences
            BIX = conv(BIX(:),ones(points_to_blank,1),"same")'>0;
            SIX(:,~BIX) = false; % clear out the threshold crossings without cross-channel coincidences.
            SIX = convn(SIX',ones(points_to_blank,1),"same")'>0;
            % TODO: merge intervals that are within x points of each other.
            % prob 30sec
            res(SIX) = 0;
            if 0
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
% Would be good to test RMS yet again.
test_data = single(mmap.Data.x(channelInds,test_ix)); 
extraMeta.rms_final = rms(test_data');

% update the meta file...
imec.writeModifiedAPMeta(); % not sure if I need to call this or if it will be done autmatically wiht the extrameta thing.

toc_time = toc;
fprintf('\n NPXL_Denoise_ap_bin_file: %f hours to process %f hours of recording. Final RMS: %3.3f\n', toc_time/3600, single(imec.nSamplesAP)/30000/3600, median(extraMeta.rms_final))

extraMeta.cleaned = true;
extraMeta.cleaningAlgorithm = regression_type;
extraMeta.processing_time_hrs = toc_time/3600;
extraMeta.processing_function = 'NPXL_Denoise_ap_bin_file';

imec.writeModifiedAPMeta('extraMeta', extraMeta);

fclose all; % Seems to ensure that the imec data is written to disk I think.
if 0
    % verify that the final data is truly cleaned and updated.
    %     imec_orig = Neuropixel.ImecDataset(PRM_BIN_FNAME, 'channelMap',CHANNEL_MAP_FILE);
    % %     mmap_orig = imec_orig.memmapAP_full();
    channelInds = 1:384;
    ix = 100000:200000;
    %     orig = mmap_orig.Data.x(channelInds,ix)';
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if ~exist(PRM_CLEANED_PATH,'dir')
%     mkdir(PRM_CLEANED_PATH)
% else
%     if length(fullfile(PRM_CLEANED_PATH,'*.bin')) > 0
%         if strcmpi(input('You sure you want to delete the processed .bin and .mat? [y,n]',"s"),'y')
%             delete(fullfile(PRM_CLEANED_PATH,'*.bin'))
%             delete(fullfile(PRM_CLEANED_PATH,'*.meta'))
%         end
%     end
% end
% tic;

% if PRM_PERFORM_CAR_BEFORE_REGRESSION % I don't think that this is necessary.
%     % Wouldn't it be more efficient just to do this in the main loop?
%     imec = Neuropixel.ImecDataset(fname_in_bin, 'channelMap',CHANNEL_MAP_FILE);
%     disp('Performing CAR before regression.')
%     % This helps a lot. In fact, it might not be that
%     % worth it to do the regression - improves but not by that much. The
%     % artifact removal really helps.
%     %          fnList = {@Neuropixel.DataProcessFn.commonAverageReference};
%     fnList = {@Neuropixel.DataProcessFn.commonAverageReferenceMovMean};
%
%     imec = imec.saveTransformedDataset(PRM_CLEANED_PATH, 'transformAP', fnList);  %'gpuArray',false - default - does not seem to work
%     disp('Finished CAR.')
%     extraMeta.performed_CAR = true;
%     extraMeta.processing_function = fnList;
% else