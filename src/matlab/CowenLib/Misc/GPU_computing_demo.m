gpuDeviceCount
% Saw 7x improvement with a RTX 2070 with spectrogram. did not matter if
% the monitor was plugged in or not.
% 
% tic
d = gpuDevice % use reset(d) to reset memory on device
% toc
d.ComputeCapability
r = rand(100000,10);
g = gpuArray(r);
% glfp = gpuArray.rand(1e6,1,'single');
glfp = gpuArray.rand(1e6,1,'single'); % Choose teh initial size carefully. If you fill up the GPU, then it wont' work again ultil you reset matlab.
d.AvailableMemory
% What I don't understand is what fills the gpu up. If there are 2GB of RAM
% in the GPU, then that's 2e9 bytes so 2e9/4 = 500 000 000 - that's 500
% million points which is huge. 
%
% lfp = rand(1e6,1,'single');
% lfp = rand(2^nextpow2(2e6),1,'single');
tic
for ii = 1:10
    glfp = gpuArray.rand(1e6,1,'single');
%     d.AvailableMemory/4 % even this is not giving you the whole story (died at 1e7, but only after running 2 iterations - so strange)
    V2 = gather(spectrogram(glfp)); % - need to remember that this dies at 10 million points, and once it dies once, it will not really work again until you restart matlab. I tried clearing the GPU, but that did not work.
    %     reset(d) does not save it once it dies. You need to restart matlab.
    %     Sad.
    
end
toc
%%
% g = [];
% tic
% for ii = 1:10
%     g{ii} = gpuArray.rand(30e6,1,'single');
% end
% o = cellfun(@spectrogram, g);
% toc
ARR_SIZE = 30e6;

% Seems to work well regardless of sze
% glfp = gpuArray.rand(ARR_SIZE,1,'single'); % Choose the initial size carefully. If you fill up the GPU, then it wont' work again ultil you reset matlab.
lfp = rand(ARR_SIZE,1,'single');
glfp = gpuArray(lfp);
classUnderlying(glfp)
disp('START GPU spectrogram')
tic

for ii = 1:10
    %     d.AvailableMemory/4 % even this is not giving you the whole story (died at 1e7, but only after running 2 iterations - so strange)
    V2 = spectrogram(glfp); % - need to remember that this dies at 10 million points, and once it dies once, it will not really work again until you restart matlab. I tried clearing the GPU, but that did not work.
    %     V3 = spectrogram(lfp); % - need to remember that this dies at 10 million points, and once it dies once, it will not really work again until you restart matlab. I tried clearing the GPU, but that did not work.
    %     reset(d) does not save it once it dies. You need to restart matlab.
    %     Sad.
    
end
V4 = gather(V2);
toc
disp('END GPU spectrogram')


disp('Start non-GPU spectrogram')
tic
%  glfp = gpuArray.rand(10e6,1,'single'); % Choose teh initial size carefully. If you fill up the GPU, then it wont' work again ultil you reset matlab.
for ii = 1:10
    %     d.AvailableMemory/4 % even this is not giving you the whole story (died at 1e7, but only after running 2 iterations - so strange)
    %      V2 = spectrogram(glfp); % - need to remember that this dies at 10 million points, and once it dies once, it will not really work again until you restart matlab. I tried clearing the GPU, but that did not work.
    V3 = spectrogram(lfp); % - need to remember that this dies at 10 million points, and once it dies once, it will not really work again until you restart matlab. I tried clearing the GPU, but that did not work.
    %     reset(d) does not save it once it dies. You need to restart matlab.
    %     Sad.
    
end
toc
disp('END non-GPU spectrogram')

disp('Is the output exactly the same?')
[V3(1:10)' V4(1:10)']

figure
subplot 211
imagesc((real(V3)));
colorbar
subplot 212
imagesc((real(V4)));
colorbar


tic
[phase,pow,filtsig,edge,convresphase_out] = SPEC_waveletdecomp(20,lfp(1:2000000),1000,5);
toc

tic
[phase,pow,filtsig,edge,convresphase_out] = SPEC_waveletdecomp(20,glfp(1:2000000),1000,5);
toc

%%

