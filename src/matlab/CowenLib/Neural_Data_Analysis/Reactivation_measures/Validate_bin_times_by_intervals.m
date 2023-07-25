% Validate bin_times_by_intervals
nCells = 10;
[spike_ca, x_tsd, y_tsd,pf_ctr] = Artificial_place_cells(60*2,nCells,[20 1],1,.01);
for ii = 1:length(spike_ca)
    sumca(ii) = length(spike_ca{ii});
end
tic
Q = bin_ts_array(spike_ca,100,100,0);
toc
figure
subplot(2,1,1)
imagesc(Q)
tic
Q2 = bin_ts_array(spike_ca,100,100,1);
toc
subplot(2,1,2)
imagesc(Q)
figure
imagesc(Q-Q2)
figure
subplot(1,2,1)
imagesc(corrcoef(Q) .* triu(ones(size(Q,2)),1))
subplot(1,2,2)
imagesc(corrcoef(Q2) .* triu(ones(size(Q2,2)),1))
sum(Q) - sum(Q2)
sum(Q)
sum(Q2)
sumca