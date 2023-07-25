function [fh, cellID] = Plot_phase_precession_cell_array(phase, x_pos, y_pos, n_spike_thresh, plot_string, plot_type )
% INPUT:
%    phase
%    x_pos
%    y_pos
%    n_spike_thresh : throw out any passes that have less than n_spike_thresh spikes
%    plot_string : title for each plot.
%    plot_type : 'summary', 'cycle_time'
% OUTPUT:
%   fh - figure handles for each plot
%   cellID - cell id for each figure.
% cowen

if nargin < 4
    n_spike_thresh = 0;
end

if nargin < 5
    plot_string = '';
end

if ~iscell(phase)
    phase = {phase};
end

if isempty(n_spike_thresh)
    n_spike_thresh = 0;
end

count = 1;
for cl = 1:length(phase)
    
    if ~isempty(phase{cl}.time) & length(phase{cl}.time) > n_spike_thresh
        % msec
        % Double it up to make the continuous plots.
        xCA = [phase{cl}.CA_spikes/10; phase{cl}.CA_spikes/10 ];
        xZA = [phase{cl}.ZA_spikes/10; phase{cl}.ZA_spikes/10 ];
        y = [phase{cl}.phase_angle(:);(phase{cl}.phase_angle(:) + 1)];
        
        if isempty(x_pos)
            switch plot_type
            case 'summary'
                fh(count) = figure;
                
                subplot(1,3,1)
                plot(xZA,y,'.b')
                title([plot_string ' Phase by time of 1st spk Cell ' num2str(cl)])
                ylabel('Phase angle')
                xlabel('Time from 1st spk (ms)')
                lsline
                
                subplot(1,3,2)
                
                plot(xCA,y,'.b')
                title([' Phase by cycle time of 1st spk'])
                ylabel('Phase angle')
                xlabel('Cycle Time from 1st spk')
                
                subplot(1,3,3)
                %HistISI(ctsa_spikes{cl});
                
                orient landscape
            case 'cycle_time'
                fh(count) = figure; cellID(count) = cl;
                c = colormap;
                l = round(linspace(1,Rows(c),length(unique(phase{cl}.pass_no))));
                p = [phase{cl}.pass_no; phase{cl}.pass_no];
                g=gscatter(xCA,y,p,[],[],[],0);
                a = axis;
                
                axis (a)
                title([ plot_string ' Phase by Cycle Time (t0) (color indicates pass), Cell ' num2str(cl) ])
                for ii = 1:length(g)
                    set(g(ii),'Color',c(l(ii),:))
                end
                set(g,'MarkerSize',14)
                
                ylabel('Phase angle')
                xlabel('1/4 Cycle from 1st spk')
                colorbar
                grid on
                orient tall
            otherwise
                error ('wrong plot type')
            end
        else
            [px,py] = ScatterFields({ts(phase{cl}.time)},x_pos,y_pos);
            %[sx,sy] = ScatterFields({PF_ctsa_spikes{cl}},x_pos,y_pos);
            switch plot_type
            case 'summary'
                fh(count) = figure; cellID(count) = cl;
                
                subplot(3,2,1)
                plot(Data(px),phase{cl}.phase_angle,'b.')
                title([plot_string ' Phase by postion (X), Cell ' num2str(cl) ])
                ylabel('Phase angle')
                xlabel('Postion')
                l = lsline;
                subplot(3,2,2)
                plot(Data(py),phase{cl}.phase_angle,'r.')
                title('Phase by postion (Y)')
                ylabel('Phase angle')
                xlabel('Postion')
                
                l = lsline;
                %subplot(3,2,3)
                %plot(Data(x_pos),Data(y_pos),'.')
                %hold on
                %plot(Data(sx),Data(sy),'ro')
                %title('Scatterfield')
                
                subplot(3,2,4)
                %HistISI(ctsa_spikes{cl});
                
                subplot(3,2,5)
                plot(xZA,y,'.b')
                title([' Phase by time of 1st spk'])
                ylabel('Phase angle')
                xlabel('Time from 1st spk (ms)')
                %lsline
                
                subplot(3,2,6)
                plot(xCA,y,'.b')
                title([' Phase by cycle time of 1st spk'])
                ylabel('Phase angle')
                xlabel('Cycle Time from 1st spk')
                %lsline
                orient tall
            case 'cycle_time'
                fh(count) = figure; cellID(count) = cl;
                c = colormap;
                l = round(linspace(1,Rows(c),length(unique(phase{cl}.pass_no))));
                p = [phase{cl}.pass_no;phase{cl}.pass_no];
                g=gscatter(xCA,y,p,[],[],[],0);
                a = axis;
                axis (a)
                for ii = 1:length(g)
                    set(g(ii),'Color',c(l(ii),:))
                end
                set(g,'MarkerSize',14)
                
                ylabel('Phase angle')
                xlabel('1/4 Cycle from 1st spk')
                colorbar
                title([plot_string ' Phase by Cycle Time (t0) (color indicates pass), Cell ' num2str(cl) ])
                grid on
                orient tall
            otherwise
                error('Incorrect plot type')
            end
            count = count + 1;
        end
    end
end
