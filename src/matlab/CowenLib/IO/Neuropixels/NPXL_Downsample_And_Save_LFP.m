function NPXL_Downsample_And_Save_LFP(lf_bin_name, meta, decimation_factor, skip_every_n_ch, fast_and_dirty)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decimates and writes data to the .LFP folder.
% Tried to make this as simple as possible.
% Saves data as single matlab files and keeps meta data with
% each file.
%
% INPUT:
% name of the bin file (can be .lf.bin or .ap.bin)
% meta data for that file from the .meta file
% decimation factor (see the decimate function). Make it big for big files.
% skip_every_n_ch (only write every n channels).
%
% Creates a new LFP folder and saves the data as individual .mat files.
% This way you can only load what you need to speed things up and reduce
% memory demands.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mmap the data
if nargin < 4
    skip_every_n_ch = 0;
end
if nargin < 5
    fast_and_dirty = 0; % if true, no downsampling, only load ever n recs
end

blocksz = 40e8; % For chunking the data to save memory. Adjust if ncessary.

n_ch = str2double(meta.nSavedChans);
nrecs_from_meta = str2double(meta.fileSizeBytes)/2/n_ch;
m = memmapfile(lf_bin_name,'Format','int16') ;
n_recs = length(m.Data)/n_ch;
n_samples = length(m.Data)/n_ch/385;
pth = fileparts(lf_bin_name);
out_dir = fullfile(pth,'LFP');
[status,msg] = mkdir(out_dir);

if nrecs_from_meta ~= n_recs
    error('Something is wrong')
end
LFP.new_sFreq = str2double(meta.imSampRate)/decimation_factor;
LFP.decimation_factor = decimation_factor;
LFP.original_meta = meta;

if skip_every_n_ch > 0
    chans = 1:(skip_every_n_ch+1):n_ch;
    chans(end) = n_ch;
else
    chans = 1:n_ch;
end
if fast_and_dirty % Do it all at once with no low pass (so aliasing issues). Great for small files, not so good for anyting > 30 minutes.
    disp('Doing it fast and dirty')
    for iCh = chans
        LFP.Channel = iCh;
        v = single(m.Data(iCh:(n_ch * decimation_factor):end));
        v = v - median(v(1:100:end));
        v(abs(v)>1000) = 0;
        LFP.Data = single(v);
        % LFP.Data = single(decimate(v,decimation_factor));
        txt = sprintf('.dec%d.ch%d.mat',LFP.decimation_factor,iCh );
        out_file = strrep(lf_bin_name,'.bin',txt);
        save(fullfile(pth,'LFP',out_file),'LFP')
        fprintf('%d/%d ',iCh,length(chans))
    end
else % load by block
    disp('Using decimate')

    block_edges = 0:blocksz:length(m.Data);
    block_edges(end) = length(m.Data)+1; % add + 1 as the loop below subtracts one from the end to ensure the blocks do not overlap 
    
    fprintf('%d files\n',length(chans))

    for iCh = chans
        LFP.Data = nan(1,ceil(n_samples/skip_every_n_ch),'single'); % Should be pre-allocated.
        st_ix = 1;
        for iEdge = 2:length(block_edges)
            LFP.Channel = iCh;
            v = double(m.Data((iCh + (block_edges(iEdge-1)):n_ch:(block_edges(iEdge)-1))));
            if iEdge == 2
                mn = mean(v(1:100:end));
            end
            v(abs(v)>1000) = 0;
            v = v - mn;
            vv = single(decimate(v,decimation_factor))';
            LFP.Data(st_ix:(st_ix+length(vv)-1)) = vv;
            st_ix = st_ix + length(vv);
            fprintf('%d/%d,',iEdge,length(block_edges))
        end
        LFP.Data = LFP.Data(1:(st_ix-1));

        disp('done')
        txt = sprintf('.dec%d.ch%d.mat',LFP.decimation_factor,iCh );
        out_file = strrep(lf_bin_name,'.bin',txt);
        save(fullfile(pth,'LFP',out_file),'LFP')
    end
end
fprintf('Wrote files in %s\n',fullfile(pth,'LFP'))

if 0
    figure
    imagesc(LFP.Data(1:20:end,:))
end
