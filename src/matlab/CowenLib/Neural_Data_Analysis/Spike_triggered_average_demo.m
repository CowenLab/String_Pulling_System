%%%%%%%%%%%%%%%%%%%%%%%%%
%% Demonstrate STAs, STCs and prove to ourselves that they work by comparing to random data.
% Cowen
%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate some fake data...
%%%%%%%%%%%%%%%%%%%%%%%%%
win_bins = 100;
sig_type = 'punctate';
% sig_type = 'sin';
switch sig_type
    case 'sin'
        sig = sin(0:.1:100*2*pi);
        [~,locs] = findpeaks(sig);
        locs = locs +10;
        locs(locs<1) = [];
    case 'punctate'
        ntrans = 2600;
        win = hanning(100);
        win = win(1:50);
        win = win/max(win);
        sig = randn(2e5,1)*2;
        locs = round(rand(ntrans,1)*length(sig));
        locs(locs>length(sig)) = [];
        locs(locs<1) = [];
        
        for ii = 1:length(locs)
            sig((locs(ii)-length(win)+1):locs(ii)) = sig((locs(ii)-length(win)+1):locs(ii)) + win*10;
        end

end

sig = sig(:);
locs = locs(:);
pks = sig(locs);

sh_locs = round(locs+rand(size(locs))*median(diff(locs)));
sh_locs(sh_locs > length(sig)) = [];
sh_locs(sh_locs < 1) = [];
sh_pks = sig(sh_locs);

sig  = sig + randn(size(sig))*.2;
figure

plot(sig,'.-')
hold on
plot(locs,pks,'r.')
plot(sh_locs,sh_pks,'c+')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decide whether to do on phase-locked or shuffled.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = locs;
% t = sh_locs;
bin_spikes = zeros(size(sig));

bin_spikes(t) = 1;

% OK, the locs are at the peaks. Should be quite clear what the sta will
% look like right? Like a curve going down...
[STA,STC,RawMu,RawCov] = simpleSTC(sig(:), bin_spikes(:), win_bins);
simpleSTC_plot(1,STA,STC,RawMu,RawCov);
simpleSTC_bootstrap(sig,bin_spikes,win_bins,300);
% Now, do the same with the PETH approach.
% 
DATA = [[1:length(sig)]'  sig];
figure
PETH_EEG_simple(DATA,t,win_bins,1);
% The above confirms that the two approaches produce identical results.
% Big relief
%%%%%%%%%%%%%%%%%%%%%%%%%
% Decomposing results into the dimensions of preincipal variance...
% This I still do not understand - the interpretation of the output.
%%%%%%%%%%%%%%%%%%%%%%%%%
[e,ev] = eig(STC);
figure
subplot(1,2,1)
plot(e(:,1)); hold on; plot(e(:,2));plot(e(:,3));
title('What do the eigenvectors truly represent here?')
subplot(1,2,2)
bar(diag(ev));
