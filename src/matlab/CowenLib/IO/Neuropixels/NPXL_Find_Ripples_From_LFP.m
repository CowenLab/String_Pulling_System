function [OUT] = NPXL_Find_Ripples_From_LFP(lfp_bin_file_path, sleep_intervals_sec, hpc_channels_ix )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% much to do here -but something tells me someone has already done all of
% this.
% Cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% channels = 1:10:384; Hi Stephen, I estimated that the hippocampus, CA3 to CA1, spans from channels 65 to 235 on bank 1. Each bank is 3840 um with each recording site being 20 um. CA3 starts at about .65mm up bank 1, and CA3 and CA1 spans across the next 1.7mm up the bank
%%
if nargin == 0
    % for testing
    % rood file name without the .lf.bin 430_S2_g0_t0.imec0.lf.bin
    lfp_bin_file_path = 'G:\Data\NP_Time_Cells\session_4_g0\session_4_g0_imec0\session_4_g0_t0.imec0.lf.bin';
    sleep_intervals_sec = [60 60*20];
    hpc_channels_ix = 65:4:235;
    hpc_channels_ix = 1:2:384;
end
%%
all_channels = 1:385;
[path_name, tmp] = fileparts(lfp_bin_file_path);
lfp_fname = [tmp '.bin'];
meta_fname = strrep(lfp_fname,'.lf.bin','.lf.meta');
% Extract_varargin;
obj = SGLX_Class;
LFP.meta = obj.ReadMeta(meta_fname,path_name);
LFP.nChan = str2double(LFP.meta.nSavedChans);
LFP.sFreq = str2double(LFP.meta.imSampRate);
LFP.nFileSamp = str2double(LFP.meta.fileSizeBytes) / (2 * LFP.nChan);
LFP.duration_of_recording_sec = LFP.nFileSamp/LFP.sFreq;

mua_filt = designfilt('bandpassiir','FilterOrder',14, 'HalfPowerFrequency1',500,'HalfPowerFrequency2',1200,'SampleRate',LFP.sFreq);

% freqz(mua_filt)

if 1
    end_rec = round(LFP.duration_of_recording_sec*LFP.sFreq)-1;
    start_rec = round((LFP.duration_of_recording_sec-20*60)*LFP.sFreq);
else
    start_rec = round(sleep_intervals_sec(1)*LFP.sFreq);
    end_rec = round(sleep_intervals_sec(end)*LFP.sFreq);
end
n_samples = end_rec - start_rec + 1;
LFP.start_rec = start_rec;

% read the data. The last rec is typically the sync pulse.
[LFP.data_uV,LFP.meta] = obj.ReadBinVolts(start_rec,n_samples,LFP.meta ,lfp_fname,path_name); %(samp0, nSamp, meta, binName, path)
LFP.data_uV = LFP.data_uV*1e6;
LFP.data_uV = LFP.data_uV' -  movmean(LFP.data_uV',round(LFP.sFreq)*1.5);
LFP.data_uV = LFP.data_uV';

ABV = mean(abs(LFP.data_uV),2,'omitnan');
BAD_CH_IX =  ABV > 300 | ABV < 50;
LFP.data_uV(BAD_CH_IX,:) = nan;

LFP.t_uSec = 1e6*(linspace(start_rec, end_rec, Cols(LFP.data_uV))./LFP.sFreq)';

% Median re-reference
LFP.data_uV = LFP.data_uV - median(LFP.data_uV,1,'omitnan');
% Restrict to just the channels of interest
LFP.data_uV = LFP.data_uV(hpc_channels_ix,:);


RIP = []; INFO = []; Mn = []; EMU = [];
for iCh = 1:Rows(LFP.data_uV)
    if isnan( LFP.data_uV(iCh,1))
        RIP{iCh}.above_times_uS = [];
    else
        [RIP{iCh}] = Ripple_detector_cowen([LFP.t_uSec(:) LFP.data_uV(iCh,:)'],LFP.sFreq,'PLOT_IT',false );
    end
    if Rows(RIP{iCh}.above_times_uS) > 10
        %function [M, x_axis, fh, OUT, EEG_sec_data] = PETH_EEG(EEG_sec_data, sFreq ,alignments_ts_sec, time_before_sec, time_after_sec, option, option_parameters)
        % function [M, ix, x_sec] = PETH_EEG_simple(EEG_t_data, alignments_t, samples_before, samples_after,sFreq, PLOT_IT)
        pts = round(LFP.sFreq/4);
        [M,~,x_s] = PETH_EEG_simple([LFP.t_uSec(:)/1e6 double(LFP.data_uV(iCh,:)')],RIP{iCh}.above_times_uS(:,1)/1e6,pts,pts,LFP.sFreq,false);
        if isempty(Mn)
            Mn = zeros(Rows(LFP.data_uV),length(x_s));
            EMU = zeros(Rows(LFP.data_uV),length(x_s));
        end
        Mn(iCh,:) = movmean(mean(M),round(LFP.sFreq/100));

        % look at the mua...
        mu = filtfilt(mua_filt,LFP.data_uV(iCh,:));
        mu2 = mu.^2;
        emu = double(envelope(mu2));
        emu = emu-mean(emu);
        emu = movmean(emu,round(LFP.sFreq/100));
        [tmp,~,x_s] = PETH_EEG_simple([LFP.t_uSec(:)/1e6 emu(:)],RIP{iCh}.above_times_uS(:,1)/1e6,pts,pts,LFP.sFreq,false);
        EMU(iCh,:) = mean(tmp);
        
    end
end

figure

subplot(1,2,1)
imagesc(x_s*1000,all_channels(hpc_channels_ix),Mn)
axis xy
ylabel('Channel'); xlabel('ms')
colorbar
plot_vert_line_at_zero
title('LFP aligned on ripple onset.')


subplot(1,2,2)
imagesc(x_s*1000,all_channels(hpc_channels_ix),EMU)
axis xy
ylabel('Channel'); xlabel('ms')
colorbar
plot_vert_line_at_zero
title('MUA aligned on ripple onset.')
caxis([-10 20])


figure
subplot(1,2,1)
imagesc(x_s*1000,[],diff(Mn(1:1:end,:),1,1))
axis xy
xlabel('ms')
colorbar
plot_vert_line_at_zero
title('Locl Diff aligned on ripple onset.')
subplot(1,2,2)
imagesc(x_s*1000,[],diff(Mn,2,1))
axis xy
xlabel('ms')
colorbar
plot_vert_line_at_zero
title('CSD aligned on ripple onset.')




