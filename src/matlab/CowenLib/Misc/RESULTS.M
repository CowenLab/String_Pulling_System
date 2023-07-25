% Summary data
% silicon, steel, nichrome
s_n = [
   1.246    0  1.2929 
   5.0808   0  3.0844 
   1.4655   0  3.1146
   1.6044   0  3.8393
   8.3279   0 11.7086
   1.336    0  2.8488
   5.0280   0 6.3372
   9.9011   0 7.2188
   1.629    0 43.4984 
]

s_n_deep =[ 

65.9   0 9.4754
18.099 0 7.2429
17.49  0 41.1319
53     0 14.04
2      0 9.9253
14     0 14.04
1.799  0 14.6613
]


k_s = [
 .2154  0.2006 0.2984
 .2112  0.1967 0.2474
 .2272  0.1792 0.1955
 .2094  0.2011 0.1975
 .2235  0.1932  0.1862
 .2032  0.2256 0.3434
 .1984  0.1828 0.1868
 .1848  0.1923 0.3434
]

k_s_p = [
 .931  0.97513 0.49040 
.929 0.97959 0.76601
.974 0.99281 0.96213
.975 0.97454 0.95867
.986 0.98300 0.95636 
.980 0.93237 0.21296
.9766 0.99084  0.96550
.877 0.98382 0.21296

]

error_fit = [
  11.6513 5.2 5.7811 
  11.4956  5.28 4.4353
  11.3362  7.25 4.9419
  11.1859 5.79 5.3071
  11.3181  5.56 5.5860
  13.6459 5.41 5.0311
  13.1577  5.29 5.0177
  13.6459 5.23 5.8498 
  12.6831 5.34 2.8591
]
error_fit = error_fit(:,[2 3 1]);

figure
hold on 
bar(mean(s_n))
errorbar(mean(s_n), sem(s_n),'o')
xlabel('silicon steel nichrome')
ylabel('S/N')
title('S/N ratio')
figure
hold on 
bar(mean(s_n_deep))
errorbar(mean(s_n_deep), sem(s_n_deep),'o')
xlabel('silicon steel nichrome deep')
ylabel('S/N')
title('S/N ratio')

figure
hold on 
bar(mean(k_s))
errorbar(mean(k_s), sem(k_s),'o')
xlabel('silicon steel nichrome')
ylabel('K-S value')
title('K_S value')

figure
hold on 
bar(mean(k_s_p))
errorbar(mean(k_s_p), sem(k_s_p),'o')
xlabel('silicon steel nichrome')
ylabel('K-S P value')
title('K_S P value')

figure
hold on 
bar(mean(error_fit))
errorbar(mean(error_fit), sem(error_fit),'o')
xlabel('silicon steel nichrome')
ylabel('error_fit value')
title('error_fit value')