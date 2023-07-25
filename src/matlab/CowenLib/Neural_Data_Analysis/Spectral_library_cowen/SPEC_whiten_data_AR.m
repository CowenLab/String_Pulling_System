function [O, INFO] = SPEC_whiten_data_AR(data,n_params)
% autoregressive model
% make n_params (order of the AR model) roughly the number of time stpes in data that you want to
% regress over.
%
%
% 
TESTME = false;
if TESTME
    p = fileparts(which(mfilename)); % p = 'C:\Users\Stephen Cowen\Dropbox\Foldershare\Src\matlab\Working\Neural_Data_Analysis\TestData'
    load(fullfile(p,'..','TestData','LFPdata.mat'));
    data = D.data;
     n_params = 17; % Insel chose 2 (seems too small). 17 seems OK. (the AIC approach is wacko big so not sure why this is better).
%     n_params = 2;
%     n_params = 221;
    
end
%%

%% % find the AIC for hte best fit. BUT i find this gets way too big.
% Tried n_params 17 and seems to work OK but this typically gives you BIG
% values.
if isempty(n_params)
    % How do we estimate the order of the filter? We could do it using AIC or
    % FPE: see Kamel et al. Whitening of Background Brain Activity via Parametric Modeling
    % Load some sample data. Could have used some optimization routine
    % instead of brute force.
%     x = fminbnd(aryule_cowen,1,550)

    prm = 1:2:550;
    AIC = []; FPE = [];reflect_coeffs = [];
    N = length(data);
    % N = 10;
    for ii = 1:length(prm)
        [arcoeffs, erro(ii),reflect_coeffs{ii}] = aryule(data,prm(ii));
        AIC(ii) = N*log(erro(ii)) + 2*prm(ii);
        %         FPE(ii) = erro(ii)*((N + (prm(ii) + 1))/(N - (prm(ii)+1)));
    end
    [mini,ix] = min(AIC);
    n_params = prm(ix);
    %
    % [mini,ix] = min(FPE);
    % prm(ix)
       
    figure
    plot(prm,AIC)
    title('Finding the best order for the aryule filter AIC')
    ylabel('AIC')
    xlabel('order')
end

%%

[INFO.arcoeffs, INFO.err] = aryule(data,n_params);

% Why ignore the first parameter (the baseline) - seems to help but why?
f = filtfilt(-INFO.arcoeffs(2:end), 1,data); % Checked wtih nate and this is what he used - but at 2048 s rate.
%  f = filtfilt(-INFO.arcoeffs, 1,data); % Checked wtih nate and this is what he used - but at 2048 s rate.
O = data-f;

%% Test
if nargout == 0
    figure
    plot(data);hold on; plot(f)
    figure
    [p,f] = pwelch(data,[],[],1:.2:60,D.sfreq);
    plot(f,p)
    hold on
    [p,f] = pwelch(f,[],[],1:.2:60,D.sfreq);
    plot(f,p)
    [p,f] = pwelch(O,[],[],1:.2:60,D.sfreq);
    plot(f,p)
    legend('orig','filtered','O-filt')
    title(['npara ' num2str(n_params)])
 
    
end


