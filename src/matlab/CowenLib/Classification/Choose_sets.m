function O = Choose_sets(S,type,n)
% Allows you to specify which sets to use for analysis
% S has to be a structure from the Session_info function.
%
%
% cowen Fri Jun  4 09:18:05 1999
O = [];

if nargin == 2
  n = 0
end

for ii = 1:length(S)
  if ~isempty(S(ii).data_dir)
    
    switch type
      case 'cut'
	if S(ii).iscut
	  O = [O,ii];
	end
      case 'novel'
	if S(ii).isnovel
	  O = [O,ii];
	end
      case 'nonnovel'
	if ~S(ii).isnovel
	  O = [O,ii];
	end
      case 'door_reward'
	if S(ii).isdoor_reward == 1
	  O = [O,ii];
	end
      case 'curt_reward'
	if S(ii).isdoor_reward == 0
	  O = [O,ii];
	end
      case 'old'
	if S(ii).isold
	  O = [O,ii];
	end
      case 'young'
	if ~S(ii).isold
	  O = [O,ii];
	end
      case 'nepochs'
	if S(ii).nepochs == n
	  O = [O,ii];
	end
	
      otherwise
	error('illegal option')
    end
  end
end