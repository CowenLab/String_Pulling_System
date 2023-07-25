function [h, raw_image] = montage(a,cm)
%MONTAGE Display multiple image frames as rectangular montage.
%   MONTAGE displays all the frames of a multiframe image array
%   in a single image object, arranging the frames so that they
%   roughly form a square.
%
%   MONTAGE(I) displays the K frames of the intensity image array
%   I. I is M-by-N-by-1-by-K.
%
%   MONTAGE(BW) displays the K frames of the binary image array
%   BW. BW is M-by-N-by-1-by-K.
%
%   MONTAGE(X,MAP) displays the K frames of the indexed image
%   array X, using the colormap MAP for all frames. X is
%   M-by-N-by-1-by-K.
%
%   MONTAGE(RGB) displays the K frames of the truecolor image
%   array RGB. RGB is M-by-N-by-3-by-K.
%
%   H = MONTAGE(...) returns the handle to the image object.
%
%   Class support
%   -------------
%   The input image can be of class uint8, uint16, or double.
%
%   Example
%   -------
%       load mri
%       montage(D,map)
%
%   See also IMMOVIE.

%   Copyright 1993-2001 The MathWorks, Inc.  
%   $Revision: 5.17 $  $Date: 2001/01/18 15:30:07 $

if (nargin == 0)
    error('Not enough input arguments.');
end

if ((nargin == 2) & (size(cm,1) == 1) & (prod(cm) == prod(size(a))))
    % old-style syntax
    % MONTAGE(D,[M N P])
    warning(['MONTAGE(D,[M N P]) is an obsolete syntax.',...
    'Use multidimensional arrays to represent multiframe images.']);

    siz = cm;
    a = reshape(a,[siz(1) siz(2) 1 siz(3)]);
    if (isind(a(imslice(siz,1))))
        cm = colormap;
        hh = montage(a,cm);
    else
        hh = montage(a);
    end
    
else

    siz = [size(a,1) size(a,2) size(a,4)];
    nn = sqrt(prod(siz))/siz(2);
    mm = siz(3)/nn;
    if (ceil(nn)-nn) < (ceil(mm)-mm),
        nn = ceil(nn); mm = ceil(siz(3)/nn);
    else
        mm = ceil(mm); nn = ceil(siz(3)/mm);
    end
    
    b = a(1,1); % to inherit type 
    b(1,1) = 0; % from a
    b = repmat(b, [mm*siz(1), nn*siz(2), size(a,3), 1]);

    rows = 1:siz(1); cols = 1:siz(2);
    for i=0:mm-1,
        for j=0:nn-1,
            k = j+i*nn+1;
            if k<=siz(3),
                b(rows+i*siz(1),cols+j*siz(2),:) = a(:,:,:,k);
            end
        end
    end
    
    if (nargin == 1)
        
        clf
        hh = imagesc(b, [0 1]);
        set(gca, ...
        'TickDir', 'out', ...
        'XGrid', 'off', ...
        'YGrid', 'off', ...
        'DataAspectRatio', [1 1 1], ...
        'PlotBoxAspectRatioMode', 'auto', ...
        'position', [0 0 1 1]);
        %shading flat
        %caxis([0 1]);
        %figure
        colormap(gray)
        axis off;
        orient tall;
        
    elseif (nargin == 2)
        hh = imshow(b,cm);
        
    else
        error('Too many input arguments.');
    end
    
end

if nargout > 0
    h = hh;
    raw_image = b;
end
