function [OUT] = LK_Load_and_Clean_LFP(LFP_Dir,sig_file, ref_files)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the important files that go with just about any analysis...
% Cowen 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [GP,E,EVT,SP,RHD,META,DEPTHS,TS] = LK_Load_Important_Things();
SES = LK_Session_Info();
% lfp_dir = fullfile(LFP_Dir,SES.rat_str,SES.session_str,'LFP');
% [~,LFP_files] = find_files(fullfile(lfp_dir,'amp*.mat'));
load(fullfile(LFP_Dir,sig_file),'LFP');
SIG = double(LFP.data)*LFP.to_uV_conversion;
SIG = SIG - mean(SIG(1:5:end));
sFreq = LFP.LFP_sFreqj;
OUT.sFreq = sFreq;
OUT.t_uS = (0:(length(SIG)-1))/sFreq;
OUT.t_uS = 1e6*OUT.t_uS(:);
OUT.sig_file = sig_file;
OUT.full_file_path = fullfile(LFP_Dir,sig_file);

if nargin > 2
    for iF = 1:length(ref_files)
        load(fullfile(LFP_Dir,ref_files{iF}),'LFP');
        if iF == 1
            REF = zeros(length(LFP.data),length(ref_files));
        end
        REF(:,iF) = double(LFP.data)*LFP.to_uV_conversion;
        REF(:,iF) = REF(:,iF) - mean(REF(1:5:end,iF));
    end
    % imagesc(L)
    [OUT.LFP, OUT.stats] = SPEC_rereference(SIG,REF);
    OUT.ref_files = ref_files;
else 
    OUT.LFP = SIG;
end