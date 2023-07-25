function [newM,corr_offset] = matrix_corr_shift_align(M,Mbase,method)
% function [newM,corr_offset] = matrix_corr_shift_align(M,Mbase,method)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Match M with Mbase but treat M and Mbase as circular data so use
% circshift to match. Realign M (using cirshift) to best align with Mbase.
% Currently assumes that these matrices are of equal size. If you want to
% match matrices of different sizes, then look closely at xcorr2.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3
    %     method = 'forloop';
    method = 'xcorr';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0
    % demo mode...
    hn = 17;
    h = hanning(hn)*hanning(hn)';
    M = rand(100,100)/2;
    Mbase = rand(100,100)/2;
    M(20:(20 + hn -1),2:(2 + hn -1)) = h;
    Mbase(60:(60 + hn -1),50:(50 + hn -1)) = h;
    %
    NewM = matrix_corr_shift_align(M,Mbase,'forloop');
    %
    figure
    subplot(1,3,1)
    imagesc(M)
    subplot(1,3,2)
    imagesc(Mbase)
    subplot(1,3,3)
    imagesc(NewM)
    %
    isequal(NewM,Mbase)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch method
    case 'forloop'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % slow but thorough
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        c = zeros(Rows(M), Cols(M));
        for ii = 0:(Rows(M)-1)
            for jj = 0:(Cols(M)-1)
                c(ii+1,jj+1) = matrix_corr_shift(M,Mbase,[ii,jj]);
            end
        end
        
        [~,ii] = max(max(c,[],2));
        [~,jj] = max(max(c,[],1));
        corr_offset = [ii,jj]-1;
        newM = circshift(M,corr_offset);
        
    case 'xcorr'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % fast and gpu capable if M and Mbase are gpuArray objects.
        % BUT does not shift using circshft and so will always be biased
        % towards the center.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        xc = xcorr2(Mbase,M);
        nboot = 10;
        xcboot = zeros(size(xc,1),size(xc,2),nboot);
        
        for ii = 1:nboot
            SMx = reshape(randperm(length(Mbase(:))), size(Mbase,1), size(Mbase,2));
            xcboot(:,:,ii) = xcorr2(Mbase(SMx),M);
        end
        mn = squeeze(mean(xcboot,3));
        xc2 = xc - mn;
        
        [~,ix] = max(xc2(:));
        [ypeak,xpeak]=ind2sub(size(xc2),ix);
        corr_offset = [ypeak - size(M,1)  xpeak - size(M,2) ];
        newM =  circshift(M,corr_offset);
        
    otherwise
        error('error: incorrect method.')
end
