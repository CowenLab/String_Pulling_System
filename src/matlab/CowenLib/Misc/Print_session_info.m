function Print_session_info(S)
names = fieldnames(S)
names'
for ii = 1:length(S)
  if ~isempty(S(ii).data_dir)
    C = struct2cell(S(ii));
    for fieldid = 1:length(C)
      
      if isstr(C{fieldid})
	fprintf('%s   ',C{fieldid});
      else
	fprintf('%i   ',C{fieldid});
      end
    end
    fprintf('\n');
%     fprintf('%s   %i   %i   %i   %i   %i   %s\n',S(ii).data_dir(end-6:end),...
%       S(ii).isold,S(ii).isnovel,S(ii).isdoor_reward,S(ii).iscut,S(ii).nepochs,S(ii).note);     
  end
end
