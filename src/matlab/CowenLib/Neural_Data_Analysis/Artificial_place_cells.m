eedfunction [spike_ca, x_tsd, y_tsd, pf_centers] = Artificial_place_cells(endtime_sec,ncells,freq,duration_sec,ref_per_sec,pf_ctrs)
%
% INPUT: 
%       endtime = end time in seconds
%       ncells  = num of cells
%       freq    = 2 element vector (element 1= the mean firing frequency of the place cells during duration_sec(not overall)
%                   element 2 is the background random mean rate.
%
%       duration_sec = the duration_sec of place cell activity (sec)
%       ref_per_sec = refractory period
%       ndims   = number of dimensions.(2d)
%       pf_ctrs = centers of the placefields. (optional nCellxndimension
%       (2)) of pf centers. 'random' randomizes the bursting - should be no
%       positional correlation.
%
% OUTPUT:
%       spike_ctsa = cell array of ts objects
%       x_tsd   = tsd of position data.
% Cowen

colors = {'r' 'g' 'b' 'y' 'k' 'm' 'c' 'r' 'g' 'b' 'y' 'k' 'm' 'c' 'r' 'g' 'b' 'y' 'k' 'm' 'c' ...
'r' 'g' 'b' 'y' 'k' 'm' 'c' 'r' 'g' 'b' 'y' 'k' 'm' 'c' 'r' 'g' 'b' 'y' 'k' 'm' 'c' 'r' 'g' 'b' 'y' 'k' 'm' 'c'};
randomize_centers = 0; % If the user wants, randomize the activity so there is no correlation.

if nargin < 6
    pf_ctrs = [];
end

% Create fake data
% Position data
%endtime = 60; % time is in seconds
spike_sample_rate = 10000; % Hz
pos_sample_rate = 20; % Hz
%time_sec = 1:endtime_sec;
pos_fq = .10; % Hz
%ncells = 10;
%freq = 8; % Hz
%duration_sec = 1; % sec
%ref_per_sec = .01; % refract period
% Variation scales with the mean.
pf_mean_rates = abs(freq(1) + randn(ncells,1)*3);
background_mean_rates = abs(freq(2) + randn(ncells,1)*1);

posx = (cos(0:1/pos_sample_rate:endtime_sec*pos_fq*2*pi)+1)/2; % make all positions between 0 and 1;
posy = (sin(0:1/pos_sample_rate:endtime_sec*pos_fq*2*pi)+1)/2; % make all positions between 0 and 1;
   
pos_times = ((1:length(posx))/length(posx))*endtime_sec*spike_sample_rate;
x_tsd = tsd(pos_times',posx');
y_tsd = tsd(pos_times',posy');
%spike_times{1} = [];
dpos = diff(posx);	
rand('seed',1)
if isstr(pf_ctrs)
    if strcmp(pf_ctrs,'random')
        randomize_centers = 1;
    end
    pf_ctrs = [];
end

if isempty(pf_ctrs)
    rand_loc = round(rand(ncells,1)*length(posx));
    pf_centers = [posx(rand_loc)' posy(rand_loc)'];
else
    pf_centers = pf_ctrs;
end

for cellno = 1:ncells
%   rand_loc = round(rand(1,1)*length(posx));
   
%   pf_center{cellno} = [posx(rand_loc) posy(rand_loc)];
%   r = rand(1,1);
   % times when the Vrat runs over these points.
   [idx_x] = find( posx > (pf_centers(cellno,1)-.02) & posx < (pf_centers(cellno,1)+.02));
   [idx_y] = find( posy > (pf_centers(cellno,2)-.02) & posy < (pf_centers(cellno,2)+.02));
   idx = intersect(idx_x, idx_y);
   d = diff(idx);
   idx(d==1) = [];  
   if randomize_centers
       % Kill the position information.
       rp = randperm(length(posx));
       idx_x = sort(rp(1:length(idx_x)));
       idx_y = sort(rp(1:length(idx_y)));
       idx = intersect(idx_x, idx_y);
       d = diff(idx);
       idx(d==1) = [];
   end

   % Make unidirectional.
   %if r >.5 % Choose the positive diff as the pf direction
   %   to_elim = find(dpos < 0);
   %   v = intersect(idx,to_elim);
   %   for vv = v
   %      idx(find(idx == vv)) = [];
   %   end	
   %else % Choos the negative diff as the placefield direction
   %   to_elim = find(dpos > 0);
   %   v = intersect(idx,to_elim)
   %   for vv = v
   %      idx(find(idx == vv)) = [];
   %   end	
   %end	
   out_units = '.1msec'; % Timestamps
   neuron{cellno} = zeros(1,endtime_sec);
   spike_times{cellno} = [];
   
   for ii = 1:length(idx)
      % add randomness to freq or duration to make more realistic
      spks = Gen_spikes(pf_mean_rates(cellno),duration_sec/2, ref_per_sec,'gaussian',out_units);
      %spks = Gen_spikes(freq,duration_sec/2,ref_per_sec,'poisson',out_units);
      spike_times{cellno} = [spike_times{cellno} pos_times(idx(ii))+spks];
      %for s = 1:length(spks)
      %   xx = idx(ii)+spks(s);
      %   neuron{cellno}(xx) = 1;
      %end	
   end
   if freq(2) == 0
       background_spikes = [];
   else
       background_spikes = Gen_spikes(background_mean_rates(cellno),endtime_sec,ref_per_sec,'poisson',out_units);
   end
   ut = unique(round([spike_times{cellno}(:); background_spikes(:)]));
   ix = find(diff(ut)<(ref_per_sec*spike_sample_rate));
   ut(ix) = [];
   spike_ctsa{cellno} = ts(ut);
   spike_ca{cellno} = ut;
end

%figure
%plot(pos_times,posx);hold on;plot(pos_times,posy,'r')
%hold on; 

%for ii = 1:ncells
%   plot(spike_times{ii}, ones(1,length(spike_times{ii}))/2,[colors{ii} '*'])
%end
if nargout == 0
    figure;
    plot(posx,posy,'k:')
    hold on
    SFx = ScatterFields(spike_ctsa,x_tsd);
    SFy = ScatterFields(spike_ctsa,y_tsd);
    
    for ii = 1:ncells
        plot(Data(SFx{ii}),Data(SFy{ii}),[colors{ii} '*'])
    end
    axis square
    figure
    Plot_Q(spike_ca,400,{[spike_ca{1}(1) spike_ca{1}(end)]} )
    figure
    Q = Bin_ts_array(spike_ctsa,400*10);
    imagesc(corrcoef(Q))
end