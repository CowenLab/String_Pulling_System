%		function [R AllCors] = corr_rel(spiketimes, sigma,mode,ini,fin,allpairs)
%								new: spiketimes = a CELL ARRAY OF SPIKE TIMES - ONE ELEMENT PER TRIAL/CELL 
% 
% old:spiketimes=N x 1 x P	(N=number of trials=number of cells, P=spike times in secs, zero padded)
%               ini, fin: window of analysis in secs
%               allpairs=1 => all pairs
%								allpairs=0 => Consecutive pairs (good approximation of allpairs).
%								mode: Just for graphic purposes
% calculates the correlation type reliability measure - Analytical version (Peter Thomas)
% R=reliability, AllCors=matrix of correlations/similarities
%
% cowen (2005) changes stimes to be a cell array of spike times instead of
% the zero padded array. Seemed to make more sense.

function [R, AllCors] = corr_relf(stimes,sigma, mode,ini,fin,allpairs)

global waves nwaves pulse npulses ncurrent ppulses pcurrent range base labels maxT waves2 nwaves2

ntrials=length(stimes);
srate=10000;
sig=sigma*srate;

if nargin < 3
    mode = 0;
end

if nargin < 4
    ini = 0;
end

if nargin < 5
    fin = inf;
end

if nargin < 6
    allpairs = 1;
end


R=0;
AllCors=eye(ntrials,ntrials);

if allpairs==1
	% ---all pairs
    for i=1:ntrials-1
    	    tmp=stimes{i};ts=tmp(:);idx=find(ts>ini & ts<fin);s1=floor(ts(idx)*srate);
	    	for j=i+1:ntrials
		    	tmp=stimes{j};ts=tmp(:);idx=find(ts>ini & ts<fin);s2=floor(ts(idx)*srate);
		    	if ~isempty(s1) & ~isempty(s2)
		    		AllCors(i,j) = prodct(s1,s2,sig)/sqrt(prodct(s1,s1,sig)*prodct(s2,s2,sig));
            	else
                    AllCors(i,j)=0;
            	end
		    	R=R+AllCors(i,j);
        	end
            fprintf('.')

    end
	R=R*2/(ntrials*(ntrials-1));
	type='All pairs';
else
    %---consecutive pairs only
    for i=1:ntrials-1
	    j=i+1;
	    tmp=stimes{i};ts=tmp(:);idx=find(ts>ini & ts<fin);s1=floor(ts(idx)*srate);
	    tmp=stimes{j};ts=tmp(:);idx=find(ts>ini & ts<fin);s2=floor(ts(idx)*srate);
	    if ~isempty(s1) & ~isempty(s2)
	    	AllCors(i,j) = prodct(s1,s2,sig)/sqrt(prodct(s1,s1,sig)*prodct(s2,s2,sig));
	    else
	        AllCors(i,j)=0;
	    end
	    R=R+AllCors(i,j);	
        fprintf('.')
    end
    R=R/(ntrials-1);
    type='Consecutive pairs';
end

if (mode >0)
	clf
	hold on
	greycols(255);
    imagesc(AllCors)	
    axis('image')
	title(sprintf('%s - Reliability:%.2f',type,R));
	drawnow
end


% Analytical version - sigma in sample points

function s=prodct(s1,s2, sigma)

sigma2 = sigma^2; % shorthand
sigmapi = 2*sigma*sqrt(pi); % shorthand
gg=0;
for a = 1:length(s1)
	gg = gg + sum(exp(-((s2 - s1(a)).^2)/(4*sigma2)));
end
s=gg/sigmapi;
			
			