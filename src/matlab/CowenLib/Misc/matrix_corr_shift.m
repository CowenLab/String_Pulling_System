function r = matrix_corr_shift(M,Mbase,shift_xy)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the correlation between 2 matrices of equal size after shifting
% M using circshift. Good for circular data.
% cowen 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0
    h = hanning(7)*hanning(7)';
    M = zeros(100,100);
    Mbase = zeros(100,100);
    M(20:26,2:8) = h;
    Mbase(60:66,50:56) = h;
    figure
    subplot(3,1,1)
    imagesc(M)
    subplot(3,1,2)
    imagesc(Mbase)
    
    for ii = 0:(Rows(M)-1)
        for jj = 0:(Cols(M)-1)
            c(ii+1,jj+1) = matrix_corr_shift(M,Mbase,[ii,jj]);
        end
    end
    [mx,ii] = max(max(c,[],2));
    [mx,jj] = max(max(c,[],1));
    newM =  circshift(M,[ii,jj]-1)
    subplot(3,1,3)
    imagesc(newM)
    
    x = xcorr(M(:),Mbase(:));
    [~,ix] = max(x);
    %
    M2 = circshift(M(:),ix);
    M3 = reshape(M2,size(M,1),size(M,2));
    xx = xcorr2(M,Mbase);
    [~, xxj] = max(max(xx));
    [~, xxi] = max(max(xx'));
    newM2 =  circshift(M,[xxi,xxj]);
        subplot(3,1,3)
    imagesc(newM2)
end
M1 = circshift(M,shift_xy);
c = corrcoef(M1(:),Mbase(:));
r = c(2);
