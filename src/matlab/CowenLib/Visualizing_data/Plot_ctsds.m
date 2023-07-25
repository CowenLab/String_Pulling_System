function Plot_ctsds(crtsd_array, startpt,windowsize)

colors = {'b' 'g' 'c' 'b:' 'r' 'p' 'v' '.' 'ro'};
symbols = {'ro','g>','<m','xr','>r','<p','+v','bx','ro'};

for cr = 1:length(crtsd_array)
  if strcmp(class(crtsd_array{cr}),'ts') 
    z = zeros(size(Data(Restrict(crtsd_array{cr},startpt,startpt+windowsize))));
    z(:) = 100 + 10 * cr;
    plot(Data(Restrict(crtsd_array{cr},startpt,startpt+windowsize)),z,symbols{cr})
    
  else
    plot(Range(Restrict(crtsd_array{cr}, ...
	startpt,startpt+windowsize),'ts'),Data(Restrict(crtsd_array{cr}, ...
	startpt,startpt+windowsize)),colors{cr})
  end
  hold on
end
title(['Window from ' Time_string(startpt) ' to ' Time_string(startpt+windowsize) ])
xlabel('timestamps. Space to go forward, button for reverse ')
axis( [StartTime(Restrict(crtsd_array{1}, startpt,startpt+windowsize)) EndTime(Restrict(crtsd_array{1}, startpt,startpt+windowsize))   -300 300]) 
drawnow
