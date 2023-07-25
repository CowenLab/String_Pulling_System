function j = Jerk(position_data)
% Jerk is the time derivative of acceleration.
% 
% https://en.wikipedia.org/wiki/Jerk_%28physics%29
% https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3470860/
%
% Strange measurement and sometimes difficult to interpret so be careful.
% Use speed when in doubt.
acc = diff(diff(position_data));
j = abs(diff(acc));
