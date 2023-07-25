function [LFP] = NPXL_Extract_LFP(lfp_bin_file_path, start_rec, n_samples )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% much to do here -but something tells me someone has already done all of
% this.
% Cowen 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% channels = 1:10:384;
%%
% start_rec = 0;
% n_samples = 100000;
% lfp_bin_file_path = fullfile(pwd,'vHP_DV7pt2_mPFC_DV7_tetrodeconfig_g0_t0.imec1.lf.bin');
[path_name, tmp] = fileparts(lfp_bin_file_path);
lfp_fname = [tmp '.bin'];
meta_fname = strrep(lfp_fname,'.lf.bin','.lf.meta');
% Extract_varargin;
obj = SGLX_Class;
LFP.meta = obj.ReadMeta(meta_fname,path_name);
LFP.nChan = str2double(LFP.meta.nSavedChans);
LFP.sFreq = str2double(LFP.meta.imSampRate);
LFP.nFileSamp = str2double(LFP.meta.fileSizeBytes) / (2 * LFP.nChan);
LFP.time_sec_of_recording = LFP.nFileSamp/LFP.sFreq;
%LFP.meta = meta;
LFP.start_rec = start_rec;
% read the data. The last rec is typically the sync pulse.
LFP.data = obj.ReadBin(start_rec,n_samples,LFP.meta ,lfp_fname,path_name); %(samp0, nSamp, meta, binName, path)
LFP.data = int16(LFP.data ); % only a range of +/- 512 bits whcih make sense since 10bit a/d 2^10 = 1024
% What is the conversion factor?
v_range = 2*str2double(LFP.meta.imAiRangeMax);
n_bits = 1024;
mV_per_bit = v_range*1000/n_bits; % I think this ignores the gain - where is this stored?
bits_to_mV = n_bits/(v_range*1000) % this can't be right - this has to be in the uV range, not mV

%
figure
subplot(2,1,1)
imagesc(LFP.data); colorbar
subplot(2,1,2)
imagesc(diff(LFP.data,2,1)); colorbar % CSD  - assumes linear ordering.
caxis([-100 100])
% here is the reading code - will probably have to modify manually... 
%             nChan = str2double(meta.nSavedChans);
% 
%             nFileSamp = str2double(meta.fileSizeBytes) / (2 * nChan);
%             samp0 = max(samp0, 0);
%             nSamp = min(nSamp, nFileSamp - samp0);
% 
%             sizeA = [nChan, nSamp];
% 
%             fid = fopen(fullfile(path, binName), 'rb');
%             fseek(fid, samp0 * 2 * nChan, 'bof');
%             dataArray = fread(fid, sizeA, 'int16=>double');
%             fclose(fid);