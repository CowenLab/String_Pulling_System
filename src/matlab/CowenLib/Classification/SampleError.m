function [Error Error_sh]= SampleError(Predicted,Actual,ErrorType);
% Sample Error: Calculates specified error measure for supplied observations
% by Will Dwinnell
% (Calculates Area Under The Curve (AUC) for ROC analysis.)
% Last modified: Apr-17-2008
%
% Error = SampleError(Predicted,Actual,ErrorType)
%
% Error      = Calculated error measure
% Predicted  = Predicted values (column vector)
% Actual     = Target values (column vector)
% ErrorType:
%   'L-1'
%   'L-2'
%   'L-4'
%   'L-16'
%   'L-Infinity'
%   'RMS'
%   'AUC' (requires tiedrank() from Statistics Toolbox)
%   'Bias'
%   'Conditional Entropy'
%   'Cross-Entropy' (assumes 0/1 actuals)
%   'F-Measure'
%   'Informational Loss'
%   'MAPE'
%   'Median Squared Error'
%   'Worst 10%'
%   'Worst 20%'
% Cowen: AUC: Added the shuffle correction and mean switching so that mean


Error_sh = [];

if isempty(Actual)
    Error = nan;
    return
end

switch upper(ErrorType)
    case {'L-1', 'L1', 'LAD', 'LAE', 'MAE', 'ABSOLUTE'}
        Error = mean(abs(Predicted - Actual));

    case {'L-2', 'L2', 'MSE', 'LSE'}
        Error = mean((Predicted - Actual) .^ 2);

    case {'L-4', 'L4'}
        Error = mean((Predicted - Actual) .^ 4);

    case {'L-16', 'L16'}
        Error = mean((Predicted - Actual) .^ 16);

    case {'L-INFINITY', 'LINFINITY', 'MAXIMUM', 'CITYBLOCK', ...
            'MANHATTAN', 'TAXICAB', 'CHEBYSHEV', 'MINIMAX'}
        Error = max(abs(Predicted - Actual));

    case {'RMS', 'RMSE'}
        Error = sqrt(mean((Predicted - Actual) .^ 2));

    case {'AUC', 'AUROC'}
        NANIX = isnan(Actual) | isnan(Predicted);
        if any(NANIX)
            Actual = Actual(~NANIX);
            Predicted = Predicted(~NANIX);
        end
        
        if any(Actual > 1)
            error('Actual category must be either 0 or 1')
        end

        nTarget     = sum(double(Actual == 1));
        nBackground = sum(double(Actual == 0));
        % Rank data
        R = tiedrank(Predicted);  % 'tiedrank' from Statistics Toolbox

        % Calculate AUC
        Error = (sum(R(Actual == 1)) - (nTarget^2 + nTarget)/2) / (nTarget * nBackground);
    case {'AUC_INFO'}
        % Count observations by class
        % COWEN: Note - this apparently assumes that the target mean is
        % GREATER than the background mean. If it is not, then the AUC will
        % be less than .5. To account for this, I invert the categories if
        % the mean in category ==1 is less than category ==0.
        
        % Remove nans from the data (assumed that nan indicates an ignored
        % point.
        NANIX = isnan(Actual) | isnan(Predicted);
        if any(NANIX)
            Actual = Actual(~NANIX);
            Predicted = Predicted(~NANIX);
        end
        
        if any(Actual > 1)
            error('Actual category must be either 0 or 1')
        end

        if mean(Predicted(Actual==1)) < mean(Predicted(Actual==0))
            % If the
            %disp('AUC: Switching means so that group 2 > group 1.')
            Actual = Actual == 0; % invert the categories.
        end

        nTarget     = sum(double(Actual == 1));
        nBackground = sum(double(Actual == 0));
        % Rank data
        R = tiedrank(Predicted);  % 'tiedrank' from Statistics Toolbox

        % Calculate AUC
        Error = (sum(R(Actual == 1)) - (nTarget^2 + nTarget)/2) / (nTarget * nBackground);
        Actual_sh = Actual(randperm(length(Actual)));
        
        if mean(Predicted(Actual_sh==1)) < mean(Predicted(Actual_sh==0))
            % If the
            %disp('AUC: Switching means so that group 2 > group 1.')
            Actual_sh = Actual_sh == 0; % invert the categories.
        end
        
        Error_sh = (sum(R(Actual_sh == 1)) - (nTarget^2 + nTarget)/2) / (nTarget * nBackground);
        
        Error = Error-Error_sh;
        
    case {'BIAS'}
        Error = mean(Predicted - Actual);

    case {'CONDITIONAL ENTROPY', 'RESIDUAL ENTROPY'}
        Error = ConditionalEntropy(Actual,Predicted);

        % Note: errors of 1.0 blow up
    case {'CROSS-ENTROPY', 'CROSSENTROPY', 'INFORMATIONALLOSS', 'INFORMATIONAL LOSS', 'MXE'}
        Error = mean(-log2([Predicted(Actual == 1); 1 - Predicted(Actual == 0)]));

    case {'F-MEASURE', 'F MEASURE'}
        TwoTP = 2 * sum(double( (Predicted == 1) & (Actual == 1) ));
        FP = sum(double( (Predicted == 1) & (Actual == 0) ));
        FN = sum(double( (Predicted == 0) & (Actual == 1) ));
        Error = TwoTP / (TwoTP + FP + FN);
        clear TwoTP FP FN;

        % Watch out for actuals equal to zero!
    case {'MAPE', 'RAE', 'RELATIVE'}
        Error = mean(abs((Predicted - Actual) ./ Actual));

    case {'MEDIAN SQUARED ERROR', 'MEDIAN SQUARE ERROR'}
        Error = median((Predicted - Actual) .^ 2);

    case {'WORST 10%'}
        [PredictedSorted I] = sort(Predicted);
        Error = sum(Actual(I(round(0.9 * length(Predicted)):end))) / sum(Actual);

    case {'WORST 20%'}
        [PredictedSorted I] = sort(Predicted);
        Error = sum(Actual(I(round(0.8 * length(Predicted)):end))) / sum(Actual);
end


% EOF




