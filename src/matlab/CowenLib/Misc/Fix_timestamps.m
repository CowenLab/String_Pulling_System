function T = Fix_timestamps(T)
% Catch gross errors in the timestamp lists.
% If there are no errors, no changes will be made 


[ii1, jj] = find(T > 100000000);
T(ii1,:) = [];
[ii2, jj] = find(T < 10000);
T(ii2,:) = [];
[r,c] = size(T);

for ii = 2:r
  % Look for overlapping intervals
  if (T(ii-1,2) >= T(ii,1)) 
    T(ii-1,:) = T(ii,1) ;
    disp(['End of interval overlaps with the following interval. ' ...
	  num2str(ii-1) '. Interval reduced.']);
  end    
  % Look for double timestamps
  if (T(ii-1,1) == T(ii,1)) | (T(ii-1,2) == T(ii,2))
    T(ii-1,:) = [];
    disp(['Double Timestamps idx ' num2str(ii-1) '. One has been deleted.']);
    r = r - 1;
  elseif (T(ii,1) >= T(ii,2)) 
    T(ii,:) = [];
    disp(['Timestamps are not in sequence idx ' num2str(ii-1) ...
	  'Offending ts has been deleted.']);
    r = r - 1;
  end    


end


numfixed = length([ii1;ii2]);

if (numfixed  > 0)
  ii1
  ii2
  disp('Your timestamp file is corrupt(vals out of range).');
  disp('See above index values for the offending lines..'); 
  disp(['DELETED the erroroneous lines (' num2str(numfixed) ' lines).']);

end  
