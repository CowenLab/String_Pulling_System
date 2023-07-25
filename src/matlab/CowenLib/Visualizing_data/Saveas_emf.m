function Saveas_emf(fname)
% Save the current figure to the desktop as an emf file.
if nargin == 0
    fname = 'temp';
end

p = strrep(userpath,'Documents\MATLAB;','Desktop');
saveas(gcf,fullfile(p,[fname '.emf']))