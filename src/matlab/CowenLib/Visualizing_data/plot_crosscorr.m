function h = plot_crosscorr(CC,xdim,conv_window_pts,WV,is_acorr)
%function plot_crosscorr(C,xdim,conv_window_pts)
% Plots a pretty cross corellogram.
%  INPUT: C = a vector of histgram values for the crosscorr
%    if C is a matrix, then multiple cross corrs are overlaid on each
%    other.
%
%    xdim - the x dimension for each point in C.
%    conv_window_pts (optional) convolution window for a smoothing convolution on top of the
%     If 'bars' is passed in, it will do intelligent bayesian fitting -
%     automatic window determination - problem is that it is REALLY slow
%     but the output is quite nice.
%    
% COWEN (2006)
if nargin < 5
    is_acorr = 0;
end
if nargin < 4
    WV = [];
end
if nargin < 3
    conv_window_pts = [];
end
sm_color = 'y'; % color of the smoothed line
ii = 1;
mdiff = mean(diff(xdim));
CC = double(CC);
xdim = xdim(:)';
for ii = 1:size(CC,1)
    h = barp( xdim -.5 * mdiff, CC(ii,:) ); % subtract .5binsize so that bins are centered on the xlabels
    set(h,'FaceColor',[0.5 0.5 0.5])
    set(h,'EdgeColor',[0.3 0.3 0.3])
    %set(h,'FaceAlpha',0.8) % THIS SCREWS UP SAVEAS__
    
    if ~isempty(conv_window_pts)
        hold on
        if isstr(conv_window_pts)
            % I have tried all of these. bars is supposed to be optimal,
            % but it is very slow and crashes without warning.
            %
            % best_polynomial works fine if you are only interested in low
            % frequency components - it misses high frequency stuff.
            % 
            % best_hamming - i just can't get that to optimize wiht
            % cross_validation - it always is minimal at order = 1. I know
            % I am missing something fundamental with this one.
            %
            % I go back to savisky golay local polynomial fitting - it
            % captures the high and low frequency components - it only
            % screws up when there is a very sharp peak - then it rings.
            switch lower(conv_window_pts)
                case 'bars'
                    % BARS is SLOOOOW but very pretty. Also crashes when
                    % unhappy.
                    [smoothed_y yconf]= bars_filter(xdim,CC(ii,:),'poisson');
                    smoothed_y = smoothed_y';
                case 'best_polynomial'
                    f = gcf;
                    figure
                    [opt_ord, smoothed_y, err, mse] = cross_validation_order_est(xdim,CC(ii,:),3:2:25,'polynomial',1);
                    figure(f)
                    
                    yconf = [err + smoothed_y;smoothed_y - err];
                case 'best_hamming'
                    f = gcf;
                    figure
                    [opt_ord, smoothed_y, err, mse] = cross_validation_order_est(xdim,CC(ii,:),5:2:80,'hamming',1);
                    figure(f)
                    
                    yconf = [err + smoothed_y;smoothed_y - err];
                otherwise
                    error('Wrong parameter')
            end
            plot(xdim,yconf(1,:)','g:','LineWidth',2)
            plot(xdim,yconf(2,:)','g:','LineWidth',2)
        else
            %decimation_ratio = .2;
            %c = decimate(CC(ii,:),1/decimation_ratio);
            %newx = linspace(xdim(1),xdim(end),length(c));
            % Upsample back to a higher original rate.
            %c = interp1(newx,c,xdim,'spline');
            %        c = conv(CC(ii,:),hamming(conv_window_pts)/sum(hamming(conv_window_pts)));
            % Determine the order of the filter- if there is a big spike in the
            % middle, butter use a higher order.
            mn = nanmean(CC(ii,:));
            sd = nanstd(CC(ii,:));
            mx = nanmax(CC(ii,:));
            %thresh = mn + 5*sd; % Rule of thumb.
            %if mx > thresh
            %    ord = nan; % Spikey so need to use a convolution.
            %else
            %end
            %CCpad = [mean(CC(ii,1:conv_window_pts)) CC(ii,:) mean(CC(ii,end-conv_window_pts:end))];
            if is_acorr
                % Do each filter separately on each side
                %ord = 5; % Not so spikey so can afford to smooth.
                mid = round(size(CC,2)/2);
                csg1 = convn(CC(ii,1:(mid-1))',hamming(conv_window_pts)/sum(hamming(conv_window_pts)),'same')';
                csg2 = convn(CC(ii,(mid+1):end)',hamming(conv_window_pts)/sum(hamming(conv_window_pts)),'same')';
               % csg1 = sgolayfilt(CC(ii,1:mid),ord,conv_window_pts+1);
               % csg2 = sgolayfilt(CC(ii,(mid+1):end),ord,conv_window_pts+1);
                csg = [csg1 csg1(end) csg2];
                csg(1:conv_window_pts/2) = nan; % remove the invalid points - assumes zero padded.
                csg(end-conv_window_pts/2:end) = nan; % - assumes zero padded.
                
            else
                % do a convolution - it's a hack, but sgolay rings with
                % sharp peaks.
                %  Also the ends tend to look like crap if there is a zero
                %  bin at the end.
                %orig = CC(ii,[1 end]);
                %CC(ii,[1 end]) = [mean(CC(ii,1:conv_window_pts)) mean(CC(ii,end-conv_window_pts:end))];
                % Look out for nans, they will kick you in the ass.
                tmp = CC(ii,:);
                ix = find(isnan(tmp));
                if ~isempty(ix)
                    if ix(1) > 1
                        tmp(ix) = tmp(ix-1);
                    else
                        tmp(ix(1)) = tmp(ix(2));
                        tmp(ix(2:end)) = tmp((2:end)-1);
                    end
                end
                csg = convn(tmp',hamming(conv_window_pts)/sum(hamming(conv_window_pts)),'same');
                if any(isnan(csg))
                else
                    csg(1:conv_window_pts/2) = nan; % remove the invalid points - assumes zero padded.
                    csg(end-conv_window_pts/2:end) = nan; % - assumes zero padded.
                end
                % the sgolay is OK but it rings at peaky points so
                % defaulting to the conv with a hamming. Seems to work
                % fine.
                % plot(xdim,csg,'g','LineWidth',2)
                %                    text(xdim(end-(xdim(end)-xdim(1))/10),max(csg),['hm' num2str(conv_window_pts/2)])
                % if ~isnan(ord)
                %     csg = sgolayfilt(CC(ii,:),ord,conv_window_pts+1);
                %     sm_color = 'y';
                % end
                %                   text(xdim(end-(xdim(end)-xdim(1))/10),max(csg),['sg' num2str(conv_window_pts+1)])
            end
            smoothed_y = csg;
        end
        %        xdim_sp = linspace(xdim(1),xdim(end),round(length(xdim)/4));
        %        csp = spline(xdim,CC(ii,:),xdim_sp);
        %        hpts = round(conv_window_pts/2);
        %        c = c(hpts:(end-hpts));
        %        c(1:hpts) = nan;
        %        c((end-hpts):end) = nan;

        plot(xdim,smoothed_y,'k','LineWidth',3)
        plot(xdim,smoothed_y,sm_color,'LineWidth',2)
    end
    
    a    = axis;
    a(3) = nanmin( CC(ii,:) );
    axis(a)
    a = axis;
    hold on
    % plot a centerline
    plot([0 0 ]',[a(3) a(4)]','-.','Color','g')
end