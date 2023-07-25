function POS = position_from_nvt(fname,option)
% INPUT: File name, option
% OUTPUT: position data - SMOOTHED and 0 points are replaced with
% interpolated data. Always check your data.
% 
% cowen.
if nargin ==0
    fname = 'VT1.nvt';
end
if nargin < 2
    option = 'raw';
    %offset = 0; % amount to correct the timing of the position data -- e.g. if there is a known delay in the video tracker.
end
FieldSelection(1) = 1;
FieldSelection(2) = 1;
FieldSelection(3) = 1;
FieldSelection(4) = 0;
FieldSelection(5) = 0;
FieldSelection(6) = 0;
ExtractHeader = 0;
ExtractMode = 1;
[t, x, y] = Nlx2MatVT_v4( fname, FieldSelection, ExtractHeader, ExtractMode);
switch option
    case 'raw'
        POS(:,1) = t;
        POS(:,2) = x;
        POS(:,3) = y;
    case 'medianfilt'
        % not much if any smearing.
        I = x > 0 & y > 0; % Get rid of zeros.
        % Fill in the gaps.
        x2 = interp1(t(I),x(I),t); % Note: DO NOT USE SPLINE - screws things up.
        y2 = interp1(t(I),y(I),t);

        x2 = medfilt1(x2,4); % Note: DO NOT USE SPLINE - screws things up.
        y2 = medfilt1(y2,4); % Note: DO NOT USE SPLINE - screws things up.
        
        %         x3 = sgolayfilt(x2,3,11); % Note: DO NOT USE SPLINE - screws things up.
        %         y3 = sgolayfilt(y2,3,11); % Note: DO NOT USE SPLINE - screws things up.
        
        POS = zeros(length(t),3);
        POS(:,1) = t;
        POS(:,2) = x2;
        POS(:,3) = y2;
 
    case 'smooth'
        I = x > 0 & y > 0;
        % Fill in the gaps.
        x3 = interp1(t(I),x(I),t); % Note: DO NOT USE SPLINE - screws things up.
        y3 = interp1(t(I),y(I),t);

        POS = zeros(length(t),3);
        POS(:,1) = t;
        POS(:,2) = sgolayfilt(x3,3,11);
        POS(:,3) = sgolayfilt(y3,3,11);
    otherwise
        error('Unknown option')
end
