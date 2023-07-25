function [O] = GPU_fft(X,N) 
%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0 
    X = randn(1e5,1);
    N = [];
end
if nargin < 2
    N = [];
end
%
Buffer_in_bytes = .5e6;
nGPUs = gpuDeviceCount;
GPU_to_use = 1;
if nGPUs == 0
    [O] = fft(X,N);
    return
end
% If multiple gpu devices, find the one with the most memory
if nGPUs > 1
    for ii = 1:nGPUs
        d = gpuDevice(ii);
        mem(ii) = d.AvailableMemory;
    end
    [~,GPU_to_use] = max(mem);
end
d = gpuDevice(GPU_to_use);
s=whos('X');
b1 = [s.bytes];
mem_avail_bytes = d.AvailableMemory - b1;
if mem_avail_bytes >  Buffer_in_bytes
    % Access violation detected error - often - not sure why.
    % Caught MathWorks::System::FatalException
    X = gpuArray(X);
    % Actually - this might not work with the toolbox.
    [O] = fft(X,N);
    X = gather(X);
    disp('Used GPU')
else
    disp('Not enough space on GPU')
    [O] = fft(X,N);
end

