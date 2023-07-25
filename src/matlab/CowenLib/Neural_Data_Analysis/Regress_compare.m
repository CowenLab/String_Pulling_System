function st = Regress_compare(varargin)
% INPUT: nx2 vectors of points to plot and compare. The first column. For instance 
%        should be sleep, the second behavior.
% OUTPUT: a plot of the bais or center of mass. if no output is specified, then a plot
%         is produced.
% cowen 4/28/02
colors =  {'b','r','g','m','k','c'};
use_dots = 0;
if min(varargin{1} < -.5)
    axis_square = 1;
else 
    axis_square = 0;
end


for ii =1:length(varargin)
    if strcmp(varargin{ii},'.')
        use_dots = 1;
    end
    if strcmp(varargin{ii},'axis_square')
        axis_square = 1;
    end

end
if use_dots
    symbols = {'.','.','.','.','.','.','.','.','.','.'};
    marker_size  = .5;
else
    symbols = {'+','^','o','p','<','>'};
    marker_size  = 1;
end

mx = -inf;
text_string = [];

for ii = 1:length(varargin)
    % Get rid of rows that have nans. This screws up regress.
    [rr,cc] = find(isnan(varargin{ii}));
    varargin{ii}(unique(rr),:) = [];
    if isempty(varargin{ii})
        error('Empty input (after nans removed)')
    end
    
    [b,bint,res,resint,stats] = regress(varargin{ii}(:,2),[ones(length(varargin{ii}(:,1)),1) varargin{ii}(:,1)]);

    st.slope(ii) = b(2);
    st.low_confidence_95(ii) = bint(2,1);
    st.up_confidence_95(ii)  = bint(2,2);
    st.Rsq(ii)= stats(1);
    st.F(ii) = stats(2);
    st.p(ii) = stats(3);

    if nargout == 0
        plot(varargin{ii}(:,1),varargin{ii}(:,2),[ symbols{ii} colors{ii}],'Markersize',marker_size);
        
        hold on
        mx = nanmax([mx;nanmax(abs(varargin{ii}(:,1)))]);
        text_string = [text_string sprintf( '%sp=%0.3f n=%d Rsq=%.2f', symbols{ii},st.p(ii),Rows(varargin{ii}),st.Rsq(ii))];
    end
    
end
if length(varargin) > 1
    if st.slope(1) > st.slope(2)
        if st.low_confidence_95(1) < st.up_confidence_95(2) 
            st.different = 0;
        else
            st.different = 1; 
        end
    else
        if st.low_confidence_95(2) < st.up_confidence_95(1) 
            st.different = 0;
        else
            st.different = 1; 
        end
    end
end

    

if nargout == 0
    %
    % If more than one arg is passes in, compare the regression lines to see if they are different.
    %
    if length(varargin) > 1
        if st.different
            text_string = [text_string sprintf( '(%s%s) diff', symbols{1},symbols{2})];
        else
            text_string = [text_string sprintf( '(%s%s) ~diff', symbols{1},symbols{2})];
        end
    end
    
    if axis_square
        axis square
        axis([-mx mx -mx mx]);
        t = text(-mx*.9 ,mx*.9,text_string);
        l1 = line([0 0],[-mx mx]);
        l2 = line([-mx mx],[0 0]);
    else
        axis tight
        a = axis;
        t = text(a(1)*.9 ,a(4)*.9,text_string);
    end
    
    lsline;
    xlabel('rest')
    ylabel('behavior')
   
    set(t,'FontSize',6)
end
