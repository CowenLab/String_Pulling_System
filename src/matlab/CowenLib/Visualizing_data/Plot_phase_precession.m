function Plot_phase_precession(time_phase_order_group,plot_type, units)
% gscatter(time_phase_order_group(:,1),time_phase_order_group(:,2),time_phase_order_group(:,3),[],[],[],0);
% set(g, 'MarkerSize',4);
% C = get(g,'Color');
%jet(n+1);
if nargin < 2 || isempty(plot_type)
    plot_type = 'connect_sequences';
    %     plot_type = 'traditional';
end

if nargin < 3
    %     units = 'radians';
    units = 'degrees';
end
%%
if size(time_phase_order_group,1) < 200
    mkrsize = 14;
else
    mkrsize = 4;
end


switch units
    case 'radians'
        unit_lab = 'radians';
        mult_factor = 1;
    case 'degrees'
        unit_lab = 'deg';
        mult_factor = 360/(2*pi);
end
time_phase_order_group(:,2) = time_phase_order_group(:,2) * mult_factor;


switch plot_type
    case 'connect_sequences'
        %         time_phase_order_group = sortrows(time_phase_order_group);
        u = unique(time_phase_order_group(:,3));
        clrs = repmat('bgrcmyk',1,ceil(length(u)/5));
        for ii = 1:length(u)
            TPG = time_phase_order_group(time_phase_order_group(:,3) == u(ii),:);
            for jj = 2:Rows(TPG)
                
                plot(TPG([jj-1 jj],1),TPG([jj-1 jj],2),'.-','Color',clrs(ii),'MarkerSize',mkrsize)
                hold on
                if abs(diff(TPG([jj-1 jj],2))) > pi
                    % because we are plottin on a linear scale, we can get
                    % a distorted impression of precession because a
                    % difference greater than pi should really be
                    % 2pi-the_diff - given that circular stats are
                    % required. This converts those datapoints to dashed
                    % lines so that these long phase differences are at
                    % least identified. Perhaps we should just avoid 
                    plot(TPG([jj-1 jj],1),TPG([jj-1 jj],2)+2*pi*mult_factor,':','Color',clrs(ii),'MarkerSize',mkrsize)
                else
                    plot(TPG([jj-1 jj],1),TPG([jj-1 jj],2)+2*pi*mult_factor,'.-','Color',clrs(ii),'MarkerSize',mkrsize)
                end
            end
        end
    case 'traditional'
        plot(time_phase_order_group(:,1),time_phase_order_group(:,2),'k.','MarkerSize',mkrsize)
        hold on
        plot(time_phase_order_group(:,1),time_phase_order_group(:,2)+2*pi*mult_factor,'k.','MarkerSize',mkrsize)
        
        %
        if 1
            rad = time_phase_order_group(:,2)/mult_factor;

            [out_rsq, out_r, out_pv, out_betas1] = Circular_linear_correlation_brute_force(rad,time_phase_order_group(:,1));
            
            [out_rsq, out_r, out_pv, out_betas2] = Circular_linear_correlation_brute_force(rad+2*pi,time_phase_order_group(:,1));
            out_betas1 = out_betas1 * mult_factor;
            out_betas2 = out_betas2 * mult_factor;
            %             if strcmp(units,'degrees')
            %                 out_betas1 = out_betas1 * mult_factor;
            %
            %                 out_betas2 = out_betas2 * mult_factor;
            %             end
            axis tight;
            
            a = axis;
            x = a(1:2);
            y = x.*out_betas1(2) + out_betas1(1);
            plot(x,y,'m')
            
            a = axis;
            x = a(1:2);
            y = x.*out_betas2(2) + out_betas2(1);
            plot(x,y,'m')
        end
end
a = axis;
a(3:4) = [0 4*pi*mult_factor];
axis(a);

pubify_figure_axis
ylabel(unit_lab)
