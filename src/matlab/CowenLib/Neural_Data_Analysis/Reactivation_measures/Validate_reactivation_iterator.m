%all_options = {{[5 5]} {[10 10]} {[20 20]} {[50 50]}  {[100 100]} {[200 200]} {[500 500]}  {[50 20]} {[100 50]}};

all_options = {{[1200 1200]} {[2500 2500]} {[3800 3800]} {[4100 4100]} {[5400 5400]} {[6800 6800]} {[7100 7100]} {[8400 8400]} };
%all_option_titles = {'dt 5' 'dt 10' 'dt 20' 'dt 50' 'dt 100' 'dt 50, 20 overlap'  'dt 100, 50 overlap'};
j = jet;
cid = floor(linspace(1,rows(j),length(all_options)));
%colors = {'b' 'r' 'g' 'k' 'm' 'c' 'y' 'b' 'r' 'g' 'k' 'm' 'c' 'y'  }
% The main routine.
V = [];
for iOption = 1:length(all_options)
    V{iOption} = Validate_reactivation(@Reactivation_EV,all_options{iOption});
end

% Plot

for iOption = 1:length(V)
    opt_str{iOption} = mat2str(all_options{iOption}{1});
    h = errorbar(V{iOption}(:,1),V{iOption}(:,2),V{iOption}(:,3));
    hold on
    set(h,'Color',j(cid(iOption),:))
    set(h,'LineWidth',3)
end
legend(opt_str,'location','Best')
xlabel('Signal to noise during sleep')
ylabel('Strength of reactivation')
