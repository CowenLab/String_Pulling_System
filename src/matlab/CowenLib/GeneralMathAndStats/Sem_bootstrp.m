function s = Sem_bootstrp(M)
[M] = bootstrp(200,@Sem,M);
s = mean(M);
%s = s/sqrt(Rows(M));
%bootstat = bootstrp(nboot,bootfun,d1,d2,...) 