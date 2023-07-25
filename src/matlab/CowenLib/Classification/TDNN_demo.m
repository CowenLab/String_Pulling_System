% propagate inputs through a TDNN
% --------------------------------------------------------------------
% --------------------------------------------------------------------
%!python c:\Source~2\Scripts\Promoted\net_to_mat.py bdg_tdnn.net
clear all
% --------------------------------------------------------------------
% Load in the output from SNNS
% --------------------------------------------------------------------
addpath(fullfile(Homedir,'matlab','SNNS_tools'))
bdg_TDNN_pat; 
bdg_TDNN_net_condef; 
bdg_TDNN_net_unitdef; 
% --------------------------------------------------------------------
% Define useful parameters
% --------------------------------------------------------------------
% Dimensions of the Input and Hidden layers.
Irows = 7;    % Freq -- the RF slides over this dimesion (in the Q matrix, it will slide over time)
Icols = 16;   % Time -- the RF coveres this dimension entirely (in Q this is the cell dim)
RFsize = 3;   % covers all time and 3 frequency slices
nRFs  = Irows - RFsize + 1;   % the number of receptive fields
nfeatures = 8;% Number of features
nsamples = length(out_pat);
% Number of input and hidden units
nOunits = Rows(o_net);
% Receptive field size(rows and columns)
% Input activation and bias
% Rows and cols need to be reversed to keep it in place x time format
% also, randomly shuffle the input-output pairs.
rndnum= randperm(nsamples);
cnt = 1;
for idx = rndnum
   IN{idx}       = reshape(in_pat{cnt},Icols,Irows)';
   OUT{idx}      = repmat(out_pat{cnt},nRFs,1);
   cnt = cnt + 1;
end

% Weights from input to H(rows represent hidden units, cols input)
wIH = randn(Icols*RFsize+1,nfeatures)/10; % +1 is for th the bias

% Weights from hidden to output(rows represent output, cols hidden)
wHO = randn(nfeatures+1,nOunits); % +1 is for th the bias
% --------------------------------------------------------------------
% Create a novel input layer that represents the overlap of the receptive fields
% This allows the activation calculation to be performed in one step.
%
% Input in format where each row represents the vectorized receptive field
% Weights in format where each column represents a weight from the corresponding
% input to one particular hidden unit.
%
% The output of the multiplication is a matrix where the rows represent the different
% windows and the columns represent the different features.
% --------------------------------------------------------------------
step = 1; % Overlap RFs by one slice of time.
for sample = 1:length(in_pat)
   % Create a new input layer in which each row represents an entire RF. 
   rI{sample} = Tessel_layer(IN{sample}, step, RFsize);
end
test_indices  = ceil(nsamples/2):nsamples;
train_indices = 1:(ceil(nsamples/2)-1);
test_IN   = Remove_cells(rI,  train_indices);
test_OUT  = Remove_cells(OUT, train_indices);
train_IN  = Remove_cells(rI,  test_indices);
train_OUT = Remove_cells(OUT, test_indices);
% --------------------------------------------------------------------
% Propagate the activation through the network
% --------------------------------------------------------------------
max_total_iters= 600; % Number of total iterations before quitting
max_iter = 50;  % number of iterations before checking with the test set
stop_crit = .1; % SSE stopping criteria
eta = 0.1;      % learning rate
SSE = 999;      % The performance index(SSE)
SSE_vector_test    = []; % The error
SSE_vector_train = []; % The error
tic
count = 0;
while(SSE > stop_crit & count < (max_total_iters/max_iter))
   [wIH,wHO,error_vector,iter] = Neuralnet_bp_sqr_out(wIH,wHO,train_IN,...
      train_OUT,eta,max_iter);
   %[wIH,wHO,error_vector,iter] = Neuralnet_bp(wIH,wHO,train_IN,...
   %   train_OUT,eta,max_iter);
   SSE_vector_train = [SSE_vector_train,error_vector];
   % Check performance with the test set.
   [SSE,E,aH,aO] = Neuralnet_prop_sqr_out(wIH,wHO,test_IN,test_OUT);
   SSE_vector_test = [SSE_vector_test,SSE];
   %SSE_vector_test_x = [SSE_vector_test_x length(SSE_vector_train)] 
   fprintf('SSE on test set: %f\n',SSE)
   count = count + 1;
end
duration = toc;
% --------------------------------------------------------------------
% Convert the two dimensional output matrix back into the one
% dimensional vector
% --------------------------------------------------------------------
for ii = 1:length(aO)
   % determine the mean output for all columns
   OUT_final{ii} = sum(aO{ii})/size(aO{ii},1);
end
% --------------------------------------------------------------------
% Display an input/hidden/output pattern pair
% --------------------------------------------------------------------
for sample = 1:length(test_IN)
   figure;orient landscape
   subplot(2,4,1);imagesc(IN{test_indices(sample)}); title('test input')
   colorbar
   subplot(2,4,2);imagesc(rI{test_indices(sample)}); title('processed input')
   colorbar
   subplot(2,4,3);imagesc(wIH);title('In->Hid wts')
   colorbar
   subplot(2,4,4);imagesc(aH{sample}); title('hidden act')
   colorbar
   subplot(2,4,5);imagesc(wHO);title('Hid->Out wts')
   colorbar
   subplot(2,4,6);imagesc(aO{sample});title('actual act')
   colorbar
   subplot(2,4,7);imagesc(test_OUT{sample}); title('desired out act')
   colorbar
   subplot(2,4,8);hold on;semilogy(SSE_vector_train);semilogy(max_iter:max_iter:length(SSE_vector_train),SSE_vector_test,'r-.');
   %t=text(length(SSE_vector_train)/3,2,0,[ num2str(duration) 's']);
   %set(t,'FontSize',6)
   colormap(1-gray)
   %print
end
 