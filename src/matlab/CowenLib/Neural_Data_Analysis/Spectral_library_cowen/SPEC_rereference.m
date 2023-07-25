function [OUT, stats] = SPEC_rereference(TGT,REF,method)
%  use regression to re-references. Assumes ch = col, sample = row
%
% Use a subset of the signal to create the model.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3
    method = 'regression';
end

stats = [];
plot_it = false;

if Rows(REF) < Cols(REF)
    error('Make sure input data is in column format')
end

if Rows(TGT) ~= Rows(REF)
    error('File sizes or record lengths are not the same')  
end

if length(TGT) > 50000
    sk = round(length(TGT)/30000);
    % If you cant make a model wiht 30000 points then you are dumb.
else
    sk = 2;
end

pr = prctile(TGT(1:sk:end),[1 99]);
Gix = find(TGT > pr(1) & TGT < pr(2) & TGT ~=0);
ix = Gix(1:sk:end);
REF = REF-mean(REF(ix,:)); % Eliminate DC offset.
TGT = TGT-mean(TGT(ix));

mod = fitlm(REF(ix,:), TGT(ix),'RobustOpts','on');
if any(isnan(mod.Coefficients.pValue));
    % turn off robust options.
    mod = fitlm(REF(ix,:), TGT(ix),'RobustOpts','off');
end
newy = predict(mod,REF);
OUT = TGT-newy;

if plot_it
    plot(TGT)
    hold on
    plot(REF)
    plot(OUT)
    if Cols(REF) ==1
        plot(TGT-REF)
    else
        plot(TGT-REF(:,1))
        plot(TGT-REF(:,2))
    end
    legend('orig','ref','reref','sub')
    xlabel('sample')
end

if nargout > 1
    ix = Gix(4:100:end);
    stats.rms_tgt = rms(TGT(ix));
    stats.rms_ref = rms(REF(ix,:));
    stats.rms_rereffed = rms(OUT(ix));
    stats.rms_from_sub = rms(TGT(ix)-REF(ix,:));
    if stats.rms_from_sub < stats.rms_rereffed
        stats
        switch method
            case 'adaptive'
                disp('Simple subtraction reduces rms more than the regression. Using subtraction.')
                if Cols(REF) ==1
                    OUT = TGT - REF;
                else
                    OUT = TGT - mean(REF,2);
                end
            otherwise
                disp('Subtraction is better than regress.')
        end
    end
end
