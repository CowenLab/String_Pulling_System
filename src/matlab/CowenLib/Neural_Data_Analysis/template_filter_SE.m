function dp_all = template_filter_SE(wave_file, outfile, dp_threash, template_file);
% 
% TEMPLATE_FILTER  clean spike file by comparing each spike with templates
%     dp_all = template_filter(wave_file, outfile, dp_threash, template_file);
% Each of a spike's four channels is compared against each template file using the dot
% product.  Before the dot product, all waveforms are normalized for energy.  The maximum dot product
% across all channels and all template waveforms is compared against the threashold.  If this dot
% product exceeds threashold, the spike is kept and written to the outfile.
% dp_all = template_filter(wave_file, [outfile], [dp_threash], [template_file]);
% wave_file is a *.dat (NT file) from Cheetah
% outfile will also be a *.dat file, if no extension one will be added
% dp_threash is the dot product threashold for keeping a spike (default= .85).
% use higher numbers for a "cleaner" (i.e., more spike-like) output file
% template file must contain a variable called wave_templates with 
% dimensions: num_templates X 32 (default: 'hipp_templates.mat')
% dp_all is the maximum dot product for each waveform in the raw file
%  adapted from David Eustons to work for SE files.
if nargin<=3
    template_file = 'hipp_templates.mat';
end;
if nargin<=2
    dp_threash = .55;
end;
if nargin<=1
    [path, name, ext] = fileparts(wave_file);
    outfile = fullfile(path ,[name '_c.nse']);
else
    [path, name, ext] = fileparts(outfile);
    if isempty(ext)
        outfile = [outfile '.nse']
    end;
end;

wave_file

[all_ts] = Nlx2MatSE(wave_file,1,0,0,0,0,0);
num_recs_all = length(all_ts);
disp(['File contains: ' num2str(num_recs_all) ' spikes']);

load(template_file);

%spikes_per_block = 30000;
spikes_per_block = 200000;
nsteps = ceil(num_recs_all/spikes_per_block);

increments = floor(linspace(1,num_recs_all,nsteps+1));
idx_increments = [increments(1:end-1)' increments(2:end)'-1];
idx_increments(end) = num_recs_all; % make sure the last block has the last record 

dp_all = zeros(1,num_recs_all)*nan;
total_bad = 0;
total_good = 0;
%total_stim = 0;
cum_ts = [];
for j = 1:nsteps
    llim = idx_increments(j,1);
    ulim = idx_increments(j,2);

    disp(['Processing Block ' num2str(j) ' of ' num2str(nsteps) ', Spikes ' num2str(llim) ' to ' num2str(ulim)]);
     
    % note we subtract one from the look-up indices because Nlx2MatSpike uses C-style indices (starting from 0)
	%[ts, ScNumbers, CellNumbers, Params, wv_data, NLX_header] = Nlx2MatSE(wave_file,1,1,1,1,1,1,all_ts(llim:ulim));
	[ts, wv_data] = Nlx2MatSE(wave_file,1,0,0,0,1,0,all_ts(llim:ulim));
        
	best_dp = zeros(1,length(ts));
    
    %for i = 1:4
    %test_waves = squeeze(wv(:,i,:));
    %test_waves = squeeze(wv_data)';
    %wave_energy = sqrt(sum((squeeze(wv_data)'.^2)'))';
    % Changed all of the above conversions to one line -- saved a LOT of
    % memory
    dot_prod = squeeze(wv_data)'./(sqrt(sum((squeeze(wv_data)'.^2)'))'*ones(1,32))*wave_templates';
    %plot(test_waves_normed(1:100:end,:)')
    %dot_prod = test_waves_normed*wave_templates';
    %imagesc(dot_prod)
    best_dp = max(best_dp, max(dot_prod'));
    %end;
    dp_all(llim:ulim) = best_dp;
    
    if 0
        hist(best_dp,100)
        pause
    end
   
	keep_i = best_dp>dp_threash;
    cum_ts = [cum_ts ts(keep_i)];
	%stim_keep_i = any(test_waves(:,[1:4 27:32])'>1000) | any(test_waves'<-2000);

    if 1
        figure
        good_waves = squeeze(wv_data(:,:,keep_i))';
        clf;
        bad_waves = squeeze(wv_data(:,:,~keep_i))';
        subplot(1,2,1);
        plot(good_waves(1:100:end,:)');
        title('Good')
        subplot(1,2,2);
        if length(bad_waves)>0
            plot(bad_waves(1:100:end,:)');
        end
        title(['Bad ' wave_file ' ' num2str(j)])
    end;
    
    total_good = total_good + sum(keep_i);
    total_bad = total_bad + sum(~keep_i);
    
	ts1 = ts(keep_i);
	num_recs = length(ts1);
	temp_waves = wv_data(:,:,keep_i);
	scn = zeros(1,num_recs);
	pars = zeros(8,num_recs);
	cn = zeros(1,num_recs);
	
%	if j == 1
%        mat2nlxSE(outfile, ts1, scn, cn, pars, temp_waves, num_recs);
%    else
%        mat2nlxttAppendFile(outfile, ts1, scn, cn, pars, temp_waves, num_recs);
%    end;
end;
clear wv_data dot_prod dp_all all_ts;
pack
if length(cum_ts) ~= length(unique(cum_ts))
    disp('ACCUMULATED TIMESTAMPS ARE ERRONEOUS')
end
[ts, ScNumbers, CellNumbers, Params, wv_data, NLX_header] = Nlx2MatSE(wave_file,1,1,1,1,1,1,cum_ts);
mat2nlxSE(outfile, ts, ScNumbers, CellNumbers, Params, wv_data, length(cum_ts));

disp(['Done processing ' wave_file]);
disp(['Total Spikes: ' num2str(num_recs_all)]);
disp(['Total Good:   ' num2str(total_good)]);
disp(['Total Bad:    ' num2str(total_bad)]);


return;
