function r = Multi_corr(A,B,C,interval_size,on_same_tet)
%function [p_r,rm_s1] = Multi_partial(A,B,C,interval_size)
% INPUT:
%    q matrices for each epoch
%    The interval size from which to compare Rm,s2|s1
%
% OUPUT:
%    r(1:Cols(C)/interval_size+1) where r(1) = r_ms1 and r(2:end) =
%    the r for each interval in the C matrix.
%

% cowen Thu Apr 15 16:17:26 1999
% adjusted a bit by Anne June 22
% This version throws out on same tet correls
% instead of zeroing them but still zeros
% out Nans from the corrcoef command
% Also, section which calcs the partial
% correl for S2 is commented out

size(A)
size(B)
size(C)


if nargin == 4
  on_same_tet = []
end

cA = []; % these will contain the lower diag of the R matrices
cB = [];
cC = [];
%error('as');

[N,c] = size(A);

n_intervals = floor(Cols(C)/interval_size);

if n_intervals == 0
  interval_size = Cols(C)-2;
  n_intervals = 1;
end

% compute the NxN R matrices
disp('Computing corrcoef of A ')
rA  = corrcoef(A');
disp('Computing corrcoef of B ')
rB  = corrcoef(B');
rA(on_same_tet) = inf;
rB(on_same_tet) = inf;
%figure;imagesc(rA);



%Find and eliminate any intervals that don't have any firing

start_idx = 1;
disp('Computing corrcoef of C ')

for ii = 1:n_intervals
  end_idx = start_idx + interval_size;
  fprintf('.');
  rC{ii} = corrcoef(C(:,start_idx:end_idx)');
  rC{ii}(on_same_tet) = inf;
%  figure
%  imagesc(rC{ii});
  fprintf('interval %i ', ii);
  start_idx = end_idx;
end


% extract the diagonals of the R matrices
% They become one large vector

for ii= 1:n_intervals
  cC{ii} = [];
end

for k = 1:N-1
  cA = [cA;diag(rA,k)];
  cB = [cB;diag(rB,k)];
  for interval = 1:n_intervals
    cC{interval} = [cC{interval};diag(rC{interval},k)];
  end
end


%Set all Nans to 0;
cA(find(isnan(cA))) = 0;
cB(find(isnan(cB))) = 0;
for jj = 1:n_intervals
  cC{jj}(find(isnan(cC{jj}))) = 0;
end

%Only consider non-Infs
% i.e. throw away stuff on same tetrode
f1 = find(isinf(cA)==0);
cA = cA(f1);
cB = cB(f1);
for jj = 1:n_intervals
  cC{jj} = cC{jj}(f1);
end


% compute the correlations of the correlations for each interval
rB_C = zeros(n_intervals,1);
%rA_C = zeros(n_intervals,1);

rB_A = diag(corrcoef(cA,cB),1);
for interval = 1:n_intervals
  rB_C(interval) = diag(corrcoef(cC{interval},cB),1);
%  rA_C(interval) = diag(corrcoef(cA,cC{interval}),1);
end

% compute the corrcoef (r) for m,s2|s1 for each interval
r(1) = rB_A; % First element is not the partial. 
r(2:2+n_intervals-1) = rB_C;


