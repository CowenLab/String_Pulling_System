function [Cg, B, W] = CalinskiHarabaszCg(mu, x, z)

% Cg = CalinskiHarabaszCg(mu, x, z)
%
% INPUTS
%     mu = nG x nD, centers of clusters
%     x = nS x nD, data 
%     z = nS x 1, assignments of data points to clusters
%
% OUTPUTS
%     Cg = C(g)
%     B = between groups dispersion
%     W = within groups dispersion
%
% ALGO
%     C(g) = (trace B / (nG - 1)) / (trace W / (nS - nG) )

% ADR 1999
% version L4.0
% status: PROMOTED

[nG, nD] = size(mu);
[nS, nD] = size(x);

% calculate W
W = zeros(nD, nD);
for iG = 1:nG
   z0 = (z == iG);
   for iS = 1:nS
      W = W + (z0(iS) .* (x(iS, :) - mu(iG, :)))' * (x(iS, :) - mu(iG, :));
   end
end

mx = mean(x);
% calculate B
B = zeros(nD, nD);
for iG = 1:nG
   B = B + sum(z == iG) * (mu(iG, :) - mx)' * (mu(iG, :) - mx);
end

Cg = (trace(B) / (nG - 1)) / (trace (W ) / (nS - nG));


   