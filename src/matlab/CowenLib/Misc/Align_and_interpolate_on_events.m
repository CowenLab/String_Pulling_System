function O = Align_and_interpolate_on_events(M, orig_x, align_events, new_x_zero_is_center, fill_nans_with_interpolants)
% Align elements in M on alignment events in align_events and interp to the
% new_x_zero_is_center values.
%
% Cowen 2016

if nargin <5
    % Fills unknown values with interpolants. This is OK for small blank
    % spots, but probably should not be done if there are huge gaps.
    fill_nans_with_interpolants = true;
end

if fill_nans_with_interpolants > 1
    n_contig_for_interp = fill_nans_with_interpolants;
else
    n_contig_for_interp = round(Rows(M)*.005);
end
O = NaN(length(new_x_zero_is_center),Cols(M),length(align_events));
m = NaN(length(new_x_zero_is_center),Cols(M));
d = nanmedian(diff(new_x_zero_is_center));

for iA = 1:length(align_events)
    newx = orig_x - align_events(iA);
    % restrict to just the ROI
    GIX = newx >=  new_x_zero_is_center(1) - d*10 & newx <=  new_x_zero_is_center(end)+ d*10 & newx ~=0 ; % add a buffer for better interpolation.
    newx = newx(GIX);
    MM = M(GIX,:);
    for iC = 1:Cols(M)
        V = MM(:,iC);
        BADIX = isnan(V) | isinf(V);
        if fill_nans_with_interpolants
            C = Count_contiguous(BADIX);
            non_interp_IX = C >= n_contig_for_interp;
        end
        if sum(~BADIX) > 5
            m(:,iC) = interp1(newx(~BADIX),V(~BADIX),new_x_zero_is_center,'linear'); % pchip does a better job - does not create the -infinity issue (log(0)
            if ~fill_nans_with_interpolants
                % preserve nans - find the closest new_x_zero_is_center to each nan
                % in the origainl data
                ix = binsearch_vector(new_x_zero_is_center,newx(BADIX));
                ix = unique(ix);
                ix = ix(2:end-1);

                if ~isempty(ix)
                    m(ix,iC) = nan;
                end
            end
        else
%             disp([mfilename ':no usable data'])
        end
        if 0 % WARNING NOT WORKSING
        if fill_nans_with_interpolants
            % if an exceptionally long string of non-data, then fill with
            % nans. 
            if any(non_interp_IX)
                m(non_interp_IX,iC) = nan;
            end
        end
        end
        %         ix = binsearch_vector(new_x_zero_is_center,newx(~NO_NANIX)+d);
        %         m(unique(ix),:) = nan;
        %         ix = binsearch_vector(new_x_zero_is_center,newx(~NO_NANIX)-d);
        %         m(unique(ix),:) = nan;
        %
        
    end
    if any(isinf(m))
        error('Infinities!!! Bad interpolation proably')
    end
    O(:,:,iA) = m;
end
