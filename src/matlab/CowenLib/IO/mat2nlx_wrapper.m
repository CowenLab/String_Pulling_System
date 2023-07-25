function mat2nlx_wrapper(fname,T,WV)
% This won't work on a mac as Neuralynx functions never work on macs -
% stupid.
%
% Takes a 3D matrix of waveform data (32pts x nChannels(4) x record) and time
% and saves it to fname.
%
% Timestamps presumed to be in uSec.
% waveform data should be in the range of +/- 2048.
% presumed to be tetrodes (for now).
%
% cowen (2009)

% % test data for checking
% fname = 'test.ntt';
% T = 10000000:20000:20000000;
% wv = [1 2 1 3 5 100 200 300 500 300 200 100 -100 -200 -100 0 100 0 0 1 0 1 1 1 1 1 1 1 1 1 1 1 ];
% WV = zeros(32,4,length(T));
% WV(:,1,:) = repmat(wv,length(T),1)';
% WV(:,2,:) = repmat(wv,length(T),1)' + 100;
% WV(:,3,:) = repmat(wv,length(T),1)' + 200;
% WV(:,4,:) = repmat(wv,length(T),1)' + 300;
% WV = WV + randn(size(WV))*90;
switch size(WV,2)
    case 1        
        mat2nlxse([fname '.nse'], T(:)', zeros(1,length(T)), zeros(1,length(T)), zeros(8,length(T)), WV, length(T));
    case 2
        disp('Warning, mat2nlxst does not seem to work. Try at own risk. Converting to tetrodes.')
        WV = cat(2,WV,WV(:,1:2,:)*0);
        %fname = ;
        mat2nlxtt_v1([fname '.ntt'], T(:)', zeros(1,length(T)), zeros(1,length(T)), zeros(8,length(T)), WV, length(T));
        % This DOES NOT WORK. FRACKING NLX. I have to make this into a
        % tetrode and then save it.
        %mat2nlxst(fname, T(:)', zeros(1,length(T)), zeros(1,length(T)), zeros(8,length(T)), WV, length(T));
    case 4
        mat2nlxtt_v1([fname '.ntt'], T(:)', zeros(1,length(T)), zeros(1,length(T)), zeros(8,length(T)), WV, length(T));
end
