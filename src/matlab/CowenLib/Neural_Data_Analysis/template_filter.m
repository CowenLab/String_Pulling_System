function dp_all = template_filter(tetrode_file, outfile, dp_threash, template_file);
% TEMPLATE_FILTER  clean spike file by comparing each spike with templates
%     dp_all = template_filter(tetrode_file, outfile, dp_threash, template_file);
% Each of a spike's four channels is compared against each template file using the dot
% product.  Before the dot product, all waveforms are normalized for energy.  The maximum dot product
% across all channels and all template waveforms is compared against the threashold.  If this dot
% product exceeds threashold, the spike is kept and written to the outfile.
% dp_all = template_filter(tetrode_file, [outfile], [dp_threash], [template_file]);
% tetrode_file is a *.dat (NT file) from Cheetah
% outfile will also be a *.dat file, if no extension one will be added
% dp_threash is the dot product threashold for keeping a spike (default= .85).
% use higher numbers for a "cleaner" (i.e., more spike-like) output file
% template file must contain a variable called wave_templates with 
% dimensions: num_templates X 32 (default: 'hipp_templates.mat')
% dp_all is the maximum dot product for each waveform in the raw file
% 
if nargin<=3
    template_file = 'hipp_templates.mat';
end;
if nargin<=2
    dp_threash = .85;
end;
if nargin<=1
    [path, name, ext] = fileparts(tetrode_file);
    outfile = [path '\' name 'c.dat'];
else
    [path, name, ext] = fileparts(outfile);
    if isempty(ext)
        outfile = [outfile '.dat']
    end;
end;

tetrode_file

[num_recs_all, ts_i, ts_f] = GetNlxFileProperties(tetrode_file);

disp(['File contains: ' num2str(num_recs_all) ' spikes']);

load(template_file);

spikes_per_block = 30000;
nsteps = fix(num_recs_all/spikes_per_block);

dp_all = zeros(1,num_recs_all);
total_bad = 0;
total_good = 0;
%total_stim = 0;

for j = 0:nsteps
     
    
    llim = j*spikes_per_block+1;
    ulim = min((j+1)*spikes_per_block, num_recs_all);

    disp(['Processing Block ' num2str(j+1) ' of ' num2str(nsteps+1) ', Spikes ' num2str(llim) ' to ' num2str(ulim)]);
     
    % note we subtract one from the look-up indices because Nlx2MatSpike uses C-style indices (starting from 0)
	[ts, ScNumbers, CellNumbers, Params, wv_data, NLX_header] = Nlx2MatSpike(tetrode_file,1,1,1,1,1,1,[llim-1 ulim-1],1);
        
	best_dp = zeros(1,length(ts));
	
    for i = 1:4
	    %test_waves = squeeze(wv(:,i,:));
        test_waves = squeeze(wv_data(:,i,:))';
        wave_energy = sqrt(sum((test_waves.^2)'))';
        test_waves_normed = test_waves./(wave_energy*ones(1,32));
        %plot(test_waves_normed(1:100:end,:)')
        dot_prod = test_waves_normed*wave_templates';
        %imagesc(dot_prod)
        best_dp = max(best_dp, max(dot_prod'));
	end;
    dp_all(llim:ulim) = best_dp;
        
	if 0
      hist(best_dp,100)
	   pause
   end
   
	keep_i = best_dp>dp_threash;
	%stim_keep_i = any(test_waves(:,[1:4 27:32])'>1000) | any(test_waves'<-2000);
	
	good_waves = test_waves(keep_i,:);
    
   if 0
      clf;
      bad_waves = test_waves(~keep_i,:);
      subplot(1,2,1);
      plot(good_waves(1:100:end,:)');
      subplot(1,2,2);
      if length(bad_waves)>0
         plot(bad_waves(1:100:end,:)');
      end
      pause;
   end;
   
    total_good = total_good + sum(keep_i);
    total_bad = total_bad + sum(~keep_i);
    
	ts1 = ts(keep_i);
	num_recs = length(ts1);
	temp_waves = wv_data(:,:,keep_i);
	scn = zeros(1,num_recs);
	pars = zeros(8,num_recs);
	cn = zeros(1,num_recs);
	
	if j == 0
        mat2nlxtt(outfile, ts1, scn, cn, pars, temp_waves, num_recs);
    else
        mat2nlxttAppendFile(outfile, ts1, scn, cn, pars, temp_waves, num_recs);
    end;
end;

disp(['Done processing ' tetrode_file]);
disp(['Total Spikes: ' num2str(num_recs_all)]);
disp(['Total Good:   ' num2str(total_good)]);
disp(['Total Bad:    ' num2str(total_bad)]);


return;
