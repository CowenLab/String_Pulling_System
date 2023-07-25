function [itpc, f_out, x, Wtr, itpcz] = SPEC_itpc_by_event(LFP, sFreq, event_times, sec_before, sec_after, method)
% function [itpc,f_out,x,itpcz] = SPEC_itpc_by_event(LFP,sFreq,event_times, sec_before,sec_after)
%
% inter-trial phase coherence using wavelets and phase estimate.
% Cowen
if nargin < 6
%     method = 'bump';
    method = 'morlet';
end

% method = 'cohen';
if nargin == 0
    % for testing. Compare to known dataset from Cohen.
    load('C:\Users\Stephen Cowen\Dropbox\Foldershare\Src\matlab\Toolboxes\MikeXCohen_book_code\sampleEEGdata.mat')
    M = double(squeeze(EEG.data(strcmpi('pz',{EEG.chanlocs.labels}),:,:))');
    x = EEG.times;
    sFreq = EEG.srate;
    sec_before = abs(x(1));
    sec_after = abs(x(end));
    %     http://www.mikexcohen.com/lecturelets/itpc/itpc.html
    %     SPEC_itpc_by_event([EEG.times(:) EEG.data(1,:,1)'],EEG.srate, event_times, sec_before,sec_after)
else
    [M,~,x] = PETH_EEG_simple(LFP(:,1:2),event_times,sec_before*sFreq,sec_after*sFreq,sFreq,0);
end
%
switch method
    case 'bump'
        % perhaps better frequency resolution. Looks a lot different than morlet.
         [~,f] = cwt(M(1,:)',sFreq,'bump'); %,sFreq,'NumOctaves',4
    case 'morlet'
        % This result looked identical - or nearly so - to Cohen's
        % approach.
        tbandw = 100;
        [~,f] = cwt(M(1,:)',sFreq,'morse','TimeBandwidth',tbandw);
    case 'cohen_morlet'
        range_cycles = [ 4 10 ];
        num_frex = 120;
        % other wavelet parameters
        f = logspace(log10(1),log10(sFreq/2),num_frex);
        wavecycles = logspace(log10(range_cycles(1)),log10(range_cycles(end)),num_frex);
end
f_out = f;
%%
Wtr = nan(length(f_out),size(M,2),size(M,1));
Wph = nan(length(f_out),size(M,2),size(M,1));

for iTrial = 1:Rows(M)
    if ~any(isnan(M(iTrial,:)))
        %         [W,f] = cwt(M(iTrial,:)','bump',sFreq);
        switch method
            case 'bump'
                [W,f] = cwt(M(iTrial,:)',sFreq,'bump'); %'NumOctaves',4
                Wtr(:,:,iTrial) = abs(W);
                Wph(:,:,iTrial) = angle(W);
            case 'morlet'
                % About 8 times faster than the Cohen approach.
                [W,f] = cwt(M(iTrial,:)',sFreq,'morse','TimeBandwidth',tbandw);
                Wtr(:,:,iTrial) = abs(W);
                Wph(:,:,iTrial) = angle(W);
            case 'cohen_morlet'
                [phase,pow,~] = SPEC_waveletdecomp(f_out,M(iTrial,:)',sFreq,8);
                Wtr(:,:,iTrial) = pow;
                Wph(:,:,iTrial) = phase;

        end
%         [Wtr(:,:,iTrial),~,Wph(:,:,iTrial)] = cwt_fix(W',f);
    end
end

%%
itpc = nan(length(f_out),Cols(M));
for iFq = 1:length(f_out)
    itpc(iFq,:) = SPEC_itpc_cohen(squeeze(Wph(iFq,:,:))');
end
%
if nargout == 0
    figure
    contourf(x,f,itpc,40,'linecolor','none') % YOU CANNOT USE IMAGESC - assumes equal spaced y.!
    set(gca,'clim',[0 .6],'ydir','normal') %,'xlim',[-300 1000],'ylim',[1 40]
    title('ITPC')
    colorbar
end
% Should add a shuffle control.
if nargout > 4
    nShuff = 100;
    itpcsh = nan(length(f_out),Cols(M),nShuff);
    %
    shft_recs = round(sFreq + rand(nShuff,1)*sFreq*2);
    LFP2 = LFP;
    for iShuff = 1:nShuff
        LFP2(:,2) = circshift(LFP(:,2),[shft_recs(iShuff) 0]);
        [itpcsh(:,:,iShuff)] = SPEC_itpc_by_event(LFP2,sFreq,event_times, sec_before,sec_after);
    end
    mn = squeeze(nanmean(itpcsh,3));
    sd = squeeze(nanstd(itpcsh,[],3));
    itpcz = (itpc - mn)./sd;
end