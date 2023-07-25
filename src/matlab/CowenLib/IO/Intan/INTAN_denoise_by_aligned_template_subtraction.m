function DAT = INTAN_denoise_by_aligned_template_subtraction(DAT, recids_for_template, template_size_recs, rec_ids_to_apply_template)
% function INTAN_denoise_by_aligned_template_subtraction(DAT, recids_for_template, template_size_recs, rec_ids_to_apply_template)
% DAT = name of .dat file.
% recids_for_template = the start time (in rec ids) for the start of each
% consistent artifact (e.g. stim start times).
% template_size = how long the artifact lasts - you decide.
% rec_ids_to_apply_template = The location in the original data on which to
% apply the template. This could be the same as recids_for_template.
%
%
% If there is a repeating artifact that is aligned to a known event and
% there is a control period, then develop a template and subtract the
% median of this template to all subsequent records to remove the
% artifact.
% Cowen 2016

plot_it = true;
template_sub_method = 1;

if ischar(DAT)
    dat_file = DAT;
    fp = fopen(dat_file,'rb');
    DAT = fread(fp,'int16');
    fclose(fp);
    write_file = true;
else
    write_file = false;
end

if plot_it
    plot(DAT,'k')
end

M = NaN(length(recids_for_template),template_size_recs);

switch template_sub_method
    case 1 % this will not work for low frequency signals. 
        for ii  = 1:length(recids_for_template)
            M(ii,:) = DAT(recids_for_template(ii):(recids_for_template(ii) + template_size_recs-1));
        end
     case 3
        % This is a work in progress and does not currently work. The main
        % idea is to replace the vlaues in DAT around the artifact with the
        % residuals of a mulitple linear regression. Nice idea, but MLR
        % takes FOREVER so at present, it is completely impractical.
        % THe other big negative of this approach
        % UPshot: I don't know WTF I am doing. Give up. Subtract. Done
        ix = round(linspace(-500,-1,30));
        X = NaN(length(recids_for_template),length(ix));
        for ii  = 1:length(recids_for_template)
            M(ii,:) = DAT(recids_for_template(ii):(recids_for_template(ii) + template_size_recs-1));
            X(ii,:) = DAT(recids_for_template(ii)+ix);
        end
        % Note - replacing the values of DAT with the residuals should work.
        % The problem with the following, however, is that it is quite
        % slow. Actually - incredibly slow. The best may be to estimate the
        % betas from a small subset and then apply them using predict
        % Or we could do the principal components and subtract off say the
        % first 2 coponents.
        %         [b,s,resid] =  mvregress(M(:,1:100),M(:,101:200),'algorithm','cwls');
        [b,s,resid] =  mvregress(mean(M(:,1:100),2),M(:,100),'algorithm','cwls');
        % Maybe polyfit would be the best. Then we could adjust the
        % parameters for each individual example.
        [pc,sc,lat] = pca(M(:,1:200));
        MM = M;
        for ii = 1:21
            MM(:,1:200) = MM(:,1:200)- MM(:,1:200).* repmat(pc(:,ii)',Rows(MM),1);
        end
        % insert resid back into DAT.
end

template = nanmedian(M)';

while (rec_ids_to_apply_template(end) + template_size_recs - 1 > numel(DAT))
    rec_ids_to_apply_template(end) = [];
end

for ii  = 1:length(rec_ids_to_apply_template)
    ix = rec_ids_to_apply_template(ii):(rec_ids_to_apply_template(ii) + template_size_recs-1);
    DAT(ix) = DAT(ix)- template ;
end
if plot_it
    hold on
    plot(DAT,'r')
    legend('orig','subtracted')
end
if write_file
    [p,n,e] = fileparts(dat_file);
    newfile = fullfile(p,[n '_tpltsubt' e]);
    fp = fopen(newfile,'wb');
    fwrite(fp,int16(DAT),'int16');
    fclose(fp);
end
