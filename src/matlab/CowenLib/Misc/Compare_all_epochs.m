% Compare all epochs
d = dir('*.tt');
for ii = 1:length(d)-1
  name1 = strtok(d(ii).name,'.');
  name2 = strtok(d(ii+1).name,'.');
  Compare_epochs(name1,name2);
  
end
