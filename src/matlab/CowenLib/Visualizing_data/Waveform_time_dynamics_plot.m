function H = Waveform_time_dynamics_plot(wv);
%function h = Waveform_time_dynamics_plot(wv);
% Plots the waveform value at time t against the value at t+1
% INPUT: a waveform matrix where each row is an observation and each col is a voltage val.
% OUTPUT: plot and figure handle.
% cowen
maxc = 100;
[r,c] = find(wv);
[idx] = find(wv);

%plot(wv',wv(:,32:-1:1)','.','MarkerSize',1)
H = ndhist([wv(idx(1:end-1))'; wv(idx(2:end))'],[200 200]',[-2048 -2048 ]',[2048 2048]')';
%s = sum(H);
%H(:,find(s==0)) = [];
%s = sum(H');
%H(find(s==0),:) = [];
imagesc(H);
axis xy
axis tight
caxis([0 min([max(H(:)) maxc])])
axis off

