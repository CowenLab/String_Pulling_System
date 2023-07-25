 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Generation of Poisson spike train with refractoriness
 % From http://www.cs.dal.ca/~tt/fcns/fcns_programs/spikes/
 % Thomas P. Trappenberg
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 clear; clf; hold on;  % parameters of the model;
 fr_mean=15/1000;      % mean firing rate per ms

 % generating presynaptic poisson spike trains
 lambda=1/fr_mean;              % time interval/firing rate in interval
 ns=1000;                       % number of spikes to be generated
 isi1=-lambda.*log(rand(ns,1)); % generation of exponential distr. ISIs
 % Delete spikes that are within refractory period
 is=0; 
 for i=1:ns;
    if rand>exp(-isi1(i)^2/32);
       is=is+1;
       isi(is)=isi1(i);
    end
 end

 hist(isi,1000);          % Plot histogram of 1000 bins
 cv=std(isi)/mean(isi)  % coefficient of variation
 title(['nspikes ' num2str(length(isi) + 1)])
 