function feature_summary(waveform_file,file_type, features_to_show, varargin)
% Summary of the features for a channel.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% INPUT 
%  waveform file to check. Cannot be in Sun format (.tt)
%  file_type = 'TT', 'ST', 'SE', or 'sunTT'
%  features to show(optional) : {'energy','peak','stdPC1','stdPC2'}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% OUTPUT
%  feature plots
% 
% cowen 2003
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
if nargin == 2
    features_to_show = {'energy','peak','stdPC1','stdPC2'};
    channels = 1;
end
subsample_limit = 120000;
fig_file_name = waveform_file;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% only a waveform file is specified.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
[p,n,e] = fileparts(waveform_file);
title_string    = n;
subsample_limit = 120000;
text_font_size  = 8;
ncols = 3;
saveit = 1;

extract_varargin;

switch file_type
case {'TT' , 'sunTT'}
    n_channels = 4;
    channel_combos =[1 2; 1 3; 1 4; 2 3; 2 4; 3 4; 1 1; 2 2; 3 3; 4 4];
    ch_validity = [1 1 1 1];
case 'ST' 
    n_channels = 2;
    
    channel_combos = [1 2; 1 1; 2 2];
    ch_validity = [1 1 0 0 ];
    
case 'SE' 
    n_channels = 1;
    channel_combos = [1 1];
    ch_validity = [1 0 0 0 ];
otherwise 
    error('BOMB: You need a valid file type in parameter 2. TT, ST, SE, sunTT')
end

if strcmp(file_type,'sunTT')
    [t, wv] = LoadTT0_nt(waveform_file,[1 1000],4);
    s = size(wv);
    wv = reshape(wv,32,4,length(t));
    total_spikes = length(t);
else
    try
        eval(['[t header] = Nlx2Mat' file_type '(waveform_file,1,0,0,0,0,1);']);
        total_spikes = length(t);
        if total_spikes>subsample_limit
            disp(['File has ' num2str(length(t)) ' records, subsampling (random).'])
            t = t(unique(round(rand(1,30000)*length(t))));
            eval(['[t wv] = Nlx2Mat' file_type '(waveform_file,1,0,0,0,1,0,t);']);
            title_string = [title_string ' SubSampled ']
        else
            eval(['[t wv] = Nlx2Mat' file_type '(waveform_file,1,0,0,0,1,0);']);
        end
    catch
        disp(['Load ' waveform_file ' failed']);
        return
    end
end

if ~isempty(features_to_show)
    % --------------------------------------------------------
    % Generate each feature.
    % --------------------------------------------------------
    figure
    nFeatures = length(features_to_show);
    a_dim = ceil(sqrt((nFeatures^2 - nFeatures)/2));
    fig_count = 1;
    count = 1;
    for iF = 1:length(features_to_show)
        for jF = (iF+1):length(features_to_show)
            for chc = 1:size(channel_combos,1)
                [FeatureData1, FeatureNames1] = ...
                    feval(['feature_', features_to_show{iF}], tsd(t,reshape(squeeze(wv(:,channel_combos(chc,1),:))',length(t),1,32)), [1 0 0 0]);
                [FeatureData2, FeatureNames2] = ...
                    feval(['feature_', features_to_show{jF}], tsd(t,reshape(squeeze(wv(:,channel_combos(chc,2),:))',length(t),1,32)), [1 0 0 0]);
                
                subplot(a_dim,a_dim ,count)
                % Check to see if you have some integer data-- if so, ad some random noise to make it viewable.
                if Is_int(FeatureData2)
                    FeatureData2 = FeatureData2 + rand(size(FeatureData2)) - .5;
                end
                if Is_int(FeatureData1)
                    FeatureData1 = FeatureData1 + rand(size(FeatureData1)) - .5;
                end
                
                if (1)
                    xlim = 100;
                    ylim = 100;
                    %H = ndhist([FeatureData1(:)'; FeatureData2(:)'],[xlim ylim]',[min(FeatureData1) min(FeatureData2)]',[max(FeatureData1) max(FeatureData2)]')';
                    H = ndhist([FeatureData1(:)'; FeatureData2(:)'],[xlim ylim]',[mean(FeatureData1)-3*std(FeatureData1) mean(FeatureData2)-3*std(FeatureData2)]',[mean(FeatureData1)+3*std(FeatureData1) mean(FeatureData2)+3*std(FeatureData2)]')';
 
                    H = log(H);
                    mn = min(H(find(H>-100)));
                    H(find(H < -100)) = mn;
                    imagesc(Hsmooth(H));          
                    axis xy
                    axis off
                else
                    plot(FeatureData1,FeatureData2,'.','Markersize',1)
                end
            
                if count == 1
                    [p, n, e] = fileparts( fig_file_name);
                    title([[n e] ' ' FeatureNames1{1} ' ch ' num2str(channel_combos(chc,1))  ' Vs ' FeatureNames2{1} ' ch ' num2str(channel_combos(chc,2)) ],'FontSize',text_font_size)
                else
                    title([FeatureNames1{1} ' ch ' num2str(channel_combos(chc,1)) ' Vs ' FeatureNames2{1} ' ch ' num2str(channel_combos(chc,2)) ],'FontSize',text_font_size)
                end
                count = count + 1;
                if count > a_dim*a_dim
                    if saveit
                        [p,n,e] = fileparts(fig_file_name);
                        saveas(gcf,[n '_projections_' num2str(fig_count)],'png')
                        fig_count = fig_count + 1;
                    end
                    count = 1;
                    figure
                end
            end
        end
    end % for
    if saveit
        [p,n,e] = fileparts(fig_file_name);
        saveas(gcf,[n '_projections_' num2str(fig_count)],'png')
        fig_count = fig_count + 1;
    end
    
end