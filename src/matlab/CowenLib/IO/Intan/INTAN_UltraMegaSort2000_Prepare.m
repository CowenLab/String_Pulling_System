function INTAN_UltraMegaSort2000_Prepare(ntrode_fname, nTrode_channels, sFreq, startrec, batch_file)
%Continuous amplifier data is basically indistinguishable from the tetrode
%files carved out of the AMPX system. This function is a copy/paste job
%that changes how the metadata becomes known to the Kleinfeld script.
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Spike Extraction (it will also sort, but you must pass in the sort
% parameter into the function. 
% In retrospect, this may be fast enough without creating a separate file
% for each ntrode. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
disp('INTAN_UltraMegaSort2000')
spikes = INTAN_UltraMegaSort2000(ntrode_fname,false,sFreq);
npts_per_UMega_spike = size(spikes.waveforms,2);
peak_pt_on_UMega_wv = 13;

[p, ntrode_fname_root, e] = fileparts(ntrode_fname);
spk_file = fullfile(p,[ntrode_fname_root '.mat']);
save(spk_file,'spikes')
% Delete this file - it is huge.
delete(ntrode_fname);
toc
%% If this is a tetrode, write it as an ntt file so that it can be clusered
% and analyzed easy peasy.
% EXPECTS a 32 point vector. Should interpolate for this - could take a lot
% of time.
nlx_peak_align = 0.00025; % where the peak usually is in the neauralynx data.
spikes_peak_align = peak_pt_on_UMega_wv/sFreq; % Where the peak is in the spikes data.
nlx_t = linspace(0,32/32000,32)-nlx_peak_align;
spikes_t = linspace(0,npts_per_UMega_spike/sFreq, npts_per_UMega_spike)-spikes_peak_align;
nSpks = length(spikes.unwrapped_times);
nch = size(spikes.waveforms,3);
NTT = zeros(32,4,nSpks); % 32xMxN
% Ugly for loop. This needs to be sped up.
% Kleinfeld's way is to make it a Huge vector with padding and then
% reconstitite it. This may work - just have to dive into his code.
disp('NTT creator')
for iSample = 1:nSpks
    for iCh = 1:length(nTrode_channels)
        % I JUST CREATED RESPLINE_COWEN which should be much faster than
        % this- it's worth a try. Also interp1 should work on columns so
        % this may be more efficitn if I run it as a sample x wave matrix.
        NTT(:,iCh,iSample) = interp1(spikes_t,spikes.waveforms(iSample,:,iCh),nlx_t);
    end
    if mod(iSample,20000) == 0
        fprintf('|%d(%d)',iSample,nSpks) 
    end
end

nlx_spk_file = fullfile(p,[ntrode_fname_root '.ntt']);
Timestamps = (double(spikes.unwrapped_times)-(startrec/sFreq)) * 1e6; % Add the start timestamps.
% Mat2NlxSpike('test.nst', 0, 1, [], [1 1 1 1 1], Timestamps,
%             ScNumbers, CellNumbers, Features, Samples, Header);
NTT = NTT * -1; % Negative is UP in the neuralynx. data.
Mat2NlxSpike(nlx_spk_file, 0, 1, [],[1 1 1 1 1 1], Timestamps, zeros(1,nSpks),zeros(1,nSpks), zeros(8,nSpks), NTT, {'Intan Amplifier Data'});
% Modify the Batch file so that the channel-validity is correct.
% presumes there is a Batch1.txt file in this directory
switch length(nTrode_channels)
    case 1
        str = '--ChannelValidity 1 0 0 0';
        minclu = '--KKwik_MinClusters       5';
        maxclu = '--KKwik_MaxClusters       15';
    case 2
        str = '--ChannelValidity 1 1 0 0';
        minclu = '--KKwik_MinClusters       8';
        maxclu = '--KKwik_MaxClusters       25';
    case 3
        str = '--ChannelValidity 1 1 1 0';
        minclu = '--KKwik_MinClusters       12';
        maxclu = '--KKwik_MaxClusters       31';
    case 4
        str = '--ChannelValidity 1 1 1 1';
        minclu = '--KKwik_MinClusters       12';
        maxclu = '--KKwik_MaxClusters       34';
end
fp = fopen(batch_file,'a+');
fprintf(fp,'\n--File %s.Ntt\n\t%s\n\t%s\n\t%s\n\n',ntrode_fname_root,str,minclu,maxclu);
fclose(fp);

%    --ChannelValidity         1 1 1 1  
%    --KKwik_MinClusters       12
%    --KKwik_MaxClusters       22

