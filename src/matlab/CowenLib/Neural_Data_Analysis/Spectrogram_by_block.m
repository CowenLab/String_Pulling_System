function [aSPEC,T,fq] = Spectrogram_by_block(LFP,window,noverlap,nfft,sFreq,chunk_duration_minutes,bands)
%function [SPEC,T,fq] = spectrogram_by_block(M,window,noverlap,nfft,sFreq,bands,block_size)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Computes the power spectrogram for
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 6
    chunk_duration_minutes = 5;
end
if nargin < 7
    bands = [];
end
block_overlap_sec = 2;
t = 1:length(LFP); % record numbers.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
block_size = sFreq*chunk_duration_minutes*60; % The duration of each chunk.
block_sec = block_size/sFreq;
block_overlap = sFreq*block_overlap_sec;
% Times to extract from each block.

if block_size > length(LFP)
    % The data is smaller than the block size so it's only one block
    % long.
    [S, fq, times, SPEC] = spectrogram(LFP,window,noverlap,nfft,sFreq);
    aSPEC = SPEC';
    return
else
    % Break the data up - lest you runeth out of memory.
    blocks = [(2:block_size:(length(LFP) - block_size) ) - 1; block_size:block_size:length(LFP)]';
    blocks(end) = length(LFP);
    nBlocks = Rows(blocks);
    o_block = [blocks(:,1) - block_overlap blocks(:,2) + block_overlap];
    o_block(1) = blocks(1);
    o_block(end) = blocks(end);
    aSPEC = [];
    R = [];
    for iB = 1:nBlocks
        [S, fq, times, SPEC] = spectrogram(LFP(o_block(iB,1):o_block(iB,2)),window,noverlap,nfft,sFreq);
        SPEC = SPEC';
        if ~isempty(bands)
            % pull out the specific frequency bands and throw away the rest.
            SPECb = zeros(Rows(SPEC),Rows(bands));
            for iBand = 1:Rows(bands)
                SPECb(:,iBand) = mean(SPEC(:,fq >= bands(iBand,1) & fq <= bands(iBand,2)),2);
            end
            SPEC = SPECb;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Find the clean section of data (void of edge effects since I am
        % using overlap).
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if iB == 1
            ix = times < (times(end)-block_overlap_sec);
        elseif iB == nBlocks
            ix = times > block_overlap_sec;
        else
            ix = times > block_overlap_sec & times < (times(end)- block_overlap_sec);
        end
        r = linspace(blocks(iB,1),blocks(iB,2),sum(ix));
        aSPEC = [aSPEC;SPEC(ix,:)];
        R = [R;r(:)];
       % size(SPEC)

    end
   
    newR = linspace(R(1),R(end),Rows(aSPEC));
    for iC = 1:Cols(SPEC)
        aSPEC(:,iC) = interp1(R,aSPEC(:,iC),newR)';
    end
    T = newR/sFreq; % Convert record number to seconds.
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout == 0;
    imagesc(fq,T,10*log10(abs(aSPEC)))
    xlabel('fq');
    ylabel('time')
    title('10*log10(abs(aSPEC))')
end