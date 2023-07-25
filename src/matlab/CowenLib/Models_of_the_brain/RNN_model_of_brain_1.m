
%% Problem 3 - prestep

% We create the data file that is used in Problem 3

clear; close all; clc;

% Network & simulated-data parameters
g = 1.5;
N = 500;
dtData = 0.0641;
dt = 0.001; %RNN simulation dt
epochs = 165; % Training epochs
noiseLevel = 0.5; % Intensity of the noise
tau = 0.01; % membrane time constant
sigN = noiseLevel * sqrt(tau / dt); % To do

tData = 0:dtData:epochs*dtData; % time array of target activity
t = 0: dt: tData(end); %time array for RNN

%% 
% Generating the target activity (bump)
xBump = zeros(N, length(tData));
sig = 0.0343 * N;  % scaled correctly in neuron space!!!
for i =1:N
  xBump(i, :) = exp(-((i - N * tData / tData(end)) .^ 2.0) ./ (2 * sig ^ 2));
end
hBump = log((xBump + 0.01)./(1 - xBump + 0.01));  % current from rate

%Plot target bump activity
figure;
imagesc(xBump);
axis on
xticks([1, 50, 100, 150])
yticks([1, 250, 500])

title('Target Activity over Time')
ylabel('Neurons')
xlabel('Time t')

%%
% Learning parameters
nRunTot = 125;
nFree = 5;
nLearn = 50;
P0 = 1.;

permuted_neurons = randperm(N);
cL = permuted_neurons(1:nLearn);
ncL = permuted_neurons(nLearn+1:end);

% initial connectivity
J = g * randn(N, N) ./ sqrt(N);
J0 = J;

% input
tauWN = 1;
ampWN = sqrt(tauWN/dt);
ampIn = 1;

iWN = ampWN * randn(N, length(t));
input = ones(N, length(t));
for tt = 2: length(t)
    input(:, tt) = iWN(:, tt) + (input(:, tt - 1) - iWN(:, tt)) * exp(- (dt / tauWN));
end
input = ampIn * input;

%% Learning loop (implementation of the RLS algorithm)
% Takes about ~5 minutes to train

R = zeros(N, length(t));   % storing firing rates
JR = zeros(N, 1);
PJ = P0 .* eye(nLearn);  % initial covariance

for nRun=1:nRunTot
        disp(strcat(num2str(100*nRun/nRunTot), ' % trained'))
        H = xBump(:, 1);
        tLearn = 0;
        iLearn = 2;
        %             frac = floor(nL(pp)*N);
        R(:, 1) = 1./(1+exp(-H));
        for tt=2:length(t)
            tLearn = tLearn + dt;
            R(:, tt) = 1./(1+exp(-H));
            JR = J*R(:, tt) + input(:, tt)+ sigN*randn(N, 1);

            H = H + dt*(-H + JR)/tau;
            if (tLearn>=dtData)&& (nRun<nRunTot-nFree)
                tLearn = 0;
                err(1:N, :) = JR(1:N, :) - hBump(1:N, iLearn);

                iLearn = iLearn + 1;

                k = PJ*R(cL, tt);
                rPr = R(cL, tt)'*k;
                c = 1.0/(1.0 + rPr);
                PJ = PJ - c*(k*k');
                p1 = J(1:N, cL);
                p2 = c*err(1:N, :)*k';
                J(1:N, cL) = p1 - p2;
            end
        end
        figure();
        imagesc(R/max(max(R)));
        axis square; colorbar;
        pause(0.001);
end
%%
% Run untrained RNN
R_nt = zeros(N, length(t));   % storing firing rates of (n)ot (t)rained network
R_nt(:, 1) = xBump(:,1);
for tt=2:length(t)
            tLearn = tLearn + dt;
            R_nt(:, tt) = 1./(1+exp(-H));
            JR = J0*R_nt(:, tt) + input(:, tt)+ sigN*randn(N, 1);
            H = H + dt*(-H + JR)/tau;
end
figure(3)
imagesc(R_nt/max(max(R_nt)));
axis square; colorbar;
%%
save('target_data.mat', 'xBump', 'tData' )
save('trainedRNN_data.mat', 'R', 't')
save('untrainedRNN_data.mat', 'R_nt', 't')
save('trainedRNN_interactmatrix.mat', 'J', 'J0')

Problem3_preparation.m
Displaying Problem3_preparation.m.