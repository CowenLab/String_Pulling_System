function [L, P] = Filter_for_spikes(L,sFreq,filt_range,filt_type)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [L] = filter_for_spikes(L,sFreq,filt_range,filt_type)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filters for spike data. Typically this is between 600 and 6000;
% L is a nsample x nChannel matrix.
% sFreq
% filt_range is a 2 col vector of the lower and upper filter range.
% TODO: See https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5373639/ which
% claims that simply flipping the signal, filtering, and then fipping back
% is sufficient to remonve much artifiact... Actually, we do this already
% by using filtfilt instead of filter in matlab - seems silly that the
% entire article boils down to using filtfilt unless I am misunderstanding
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2010.
% Cowen 2015 - now it works in blocks if there is a very large rec. Need to
% do this for memory reasons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3 || isempty(filt_range)
    filt_range = [600 6000];
end
blocksize_recs = 1e7;

if nargin < 4
    %filt_type = 'cheby1';
    filt_type = 'ellip'; % Seems a bit faster than cheby1 and butter.
    %filt_type = 'butter';
end

data_class = class(L);
if ~strcmpi(data_class,'double');
    % Preserve the class of the variable.
    L = double(L);
end
rip = 0.1;
switch filt_type
    case 'ellip'
        % From Wave_clus
        % noticed that this can create an artificatual 'rise' at the start
        % of spike - at least with order 2.
        % This does work but it seems to be more sensitive to low frequency
        % artifact - it picks it up more.
        ord = 2; % 2 is default. I tried 8 and that creates more artifact and ringning adn lower amplitude.
        [b,a] = ellip(ord,rip,40,filt_range*2/sFreq);
    case 'cheby1'
        ord = 4;
        % Something I made.
        [b,a] = cheby1(ord,rip, filt_range*2/sFreq);
    case 'butter'
        % % FROM Kleinfeld spike_sort code. example of filtering
        filt_range = [600 10000];
        Wp = [ 800  8000] * 2 / sFreq - eps;
        Ws = [ 600 10000] * 2 / sFreq- eps;
        [ord,rip] = buttord( Wp, Ws, 3, 20);
        [b,a] = butter(ord,rip);
    otherwise
        error('incorrect parameter')
end
% If the file is HUGE, then filter in blocks.

if Rows (L) <= blocksize_recs
    for iT = 1:Cols(L)
        L(:,iT) = filtfilt(b,a,L(:,iT));
    end
else
    % Do it in blocks because it is too darn big.
    blocks = round(linspace(1,Rows(L),ceil(Rows(L)/blocksize_recs)));
    if length(blocks) == 1
        error('Blocks were not calculated correctly')
    end
    disp(['Breaking filtering into ' num2str(length(blocks)-1) ' blocks'])
    for iB = 1:(length(blocks)-1)
        for iT = 1:Cols(L)
            L(blocks(iB):blocks(iB+1),iT) = filtfilt(b,a,L(blocks(iB):blocks(iB+1),iT));
        end
    end
end

% return to the original class.
% This could be dangerous. Potential data or information loss if going from
% filtered 64 bit back down to say 16 bit. Maybe this is a bad idea.
if ~strcmpi(data_class,'double')
    disp(['Converting back to a ' data_class])
    L = feval(data_class,L);
end

if nargout >1
    P.filt_range = filt_range;
    P.sFreq = sFreq;
    P.filt_type = filt_type;
    P.a = a;
    P.b = b;
    P.ord = ord;
    P.rip = rip;
end